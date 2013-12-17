ALTER PROCEDURE  [dbo].[AffAdmin_UserCurrencyIns]		
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
	[Aff_UserCurrencyIns]		
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

SELECT @GroupID=GroupID FROM dbo.AdminUser WITH (NOLOCK) WHERE CustID=@UserID
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
	DELETE dbo.AffGroupPermissionDetail WHERE ObjectID=@UserID AND GroupID=@GroupID -- LicenseeID
	
	INSERT INTO dbo.AffGroupPermissionDetail (GroupID,TypeID,AttributeID,ObjectID)
	SELECT @GroupID,1,CurrencyID,@UserID
	FROM #Currency
	WHERE status=1
	
	-------------------------------------
	DROP TABLE #Currency
	exec sp_xml_removedocument @iDoc		
	-------------------------------------
	IF (@@ERROR<>0)	
		BEGIN 
			SELECT @ErrCode = 2010
		END 
	SELECT @LogSPData = '<Aff_UserCurrencyIns GroupID="'+ COALESCE(CAST(@GroupID as VARCHAR(50)),SPACE(1)) + '" ' +
			'UserID="'+ COALESCE(CAST(@UserID as VARCHAR(50)),SPACE(1)) + '" ' +
			'Modifyby="'+ COALESCE(CAST(@ModifyBy as VARCHAR(50)),SPACE(1)) + '" ' +
			'CurrencyID="'+ COALESCE(CAST(@LogSPData2  as VARCHAR(500)),SPACE(1)) + '" ' +
			'Language="'+ COALESCE(CAST(@Langkey as VARCHAR(10)),SPACE(1)) + '" ' +
			'IP="'+ COALESCE(CAST(@IP as VARCHAR(40)),SPACE(1)) + '" ' +
			'ErrCode="'+ COALESCE(CAST(@ErrCode as VARCHAR(50)),SPACE(1)) + '" '

	SET @endRun = GETDATE()
	SET @duration  = datediff (millisecond,@startRun,@endRun)

	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @ModifyBy,
		@CustID = @UserID,
		@ActionID = 2801,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = '',
		@duration = @duration


END


