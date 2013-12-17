ALTER Procedure [Aff_CommGroupSelDetail]	
	@GroupId int = null,		
	@AffID int = null
AS
/*
Created: 20090719@DungTong
Task : Get Group Setting for Editing an existing Group
DB: DB052.Affiliate_12Bet
Original:

Revisions:
*/
SET NOCOUNT ON

if @AffID is not null 
begin
	select @GroupId = groupid from affinfo with(nolock) where affid = @AffID
end

select GroupID,GroupName,CreatedDate,Creator,Description
from CommGroup (nolock)
where GroupID=@GroupID

select g.GroupID,g.SportType,g.TierID,g.MinAmount,g.MaxAmount,g.MinQM,g.MaxQM,g.Commission
from GroupSetting g (nolock)     
where g.GroupID=@GroupID 

Select DeductionID, DeductedPercentage
from DeductionSetting (nolock)
where GroupID=@GroupID

Select top(1000) SportID,SportName, QMTurnOver
	from SportType (nolock)
	
Select top(100)  DTypeID,SportID,DTypeName,DTypeDesc,DeductedPercentage 
from DeductionType (nolock)
	
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelDetail] TO [vnteam]
