 USE [Deposit_DB]
GO
/****** Object:  StoredProcedure [dbo].[DEP_AffiliateGeneralInfo]    Script Date: 10/06/2009 08:53:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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

	SELECT @MemInProAllNum = count(1)
	FROM Deposit_Customer with(nolock) 	
	WHERE AffiliateID > 0

	SELECT @MemInProMonthNum = count(1)
	FROM Deposit_Customer with(nolock) 
	WHERE AffiliateID > 0 AND datediff(mm, creatdate, CURRENT_TIMESTAMP) = 0

	SELECT  
		@MemInProAllNum as MemInProAllNum,
		@MemInProMonthNum as MemInProMonthNum
END


GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateGeneralInfo] TO [bodbAffiliateNet]