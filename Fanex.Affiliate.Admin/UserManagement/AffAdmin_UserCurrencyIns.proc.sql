ALTER PROCEDURE  [dbo].[AffAdmin_UserCurrencyIns]		
	@LicenseeID INT,
	@UserID INT,
	@CurrencyXML VARCHAR(max),
	@ModifyBy INT,
	@Langkey VARCHAR(10) = 'en-US',
	@IP VARCHAR(40),
	@ErrCode INT = 0 OUTPUT
AS	
/*
Created:20130729@Jim
Task :  Restrict permission of Aff Users by currency
DB: DBLIC.Affiliate_Alpha


Revisions:
    -20131223@Bobby: delete current setting on AffGroupPermissionDetail
	-20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
Param's Explanation:
@CurrencyXML format:

'<currencies>
 <currency currencyid=''5'' status=''1'' > 
</currency>
 <currency currencyid=''4'' status=''1''>
</currency>
</currencies>'

*/
/*
	[AffAdmin_UserCurrencyIns]		
	@UserID =1,
	@CurrencyXML =
	'<currencies>
	<currency currencyid=''101'' status=''1'' > 
	</currency>
	<currency currencyid=''100'' status=''1''>
	</currency>
	</currencies>',
	@ModifyBy =1,
	@Langkey  = 'en-US',
	@IP ='NULL'
*/
SET NOCOUNT ON

DECLARE @GroupID INT
DECLARE @startRun DATETIME
DECLARE @endRun DATETIME
DECLARE @duration INT
DECLARE @LogSPData VARCHAR(5000)
DECLARE @LogSPData2 VARCHAR(5000)
SET @startRun = GETDATE()
DECLARE @iDoc INT , @i INT, @max INT 

CREATE TABLE  #Currency (ID INT IDENTITY(1,1),currencyid INT, status INT)
EXEC sp_xml_preparedocument @iDoc OUTPUT,@CurrencyXML

SELECT @GroupID=GroupID FROM dbo.AffAdmin_f_AdminUserInfo_Select(@UserID, @LicenseeID)
INSERT INTO #Currency (CurrencyID,status)
SELECT CurrencyID,status
FROM 
	OPENXML(@iDoc,'/currencies/currency',0)
WITH (currencyid varchar(20),status varchar(10))
SELECT @i=1,@max=MAX(ID) FROM #currency 
SET @LogSPData2=''
WHILE (@i<=@max)
	BEGIN 
		
		SELECT @LogSPData2=@LogSPData2+','+CONVERT(VARCHAR(10),CurrencyID) 
		FROM #Currency 
		WHERE ID=@i
		AND status=1
		SET @i=@i+1	
	END

BEGIN
	EXEC DBLIC.bodb_licensee.dbo.AffAdmin_UserCurrency_Delete @UserID = @UserID, @LicenseeID = @LicenseeID
	
	DECLARE @CurrencyIDs VARCHAR(1000)

	SELECT	@CurrencyIDs = COALESCE(@CurrencyIDs + ', ', '') + CONVERT(VARCHAR(10), CurrencyID)
	FROM	#Currency 
	WHERE status = 1

	EXEC DBLIC.bodb_licensee.dbo.AffAdmin_UserCurrency_Insert @UserID = @UserID, @LicenseeID = @LicenseeID, @CurrencyIDs = @CurrencyIDs, @IsActive = 1
	
	-------------------------------------
	DROP TABLE #Currency
	exec sp_xml_removedocument @iDoc		
	-------------------------------------
	IF (@@ERROR<>0)	
		BEGIN 
			SELECT @ErrCode = 2010
		END 
	SELECT @LogSPData = '<AffAdmin_UserCurrencyIns GroupID="'+ COALESCE(CAST(@GroupID as VARCHAR(50)),SPACE(1)) + '" ' +
			'UserID="'+ COALESCE(CAST(@UserID as VARCHAR(50)),SPACE(1)) + '" ' +
			'Modifyby="'+ COALESCE(CAST(@ModifyBy as VARCHAR(50)),SPACE(1)) + '" ' +
			'CurrencyID="'+ COALESCE(CAST(@LogSPData2  as VARCHAR(500)),SPACE(1)) + '" ' +
			'Language="'+ COALESCE(CAST(@Langkey as VARCHAR(10)),SPACE(1)) + '" ' +
			'IP="'+ COALESCE(CAST(@IP as VARCHAR(40)),SPACE(1)) + '" ' +
			'ErrCode="'+ COALESCE(CAST(@ErrCode as VARCHAR(50)),SPACE(1)) + '" '

	SET @endRun = GETDATE()
	SET @duration  = datediff (millisecond,@startRun,@endRun)

	EXEC [dbo].[Aff_WriteLog_UserLog_RunSP]
			@Creator=@ModifyBy,	
			@AffID=@UserID,
			@SPName='AffAdmin_UserCurrencyIns' ,		
			@IP =@IP,
			@Details=@LogSPData	

	--EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
	--	@UserID = @ModifyBy,
	--	@CustID = @UserID,
	--	@ActionID = 2801,
	--	@TrackingValue = @LogSPData,
	--	@TrackingValue2 = '',
	--	@duration = @duration
END