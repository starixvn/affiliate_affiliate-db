/*<info serverAlias="DBAFF12B-Affiliate_12B" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_MemberInfo_Upd]
	@IsReal BIT = 0 
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Job - Update member info

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20240317@Sophia: Enhance job update MemberDaily, add param @IsReal [RedmineID: #219892]
        - 20250808@Sally: Get TagList info [RedmineID: #234932]
		- 20250923@Sally: Enhance SP [RedmineID: #238812]

	Param explain:
		@IsReal = 1: Real time Job (every 1 min)
		@IsReal = 0: Normal job (every 30 min)

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SiteId INT, @SiteName VARCHAR(30), @LastUpdatedTime DATETIME, @TimeZone INT
	SELECT  @SiteName = dbo.Aff_f_GetSetting('SiteName'), @LastUpdatedTime = dbo.Aff_f_GetSetting('MemberInfoLastUpdatedTime'), @TimeZone = dbo.Aff_f_GetSetting('TimeZone')
	SELECT  @SiteId = SiteId FROM bodb_12B.dbo.ServerInfo WITH (NOLOCK) WHERE LicenseeName = @SiteName

	SELECT @LastUpdatedTime = ISNULL(CONVERT(DATE, DATEADD(DAY, -1, @LastUpdatedTime)), '2021-01-01') -- Recall data backward a day

	-- Real time: will use the SName = 'RealMemberInfoLastUpdatedTime', re-call data backward 1 hour
	IF @IsReal = 1
	BEGIN 
		SELECT @LastUpdatedTime = dbo.Aff_f_GetSetting('RealMemberInfoLastUpdatedTime')
		SELECT @LastUpdatedTime = DATEADD(HOUR, -1, @LastUpdatedTime)
	END

	CREATE TABLE #Customer
	(
		RowNumber			INT IDENTITY(1,1)
		,CustId				INT
		,IBCUsername		VARCHAR(50)
		,ActStatus			TINYINT
		,Status				TINYINT
		,FirstDepositDate	DATETIME
		,FirstDepositAmount	MONEY
		,TagList			NVARCHAR(MAX)
		,UpdatedTime		DATETIME
	)

	INSERT INTO #Customer (CustId, IBCUsername, ActStatus, Status, FirstDepositDate, FirstDepositAmount, UpdatedTime, TagList)
	SELECT CustId, TpSystemUserName, ActStatus, Status, FirstDepositDate, FirstDepositAmount, UpdatedTime, TagList
	FROM bodb_12B.dbo.Customer WITH (NOLOCK)
	WHERE SiteId = @SiteId
		AND UpdatedTime >= @LastUpdatedTime

	IF EXISTS (SELECT 1 FROM #Customer)
	BEGIN
		-- Update in batches of 2000 rows
		DECLARE @StartRow	INT 
			,@StopRow		INT 
			,@MaxRow		INT	= 0
			,@Threshold		INT  -- the number of each batch

		SET @Threshold = 2000
		SELECT @MaxRow = MAX(RowNumber) FROM #Customer

		IF (@Threshold >= @MaxRow)
			SET @Threshold = @MaxRow

		-- SET for first batch
		SELECT @StartRow = 1, @StopRow = @Threshold

		WHILE (@MaxRow IS NOT NULL)
		BEGIN
			UPDATE m WITH (ROWLOCK, UPDLOCK)
			SET	m.IBCUserName = c.IBCUsername
				,m.ActStatus = c.ActStatus
				,m.Status = c.Status
				,m.FirstDepositDate = DATEADD(HOUR, @TimeZone, c.FirstDepositDate)
				,m.FirstDepositAmount = c.FirstDepositAmount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END
				,m.TagList = c.TagList
			FROM dbo.MemberInfo m
				INNER JOIN #Customer c ON m.CustId = c.CustId
				LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON t.TpExchangeId = m.Currency
				INNER JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, m.Currency) = e.ExchangeId
			WHERE c.RowNumber BETWEEN @StartRow AND @StopRow

			IF @StopRow = @MaxRow BREAK

			-- Set for next batch
			SET @StartRow = @StopRow + 1
			SET @StopRow = @StopRow + @Threshold

			IF @StopRow >= @MaxRow
				SET @StopRow = @MaxRow

		END

		SELECT @LastUpdatedTime = MAX(UpdatedTime) FROM #Customer

		IF @IsReal = 1 
		BEGIN 
			UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET SValue = CONVERT(VARCHAR(20), @LastUpdatedTime, 120)
			WHERE SName = 'RealMemberInfoLastUpdatedTime'		
		END 
		ELSE
		BEGIN 
			UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
			SET SValue = CONVERT(VARCHAR(20), @LastUpdatedTime, 120)
			WHERE SName = 'MemberInfoLastUpdatedTime'
		END 
		
	END

	DROP TABLE #Customer
END
GO