/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_UserCurrencyIns]
	@LicenseeID		INT,
	@UserID			INT,
	@CurrencyXML	VARCHAR(MAX),
	@ModifyBy		INT,
	@Langkey		VARCHAR(10) = 'en-US',
	@IP				VARCHAR(40),
	@ErrCode		INT = 0 OUTPUT
AS

/*
	Created: 20130729@Jim
	Task: Restrict permission of Aff Users by currency
	DB: DBAFF.Affiliate_XXX
	
	Revisions:
		- 20131223@Bobby: delete current setting on AffGroupPermissionDetail
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested SP & Function [RedmineID: #103658]
							AffAdmin_UserCurrency_Delete
							AffAdmin_UserCurrency_Insert
							AffAdmin_f_AdminUserInfo_Select

	Param's Explanation:
		@CurrencyXML format:
			'<currencies>
				<currency currencyid=''5'' status=''1'' ></currency>
				<currency currencyid=''4'' status=''1''> </currency>
			 </currencies>'
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData VARCHAR(5000), @LogSPData2 VARCHAR(5000)
	SELECT	@startRun = GETDATE()
	
	DECLARE @iDoc INT, @i INT, @max INT 

	CREATE TABLE #Currency (ID INT IDENTITY(1,1), currencyid INT, status INT)
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @CurrencyXML

	DECLARE @GroupID INT
	DECLARE @tblGroupID TABLE (GroupID INT)

	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql =
	'SELECT GroupID FROM OPENQUERY(DBCUST,
		''SELECT GroupID FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @UserID) + ', ' + CONVERT(VARCHAR(20), @LicenseeID) + ')'')'

	INSERT INTO @tblGroupID (GroupID)
	EXEC (@sql)

	SELECT @GroupID = GroupID FROM @tblGroupID
	
	INSERT INTO #Currency (CurrencyID, status)
	SELECT CurrencyID, status
	FROM OPENXML(@iDoc,'/currencies/currency', 0)
	WITH (currencyid VARCHAR(20),status VARCHAR(10))
	
	SELECT @i=1, @max = MAX(ID) FROM #currency
	
	SET @LogSPData2 = ''
	
	WHILE (@i<=@max)
	BEGIN 
		SELECT @LogSPData2 = @LogSPData2 + ',' + CONVERT(VARCHAR(10),CurrencyID)
		FROM #Currency
		WHERE ID = @i AND status = 1
		
		SET @i = @i + 1
	END

	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_UserCurrency_Delete @UserID = @UserID, @LicenseeID = @LicenseeID
	
	DECLARE @CurrencyIDs VARCHAR(1000)
	SELECT	@CurrencyIDs = COALESCE(@CurrencyIDs + ', ', '') + CONVERT(VARCHAR(10), cc.PartnerExchangeID)
	FROM #Currency c
		INNER JOIN dbo.CurrencyConverter cc WITH (NOLOCK) ON c.currencyid = cc.ExchangeID
	WHERE STATUS = 1

	EXEC DBCUST.bodb_Licensee.dbo.AffAdmin_UserCurrency_Insert @UserID = @UserID, @LicenseeID = @LicenseeID, @CurrencyIDs = @CurrencyIDs, @IsActive = 1
	
	-------------------------------------
	DROP TABLE #Currency
	exec sp_xml_removedocument @iDoc		
	-------------------------------------
	
	IF (@@ERROR <> 0)
	BEGIN 
		SELECT @ErrCode = 2010
	END 
	
	SELECT @LogSPData = '<AffAdmin_UserCurrencyIns GroupID="'+ COALESCE(CAST(@GroupID as VARCHAR(50)),SPACE(1)) + '" ' +
			'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
			'Modifyby="'+ COALESCE(CAST(@ModifyBy AS VARCHAR(50)),SPACE(1)) + '" ' +
			'CurrencyID="'+ COALESCE(CAST(@LogSPData2 AS VARCHAR(500)),SPACE(1)) + '" ' +
			'Language="'+ COALESCE(CAST(@Langkey AS VARCHAR(10)),SPACE(1)) + '" ' +
			'IP="'+ COALESCE(CAST(@IP AS VARCHAR(40)),SPACE(1)) + '" ' +
			'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '

	SET @endRun = GETDATE()
	SET @duration = datediff (millisecond, @startRun, @endRun)

	EXEC dbo.Aff_WriteLog_UserLog_RunSP
		@Creator	= @ModifyBy,
		@AffID		= @UserID,
		@SPName		= 'AffAdmin_UserCurrencyIns',
		@IP			= @IP,
		@Details	= @LogSPData
END
GO