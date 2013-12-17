-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_GroupSettingSel]
	@GroupId int	
AS
/*
Created: 20090719@DungTong
Task : Get Group Setting for Editing an existing Group
DB: DB052.Affiliate_MYM
Original:

Revisions:
*/
SET NOCOUNT ON

select g.GroupID,g.ProductID,g.TierID,g.MinAmount,g.MaxAmount,g.MinQM,g.MaxQM,g.Commission
from GroupSetting g (nolock)     
where g.GroupID=@GroupId


GO
GRANT EXECUTE ON [dbo].[AffAdmin_GroupSettingSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_GroupSettingSel] TO [vnteam]