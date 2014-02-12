ALTER Procedure [dbo].[Aff_CommGroupSelListNormal]   
 @AffID int=-1,  
 @Currency varchar(5)=null,    
    @GroupID int=-1 output  
AS  
  
/*  
Created: 20090719@DungTong  
Task : Get Commission Group List (groupid<1000) for dropdown list  
DB: DB052.Affiliate_ZZun  
Original:  
  
Params Explaination:  
   if AffID<> -1: need to check whether this private group is already assigned to this Aff  
   output : Change AffID=0 if existed  
Revisions:  
*/  
SET NOCOUNT ON  
if(@AffID<>-1)  
begin  
 select @GroupID=GroupID,@Currency=Currency from AffInfo (nolock) where AffId=@AffID  
end  
  
select   
 GroupId,   
 GroupName      
from CommGroup with (nolock)       
where GroupID <1000 and IsDeleted=0 and  currency=coalesce(@Currency,currency)  
	 
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelListNormal] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelListNormal] TO [vnteam]