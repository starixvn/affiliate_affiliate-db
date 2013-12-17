ALTER Procedure [Aff_CommGroupSelListNormal]	
	@AffID int=-1,
	@GroupID int=-1 output
AS

/*
Created: 20090719@DungTong
Task : Get Commission Group List (groupid<1000) for dropdown list
DB: DB052.Affiliate_12Bet
Original:

Params Explaination:
   if AffID<> -1: need to check whether this private group is already assigned to this Aff
   output : Change AffID=0 if existed
Revisions:
*/
SET NOCOUNT ON
if(@AffID<>-1)
begin
	select @GroupID=GroupID from AffInfo (nolock) where AffId=@AffID
end

select 
	GroupId,	
	GroupName    
from CommGroup with (nolock)
	 
where GroupID <1000 and IsDeleted=0
	 
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelListNormal] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelListNormal] TO [vnteam]