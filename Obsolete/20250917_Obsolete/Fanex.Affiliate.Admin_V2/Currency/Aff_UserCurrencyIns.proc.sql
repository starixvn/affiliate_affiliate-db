ALTER PROCEDURE [dbo].[Aff_UserCurrencyIns] 
	@UserID INT
	,@CurrencyXML VARCHAR(max)
	,@ModifyBy INT
	,@Langkey VARCHAR(10) = 'en-US'
	,@IP VARCHAR(40)
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created:20130729@Jim
Task :  Restrict permission of Aff Users by currency
DB: DBLIC.Affiliate_Alpha


Revisions:
    20140317@Bobby: Update Aff_WriteLog_UserLog_RunSP

Param's Explanation:
	@CurrencyXML format:
	'<currencies>
	 <currency currencyid=''5'' status=''1'' > 
	</currency>
	 <currency currencyid=''4'' status=''1''>
	</currency>
	</currencies>'
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @GroupID INT
	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	DECLARE @LogSPData VARCHAR(5000)
	DECLARE @LogSPData2 VARCHAR(5000)

	SET @startRun = GETDATE()

	DECLARE @iDoc INT
		,@i INT
		,@max INT

	CREATE TABLE #Currency (
		ID INT IDENTITY(1, 1)
		,currencyid INT
		,STATUS INT
		)

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		,@CurrencyXML

	SELECT @GroupID = GroupID
	FROM dbo.AdminUser WITH (NOLOCK)
	WHERE CustID = @UserID

	INSERT INTO #Currency (
		CurrencyID
		,STATUS
		)
	SELECT CurrencyID
		,STATUS
	FROM OPENXML(@iDoc, '/currencies/currency', 0) WITH (currencyid VARCHAR(20), STATUS VARCHAR(10))

	SELECT @i = 1
		,@max = MAX(ID)
	FROM #currency

	SET @LogSPData2 = ''

	WHILE (@i <= @max)
	BEGIN
		SELECT @LogSPData2 = @LogSPData2 + ',' + CONVERT(VARCHAR(10), CurrencyID)
		FROM #Currency
		WHERE ID = @i
			AND STATUS = 1

		SET @i = @i + 1
	END

	BEGIN
		DELETE dbo.AffGroupPermissionDetail
		WHERE ObjectID = @UserID
			AND GroupID = @GroupID -- LicenseeID

		INSERT INTO dbo.AffGroupPermissionDetail (
			GroupID
			,TypeID
			,AttributeID
			,ObjectID
			)
		SELECT @GroupID
			,1
			,CurrencyID
			,@UserID
		FROM #Currency
		WHERE STATUS = 1

		-------------------------------------
		DROP TABLE #Currency

		EXEC sp_xml_removedocument @iDoc

		-------------------------------------
		IF (@@ERROR <> 0)
		BEGIN
			SELECT @ErrMsg = CASE @Langkey
					WHEN 'en-US' THEN 'Update process is unsuccessful!'
					ELSE 'Update process is unsuccessful!'
					END
				,@ErrCode = 101
		END

		SELECT @LogSPData = '<Aff_UserCurrencyIns GroupID="' + COALESCE(CAST(@GroupID AS VARCHAR(50)), SPACE(1)) + '" ' + 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" ' + 'Modifyby="' + COALESCE(CAST(@ModifyBy AS VARCHAR(50)), SPACE(1)) + '" ' + 'CurrencyID="' + COALESCE(CAST(@LogSPData2 AS VARCHAR(500)), SPACE(1)) + '" ' + 'Language="' + COALESCE(CAST(@Langkey AS VARCHAR(10)), SPACE(1)) + '" ' + 'IP="' + COALESCE(CAST(@IP AS VARCHAR(40)), SPACE(1)) + '" ' + 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' + 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(5000)), SPACE(1)) + '" />'

		SET @endRun = GETDATE()
		SET @duration = datediff(millisecond, @startRun, @endRun)

		EXEC dbo.Aff_WriteLog_UserLog_RunSP @Creator = @ModifyBy
			,@AffID = @UserID
			,@SPName = 'Aff_UserCurrencyIns'
			,@Details = @LogSPData
			,@IsAdmin = 1
			,@IP = @IP
	END
END
