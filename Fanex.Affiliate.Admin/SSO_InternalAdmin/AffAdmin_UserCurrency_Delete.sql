/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_UserCurrency_Delete]
	@UserID	INT,
	@LicenseeID INT
AS

/*
	Created: 20151111@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Delete User's Currency data
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @System INT
	SELECT  @System = id FROM dbo.Systems WITH (NOLOCK) WHERE SystemName LIKE 'AFF'

	DELETE dbo.CurrencyUser WITH (ROWLOCK, UPDLOCK)
	WHERE SystemID = @System -- Affiliate
		AND UsrID = @UserID
		AND LicenseeID = @LicenseeID
END
GO