-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_CommGroupSelByID]		
	@GroupID int,
	@UserId int
AS

/*
Created: 20131114@Joseph
Task : Search a Commission Group
DB: DB052.Affiliate_MYM
Original:
Revisions:	
	- 20131121@Joseph: filter by TestLevel
*/
SET NOCOUNT ON

SELECT AttributeID as CurrencyID INTO #tmpCurrency
FROM dbo.Aff_f_GetCurrencybyUser (@UserId,1)

DECLARE @IsITAdmin BIT
SELECT @IsITAdmin = CASE GroupID WHEN 2 THEN 1 ELSE 0 END FROM AdminUser WHERE custid = @UserId

SELECT cg.GroupID,GroupName,Description,isnull(i.username,'System') as Creator,
cg.CreatedDate,e.CurrencyID,e.CurrencyCode as Currency,QualifiedAmount,
Count(ai.AffID) as NoOfAffiliate
from CommGroup cg with (nolock)
inner join dbo.Currency e on cg.Currency = e.CurrencyID			  
left join AdminUser i with (nolock) on i.custid=cg.Creator
left join AffInfo ai with (nolock) on ai.GroupID = cg.GroupID
where 			   
cg.GroupID = @GroupID
and (@IsITAdmin = 1 or ai.TestLevel in (0,1))
and (cg.Currency = 0 or (cg.Currency in (select CurrencyID from #tmpCurrency)))
group by cg.GroupID, cg.GroupName, cg.Description,cg.CreatedDate,cg.QualifiedAmount,
i.Username,e.CurrencyID,e.CurrencyCode
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelByID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupSelByID] TO [vnteam]