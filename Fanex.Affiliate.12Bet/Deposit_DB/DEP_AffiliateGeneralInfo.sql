ALTER PROCEDURE [dbo].[DEP_AffiliateGeneralInfo]		
AS
/*
	Created: 20090828@Bryan
	Task : Gather overview statistic information of aff-admin site
	DB: DBDEPOSIT.DEPOSIT_DB
	Revisions:- 20090829@Bryan initialize
		
	Param's Explanation:

*/
SET NOCOUNT ON
BEGIN
	Declare 
		@NonDepositMemAllNum int,
		@MemInProAllNum int,
		@MemInProMonthNum int,
		@NonDepositMemMonthNum int

	SELECT @MemInProAllNum = count(1),
		@NonDepositMemAllNum = sum(CASE WHEN ActStatus=1 THEN 1 ELSE 0 END)
	FROM Deposit_Customer with(nolock) 	
	WHERE AffiliateID > 0

	SELECT @MemInProMonthNum = count(1),
		@NonDepositMemMonthNum = sum(CASE WHEN ActStatus=1 THEN 1 ELSE 0 END)
	FROM Deposit_Customer with(nolock) 
	WHERE AffiliateID > 0 AND datediff(mm, creatdate, CURRENT_TIMESTAMP) = 0



	SELECT  
		@NonDepositMemAllNum as NonDepositMemAllNum,
		@MemInProAllNum as MemInProAllNum,
		@MemInProMonthNum as MemInProMonthNum,
		@NonDepositMemMonthNum as NonDepositMemMonthNum
END

GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateGeneralInfo] TO [bodbAffiliateNet]
