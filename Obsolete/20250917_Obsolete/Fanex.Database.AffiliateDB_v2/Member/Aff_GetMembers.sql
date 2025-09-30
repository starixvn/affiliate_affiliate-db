

ALTER PROCEDURE [dbo].[Aff_GetMembers]  		
	@Date SMALLDATETIME  
AS   
/*
	Created: 2013@Joseph	
	Task : Get list of member for task import member daily
	DB:  DB052.Affiliate_ZZun for Testing
	Revisions:
		- 20130731@Don : Fixed bug [Data isn't saved in DB when winlostdate < transdate in table bodb02.bettrans] (redmine.nexcel.vn/issues/4195)
		
*/
Select m.username  
from dbo.MemberInfo m (nolock)
left join dbo.MemberRemoval m1 (nolock) on m1.username=m.username
where datediff(d,m.RegisteredDate, cast(@Date as varchar(50)))>=-1 and 
(m.IsRemoved=0 or (m.IsRemoved=1 and datediff(m, cast(@Date as varchar(50)) 
,isnull(m1.RemovedDate,GetDate()))>0)) and m.CreatedDate is not null
   
GO
GRANT EXECUTE ON [dbo].[Aff_GetMembers] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMembers] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMembers] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetMembers] TO [vnTeam]
GO