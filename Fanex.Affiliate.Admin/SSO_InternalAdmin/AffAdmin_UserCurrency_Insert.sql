/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_UserCurrency_Insert]
	@UserID			INT,
	@LicenseeID		INT,
	@currencyIDs	VARCHAR(1000),
	@IsActive		INT = 1
AS

/*
	Created: 20151118@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Insert User's Currency
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @System INT
	SELECT  @System = id FROM dbo.Systems WITH (NOLOCK) WHERE SystemName LIKE 'AFF'

	DECLARE @CurrencyList TABLE (CurrencyID INT)
	INSERT INTO @CurrencyList (CurrencyID)
	SELECT CAST(val AS INT) FROM dbo.Lrf_f_StringSplit(@currencyIDs, ',')
	
	INSERT INTO dbo.CurrencyUser (usrID, LicenseeID, CurrencyID, SystemID, isActive)
	SELECT @UserID, @LicenseeID, CurrencyID, @System, @IsActive -- Affiliate
	FROM @CurrencyList
END
GO