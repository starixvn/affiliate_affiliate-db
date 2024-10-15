/*<info serverAlias="DBCUST-bodb_licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Con_AccountUpd]
	@UserID			INT,
	@LicenseeID		INT,
	@GroupID		INT,
	@CurrencyIds	VARCHAR(MAX),
	@ModifyBy		INT,
	@ErrCode		INT = 0 OUTPUT

/*
	Created: 20240824@Sally
	DB: DBCUST-bodb_licensee
	Task: Remove linked server to DBCust
	Org: DBAFF-Affiliate_Athena000/dbo.AffAdmin_Con_AccountUpd

	Revision:
		- 20240809@Sally: Initialize SP [RedmineID: #206891] 

	Param's Explanation:
		@CurrencyIds : PartnerExchangeID   

*/
AS
BEGIN
	DECLARE @AdminGroupID INT 
	
	UPDATE Aff_LicenseeUser WITH (ROWLOCK, UPDLOCK) 
	SET GroupID	   = @GroupID,
		ModifyDate = GETDATE(),
		@ModifyBy  = ISNULL(@ModifyBy, ModifyBy)
	WHERE UserID = @UserID
		AND LicenseeID = @LicenseeID
	
	SELECT @AdminGroupID = GroupID 
	FROM dbo.Aff_GroupInfo WITH (NOLOCK) 
	WHERE LicenseeID = @LicenseeID 
		AND GroupName = 'Administrator'
	
	IF (@AdminGroupID = @GroupID)
	BEGIN

		DECLARE @Currency AS TABLE (CurrencyID INT)
		DECLARE @System INT
		
		SELECT @System = id 
		FROM dbo.Systems WITH (NOLOCK) 
		WHERE SystemName LIKE 'AFF'
	
		INSERT INTO @Currency (CurrencyID)
		SELECT CONVERT(INT, value) AS CurrencyID
		FROM STRING_SPLIT(@CurrencyIds, ',')t
		
		DELETE dbo.CurrencyUser WITH (ROWLOCK, UPDLOCK)
		WHERE usrID = @UserID 
			AND LicenseeID = @LicenseeID 
			AND SystemID = @System

		INSERT INTO dbo.CurrencyUser (UsrID, LicenseeID, CurrencyID, SystemID, IsActive)
			SELECT @UserID, @LicenseeID, CurrencyID, @System, 1
			FROM @currency
	END

	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 502 -- Error occurs.Update unsucessfully.
		RETURN
	END
END
GO
