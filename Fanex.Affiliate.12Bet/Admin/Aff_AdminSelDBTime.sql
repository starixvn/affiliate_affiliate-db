Alter Procedure [Aff_AdminSelDBTime]
	@DBTime DateTime output,
	@GMTOffset varchar(20) output
AS
/*
Created: 20090708@DungTong
Task : Select current DB Time to display to website
DB: DB052.Affiliate_12BET
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
.@DBTime: OUTPUT of current DB Time,
*/
SET NOCOUNT ON
Select @DBTime=getdate()
declare @OffsetMinute int
select @OffsetMinute=DATEDIFF(minute,getutcdate(),getdate())

select @GMTOffset=' GMT'
if @OffsetMinute=0
  return   

if(@OffsetMinute>0) 
  set @GMTOffset=@GMTOffset + '+' 
else 
  set @GMTOffset=@GMTOffset + '-' 
select @OffsetMinute=abs(@OffsetMinute)
if(@OffsetMinute/60>= 10)
  set @GMTOffset=@GMTOffset + cast(@OffsetMinute/60 as varchar(5))
else
  set @GMTOffset=@GMTOffset + '0' + cast(@OffsetMinute/60 as varchar(5))

if @OffsetMinute%60 >= 10
	  set @GMTOffset=@GMTOffset + ':' + cast(@OffsetMinute%60 as varchar(5))
else
	  set @GMTOffset=@GMTOffset + ':0' + cast(@OffsetMinute%60 as varchar(5))

 
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSelDBTime] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSelDBTime] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSelDBTime] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminSelDBTime] TO [vnteam]