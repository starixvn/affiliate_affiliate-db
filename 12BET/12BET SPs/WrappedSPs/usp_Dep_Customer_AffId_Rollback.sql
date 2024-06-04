/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_usp_Dep_Customer_AffId_Rollback
	@UserName 	NVARCHAR(30)
	,@ErrorCode SMALLINT OUTPUT
	,@ErrorMsg 	VARCHAR(200) OUTPUT
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

	EXEC DBDEPOSIT2.Deposit_DB.dbo.usp_Dep_Customer_AffId_Rollback 		
		@UserName 	= @UserName
		,@ErrorCode = @ErrorCode OUTPUT
		,@ErrorMsg 	= @ErrorMsg OUTPUT

END
GO