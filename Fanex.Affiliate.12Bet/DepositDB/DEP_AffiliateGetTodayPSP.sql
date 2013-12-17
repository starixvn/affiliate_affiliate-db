ALTER PROCEDURE [dbo].[DEP_AffiliateGetTodayPSP]	
	@affID int = 0,	
	@PSP money = 0 OUTPUT
AS
/*
	Created: 20091230@Bryan
	Task : Get PSP for member or mebers follow affiliate
	DB: DBDEPOSIT.DEPOSIT_DB
	Revisions:
		- 20091230@Bryan initialize
		
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
			and AffiliateID=@affID
	) c on di.CustID = c.CustId
where status=2 and datediff(dd, di.ApprovedDate, getdate()) = 0


select @PSP2 = isnull(sum(di.chargefee),0)
from deposit_withdrawalinfo di with (nolock)
	inner join
	(
		Select CustID 
		from Deposit_Customer with (nolock) 
		where ActStatus = 2 
			and AffiliateID=@affID
	) c on di.CustID = c.CustId
where status=2 and datediff(dd, di.ApprovedDate, getdate()) = 0

select @PSP = isnull(@PSP1, 0) + isnull(@PSP2, 0)

GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateGetTodayPSP] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_AffiliateGetTodayPSP] TO [VNTeam]