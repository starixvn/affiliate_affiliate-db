-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_DeductionSettingSel]
	@GroupIDList varchar(1000),
	@Date smalldatetime = null	
AS

/*
Created: 20130909@Joseph
Task : Get all deduction settings
DB: DB052.
Original:

Revisions:
*/
SET NOCOUNT ON

declare @TblGroup table (id int primary key, rank int, val nvarchar( 6) )
	
insert into @TblGroup 
select * from [dbo].[strSplit] ( @GroupIDList, ',' ) 

if  @Date is null or DateDiff(m,CURRENT_TIMESTAMP,@Date) >= 0
Begin
	Select ds.DeductionID,ds.GroupID,ds.DeductedPercentage,d.ProductID, d.DTypeName
	from DeductionSetting ds with(nolock)
		inner JOIN DeductionType d WITH(nolock) ON ds.DeductionID = d.DTypeId
	where ds.GroupID in (select val from @TblGroup)	
End
else
Begin
	Select ds.DeductionID,ds.GroupID,ds.DeductedPercentage,d.ProductID, d.DTypeName
	from dbo.DeductionSettingHistory ds (nolock)
		inner JOIN DeductionType d WITH(nolock) ON ds.DeductionID = d.DTypeId
	where ds.GroupID in (select val from @TblGroup)	
		and DATEDIFF(m, ds.MonthDate, @Date) = 0
End


GO
GRANT EXECUTE ON [dbo].[AffAdmin_DeductionSettingSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DeductionSettingSel] TO [vnteam]