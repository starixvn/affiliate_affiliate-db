/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE [bodb_licensee]
GO

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
		- 20160118@Francis: Add full currency permission for user that is changed to Administrator Group
		- 20180108@Percy: Fix issue duplicate currency [RedmineID: #89325]
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RemineID: #103658]
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
		
		DELETE dbo.CurrencyUser WITH (ROWLOCK, UPDLOCK)
		WHERE usrID = @UserID AND LicenseeID = @LicenseeID AND SystemID = @System

		INSERT INTO dbo.CurrencyUser (UsrID, LicenseeID, CurrencyID, SystemID, IsActive)
			SELECT @UserID, @LicenseeID, CurrencyID, @System, 1
			FROM @currency
	END
END
GO