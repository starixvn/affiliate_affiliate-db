/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_MemberInfo_Import]
	@XmlData	XML
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	VARCHAR(2000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Job (web call) - Import member info

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250221@Sally: Enhance AFFMediaLink  [RedmineID: #212201]
		- 20250320@Sophia: Import ClickId [RedmineID: #219949]
		- 20250808@Sally: Get TagList info [RedmineID: #234932]

*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	DECLARE @SiteName VARCHAR(30), @BrandName VARCHAR(30), @TimeZone INT
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName'), @BrandName = dbo.Aff_f_GetSetting('BrandName'), @TimeZone = dbo.Aff_f_GetSetting('TimeZone')

	CREATE TABLE #MemberInfo
	(
		CustId		INT
		,UserName	VARCHAR(30)
		,CurrencyId	INT
		,ActStatus	TINYINT
		,AffId		INT
		,AffCode	VARCHAR(20)
		,RegTime	DATETIME
		,Status		TINYINT
		,IsTest		BIT
		,IsValid	BIT DEFAULT(0)
		,ClickId 	BIGINT
		,TagList 	NVARCHAR(MAX)
	)

	BEGIN TRY
		INSERT INTO #MemberInfo
		(
			CustId
			,UserName
			,CurrencyId
			,ActStatus
			,AffId
			,AffCode
			,RegTime
			,Status
			,IsTest
			,ClickId
			,TagList
		)
		SELECT
			CustId		= t.c.value('@custid', 'INT')
			,UserName	= t.c.value('@username', 'VARCHAR(30)')
			,CurrencyId	= t.c.value('@currencyid', 'INT')
			,ActStatus	= t.c.value('@actstatus', 'TINYINT')
			,AffId		= t.c.value('@affid', 'INT')
			,AffCode	= t.c.value('@affcode', 'VARCHAR(20)')
			,RegTime	= DATEADD(HOUR, @TimeZone, NULLIF(t.c.value('@regtime', 'DATETIME'), ''))
			,Status		= t.c.value('@status', 'TINYINT')
			,IsTest		= t.c.value('@istest', 'BIT')
			,ClickId = CASE WHEN t.c.value('@clickid', 'BIGINT') = 0 THEN NULL ELSE t.c.value('@clickid', 'BIGINT') END
			,CASE 
				WHEN ISNULL(t.c.value('@taglist', 'NVARCHAR(MAX)'), '') IN ('', '[]') THEN NULL
				ELSE REPLACE(REPLACE(REPLACE(t.c.value('@taglist', 'NVARCHAR(MAX)'), '[', ''), ']', ''), ' ', '')
			END
		FROM @XmlData.nodes('root/row') AS t(c)
		OPTION (OPTIMIZE FOR (@XmlData = NULL))
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 100, @ErrMsg = 'Failed Parse XML data: ' + ERROR_MESSAGE()
		RETURN
	END CATCH

	CREATE CLUSTERED INDEX CIX_CustId ON #MemberInfo (CustId)

	BEGIN
		UPDATE m
		SET m.AffId = ai.AffId, m.IsValid = 1
		FROM #MemberInfo m
			INNER JOIN dbo.AffiliateCode ac WITH (NOLOCK) ON ac.AffCode = m.AffCode
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = ac.AffId
		WHERE m.RegTime >= ai.ApprovedDate

		IF EXISTS (SELECT 1 FROM #MemberInfo WHERE AffId IS NOT NULL AND IsValid = 0)
			UPDATE m
			SET m.IsValid = 1
			FROM #MemberInfo m
				INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = m.AffId
			WHERE m.RegTime >= ai.ApprovedDate
				AND m.IsValid = 0

		DELETE #MemberInfo WHERE IsValid = 0

		UPDATE #MemberInfo SET CurrencyId = 20 WHERE IsTest = 1
	END

	-- Insert/update data
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM dbo.MemberInfo mi WITH (NOLOCK)
			WHERE EXISTS (SELECT 1 FROM #MemberInfo m WHERE mi.CustId = m.CustId)
		)
		BEGIN
			UPDATE mi WITH (ROWLOCK)
			SET mi.CustId			= m.CustId
				,mi.UserName		= m.UserName
				,mi.Currency		= m.CurrencyId
				,mi.ActStatus		= m.ActStatus
				,mi.Status			= m.Status
				,mi.RegisteredDate	= m.RegTime
				,mi.AffId			= m.AffId
				,mi.ClickId 		= m.ClickId
				,mi.TagList 		= m.TagList
			FROM dbo.MemberInfo mi
				INNER JOIN #MemberInfo m ON mi.CustId = m.CustId
		END

		INSERT INTO dbo.MemberInfo
		(
			CustId
			,UserName
			,Currency
			,ActStatus
			,Status
			,RegisteredDate
			,AffId
			,IsRemoved
			,ClickId
			,TagList
		)
		SELECT
			CustId
			,UserName
			,CurrencyId
			,ActStatus
			,Status
			,RegTime
			,AffId
			,0 AS IsRemoved
			,ClickId
			,TagList
		FROM #MemberInfo m
		WHERE NOT EXISTS (SELECT 1 FROM dbo.MemberInfo mi WITH (NOLOCK) WHERE m.CustId = mi.CustId)
	END

	DROP TABLE #MemberInfo
END
GO