-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_CommGroupDetailSel]
	@GroupIDList varchar(1000),
	@Date smalldatetime = null	
AS

/*
Created: 20130909@Joseph
Task : Get all group details
DB: DB052.
Original:

Revisions:
*/
SET NOCOUNT ON

declare @TblGroup table (GroupID int)

insert into @TblGroup 
select DISTINCT val as GroupId from [dbo].[strSplit] ( @GroupIDList, ',' ) 

if  @Date is null or DateDiff(m,CURRENT_TIMESTAMP,@Date) >= 0
	select 
		g.GroupId,	
		g.ProductID,
		s.ProductName,
		g.TierID,
		g.MinAmount,
		g.MaxAmount,
		g.MinQM,
		g.MaxQM,
		g.Commission	
	from GroupSetting g with (nolock)
		 inner join Product s with (nolock) on s.ProductID=g.ProductID
	where g.GroupID in (
		 select GroupID from @TblGroup
	   )
else
	select 
		g.GroupId,	
		g.ProductID,
		s.ProductName,
		g.TierID,
		g.MinAmount,
		g.MaxAmount,
		g.MinQM,
		g.MaxQM,
		g.Commission	
	from dbo.GroupSettingHistory g with (nolock)
		 inner join Product s with (nolock) on s.ProductID=g.ProductID
	where g.GroupID in (
		 select GroupID from @TblGroup
	   ) AND datediff(m, g.MonthDate, @Date) = 0

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupDetailSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupDetailSel] TO [vnteam]