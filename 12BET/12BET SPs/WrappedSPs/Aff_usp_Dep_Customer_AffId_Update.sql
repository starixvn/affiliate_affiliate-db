/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_usp_Dep_Customer_AffId_Update
	@UserName 			NVARCHAR(30)
	,@AffiliateId 		INT
	,@DepositUsername 	NVARCHAR(30) = '' OUTPUT
	,@AffId 			INT = 0 OUTPUT
	,@ErrorCode 		SMALLINT OUTPUT
	,@ErrorMsg 			VARCHAR(200) OUTPUT
AS
/*
	Created: New Wrapper SPs, to execute the SPs of 12bet via linkedserver instead of web call directly
	DB: DBAFF12BET.Affiliate_12BET
	Task: 

	Revisions:
		- 20240604@Eddie: Initiliaze SP [RedmineID: #180516]

*/
BEGIN
	SET NOCOUNT ON

	EXEC DBDEPOSIT2.Deposit_DB.dbo.usp_Dep_Customer_AffId_Update 		
		@UserName 			= @UserName
		,@AffiliateId 		= @AffiliateId
		,@DepositUsername 	= @DepositUsername OUTPUT
		,@AffId 			= @AffId OUTPUT
		,@ErrorCode 		= @ErrorCode OUTPUT
		,@ErrorMsg 			= @ErrorMsg OUTPUT

END
GO