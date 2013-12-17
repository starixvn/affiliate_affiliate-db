Alter PROCEDURE [dbo].[DEP_AffiliateGetPSP]		
	@PSP money = 0 OUTPUT
AS
/*
	Created: 20091010@Johnny
	Task : Get Sum all of PSP for all members or mebers follow affiliate
	DB: DBDEPOSIT.DEPOSIT_DB
	Revisions:
		- 20091010@Johnny initialize
		
	Param's Explanation:		

*/
SET NOCOUNT ON

declare @PSP1 money, @PSP2 money

select @PSP1 = isnull(sum(di.chargefee),0)
from deposit_depositinfo di with (nolock)
	inner join
	(
		Select CustID 
		from Deposit_Customer with (nolock) 
		where ActStatus = 2 
			and isnull(AffiliateID, 0) <> 0
	) c on di.CustID = c.CustId
where status=2 and datediff(dd, di.ApprovedDate, getdate()) = 0


select @PSP2 = isnull(sum(di.chargefee),0)
from deposit_withdrawalinfo di with (nolock)
	inner join
	(
		Select CustID 
		from Deposit_Customer with (nolock) 
		where ActStatus = 2 
			and isnull(AffiliateID, 0) <> 0
	) c on di.CustID = c.CustId
where status=2 and datediff(dd, di.ApprovedDate, getdate()) = 0

select @PSP = isnull(@PSP1, 0) + isnull(@PSP2, 0)

GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateGetPSP] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_AffiliateGetPSP] TO [VNTeam]