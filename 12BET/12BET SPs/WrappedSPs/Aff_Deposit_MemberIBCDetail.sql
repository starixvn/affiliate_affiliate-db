/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Deposit_MemberIBCDetail
	@DepUserName NVARCHAR(1000),
	@IbcCustId INT,
	@IbcUserName NVARCHAR(1000),
	@ErrorCode INT OUTPUT,
	@ErrorMsg NVARCHAR(1000) OUTPUT
AS
/*
	Created: New Wrapper SPs, to execute the SPs of 12bet via linkedserver instead of web call directly
	DB: DBAFF12BET.Affiliate_12BET
	Task: 

	Revisions:
		- 20240420@Sophia: Initiliaze SP [RedmineID: #204146]

*/
BEGIN
	SET NOCOUNT ON

	EXEC DBDEPOSIT2.Deposit_DB.dbo.Deposit_MemberIBCDetail 		
		@DepUserName = @DepUserName,
		@IbcCustId = @IbcCustId,
		@IbcUserName = @IbcUserName,
		@ErrorCode = @ErrorCode OUTPUT,
		@ErrorMsg = @ErrorMsg OUTPUT

END
GO