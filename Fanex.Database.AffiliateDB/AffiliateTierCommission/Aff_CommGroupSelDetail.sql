ALTER Procedure [dbo].[Aff_CommGroupSelDetail]   
 @GroupId int = null,    
 @AffID int = null  
AS  
/*  
Created: 20090719@DungTong  
Task : Get Group Setting for Editing an existing Group  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
*/  
SET NOCOUNT ON  
  
if @AffID is not null   
begin  
 select @GroupId = groupid from affinfo with(nolock) where affid = @AffID  
end  
  
select GroupID,GroupName,g.CreatedDate,g.Creator,Description,e.ExchangeID,e.Code as Currency,QualifiedAmount,  
  (case when Exists(select top(1) 1 from AffCommission(nolock) where GroupID=g.GroupID)   
     or Exists(select top(1) 1 from AffInfo ai (nolock) where ai.GroupID=g.GroupID)  then 0 else 1 end) as IsCurrencyEditable  
from CommGroup g (nolock)  
inner join dbo.Exchange e on g.Currency = e.ExchangeID  
where GroupID=@GroupID  
  
select g.GroupID,g.ProductID,g.TierID,g.MinAmount,g.MaxAmount,g.MinQM,g.MaxQM,g.Commission  
from GroupSetting g (nolock)       
where g.GroupID=@GroupID   
  
Select DeductionID, DeductedPercentage  
from DeductionSetting (nolock)  
where GroupID=@GroupID  
  
Select top(1000) ProductID,ProductName  
 from Product (nolock)  
   
Select top(100)  DTypeID,ProductID,DTypeName,DTypeDesc,DeductedPercentage   
from DeductionType (nolock)  
  
Select SValue as SupportedBaseCurrencies from SystemSettings (nolock) where Type='meta' and SName='SupportedBaseCurrencies'  
   
	
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelDetail] TO [vnteam]
