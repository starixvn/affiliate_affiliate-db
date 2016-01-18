ALTER PROCEDURE [dbo].[AffAdmin_AdminUser_UpdateGroup]
(
	@UserID		INT,
	@LicenseeID	INT,
	@GroupID	INT,
	@ModifyDate	DATE = NULL,
	@ModifyBy	INT = NULL
)
/*
	Created: 20151125@Victor
	DB: DBLIC/bodb_licensee
	Remark: Update Admin user group
	Revision:
	-20160118@Francis: Add full currency permission for user that is changed to Administrator Group
*/
AS
BEGIN
	DECLARE @AdminGroupID INT 
	
	UPDATE Aff_LicenseeUser WITH (ROWLOCK, UPDLOCK) 
	SET GroupID = @GroupID,
		ModifyDate = ISNULL(@ModifyDate, GETDATE()),
		@ModifyBy = ISNULL(@ModifyBy, ModifyBy)
	WHERE UserID = @UserID
		AND LicenseeID = @LicenseeID
	
	SELECT @AdminGroupID = GroupID 
	FROM Aff_GroupInfo WITH (NOLOCK) 
	WHERE LicenseeID = @LicenseeID AND GroupName = 'Administrator'
	
	IF (@AdminGroupID = @GroupID)
	BEGIN
		DECLARE @LicenseeName VARCHAR(50)
		DECLARE @Currency AS TABLE (CurrencyID INT)
		DECLARE @cmd VARCHAR(8000)
		DECLARE @System INT
		
		SELECT @System = id 
		FROM dbo.Systems WITH (NOLOCK) 
		WHERE SystemName LIKE 'AFF'
		
		SELECT @LicenseeName = LicenseeName
		FROM Licensees WITH (NOLOCK)
		WHERE LicenseeID = @LicenseeID
		
		SELECT @cmd = '
		DECLARE @AffiliateCurrencies varchar(4000)
		SELECT @AffiliateCurrencies = Svalue FROM DBAFF.Affiliate_' + @LicenseeName + '.dbo.SystemSettings WITH (NOLOCK) WHERE Sname = ''AffiliateCurrencies''

		SELECT cc.PartnerExchangeID
		FROM dbo.strSplit (@AffiliateCurrencies,'','')
		INNER JOIN DBAFF.Affiliate_' + @LicenseeName + '.dbo.Currency c WITH (NOLOCK) ON c.CurrencyCode = val
		LEFT JOIN DBAFF.Affiliate_' + @LicenseeName + '.dbo.CurrencyConverter cc WITH (NOLOCK) on c.CurrencyID = cc.ExchangeID'

		INSERT INTO @Currency (CurrencyID)
			EXEC (@cmd)	
		
		INSERT INTO dbo.CurrencyUser (UsrID, LicenseeID, CurrencyID, SystemID, IsActive)
			SELECT @UserID, @LicenseeID, CurrencyID, @System, 1
			FROM @currency
	END
	
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AdminUser_UpdateGroup] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AdminUser_UpdateGroup] TO [vnteam] AS [dbo]