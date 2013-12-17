-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_CommGroupSelDetail]	
	@GroupId int = null,		
	@AffID int = null
AS
/*
Created: 20090719@DungTong
Task : Get Group Setting for Editing an existing Group
DB: DB052.Affiliate_MYM
Original:

Revisions:
*/
SET NOCOUNT ON

if @AffID is not null 
begin
	select @GroupId = groupid from affinfo with(nolock) where affid = @AffID
end

select GroupID,GroupName,g.CreatedDate,g.Creator,Description,g.Currency,QualifiedAmount,
		(case when Exists(select top(1) 1 from AffCommission(nolock) where GroupID=g.GroupID) 
					or Exists(select top(1) 1 from AffInfo ai (nolock) where ai.GroupID=g.GroupID)  then 0 else 1 end) as IsCurrencyEditable
from CommGroup g (nolock)
where GroupID=@GroupID


GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupSelDetail] TO [vnteam]