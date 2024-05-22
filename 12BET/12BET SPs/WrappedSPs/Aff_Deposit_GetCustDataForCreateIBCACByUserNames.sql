/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Deposit_GetCustDataForCreateIBCACByUserNames
	@deposit_usernames NVARCHAR(1000)
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

	EXEC DBDEPOSIT2.Deposit_DB.dbo.Deposit_GetCustDataForCreateIBCACByUserNames 
		@deposit_usernames = @deposit_usernames

END
GO