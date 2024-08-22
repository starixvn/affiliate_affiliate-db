/*<info serverAlias="DBCUST-bodb_Licensee" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_UserCurrencyIns]
	@LicenseeID		INT,
	@UserID			INT,
	@CurrencyIds	VARCHAR(MAX),
	@ErrCode		INT = 0 OUTPUT,
	@GroupID		INT = 0 OUTPUT
AS

/*
	Created: 20240806@Sally
	Task: Remove linked server to DBCust
	DB: DBCUST-bodb_Licensee
	Orig: DBAFF-Affiliate_Athena000/dbo.AffAdmin_UserCurrencyIns
	
	Revisions:
		- 20240806@Sally: Initialize SP [RedmineID: #206891]

	Param's Explanation:
		@CurrencyIds: CurrencyID of PartnerExchange
		@CurrencyIds =  '9,41,13,6'
*/

BEGIN

	SET NOCOUNT ON;

	SELECT @GroupID = GroupID 
	FROM dbo.AffAdmin_f_AdminUserInfo_Select(@UserID,@LicenseeID)

	EXEC dbo.AffAdmin_UserCurrency_Delete @UserID = @UserID, @LicenseeID = @LicenseeID	

	EXEC dbo.AffAdmin_UserCurrency_Insert @UserID = @UserID, @LicenseeID = @LicenseeID, @CurrencyIDs = @CurrencyIds, @IsActive = 1	

	IF(@@ERROR <> 0)
	BEGIN 
		SELECT @ErrCode = 2010 --Fail to update process
		RETURN
	END 

	SELECT @GroupID

END
GO
