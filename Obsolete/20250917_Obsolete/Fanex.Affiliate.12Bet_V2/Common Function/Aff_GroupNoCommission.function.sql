set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER FUNCTION [dbo].[Aff_GroupNoCommission]
(
	@Month int,
	@Year int
)
RETURNS @AffGroup TABLE(GroupID int, SportId int)  
AS 
BEGIN

Declare @TmpAllGroupAndSport Table(GroupId int, SportId int)--Temp table Store All GroupId and SportId

Declare @MaxAmount money, @MaxQM int, @CurrentMonth smalldatetime, @DateCalculate smalldatetime
select @CurrentMonth = current_timestamp
		, @MaxAmount = 100000000000000
		, @MaxQM = 1000000000
		, @DateCalculate = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)



		
if(datediff(m, @CurrentMonth, @DateCalculate) = 0)
Begin
	insert into @TmpAllGroupAndSport(GroupId, SportId)
	select GroupId, SportId
	From (select distinct GroupId from GroupSetting (nolock)) as g
		, (select SportId from SportType nolock) as sp


	insert into @AffGroup(GroupID, SportId)
	select GroupId, SportType
	from GroupSetting nolock
	Where Commission = 0 
		and MinAmount = 0
		and MaxAmount = @MaxAmount
		and MinQM = 0 
		and MaxQM = @MaxQM
	
	Union All

	select distinct t.GroupId, t.SportId
	from @TmpAllGroupAndSport as t
		left join GroupSetting as g on t.GroupId = g.GroupId and t.SportId = g.SportType
	where g.GroupId is null and g.SportType is null
end
Else
Begin	
	

	insert into @TmpAllGroupAndSport(GroupId, SportId)
	select GroupId, SportId
	From (select distinct GroupId from GroupSettingHistory (nolock) where datediff(m, @DateCalculate, MonthDate) = 0) as g
		, (select SportId from SportType nolock) as sp


	insert into @AffGroup(GroupID, SportId)
	select GroupId, SportType
	from GroupSettingHistory nolock
	Where Commission = 0 
		and MinAmount = 0 
		and MaxAmount = @MaxAmount
		and MinQM = 0 
		and MaxQM = @MaxQM
		and datediff(m, @DateCalculate, MonthDate) = 0
	
	Union All

	select distinct t.GroupId, t.SportId
	from @TmpAllGroupAndSport as t
		left join (select distinct GroupId, SportType 
					from GroupSettingHistory (nolock) 
					where datediff(m, @DateCalculate, MonthDate) = 0
					) as g on t.GroupId = g.GroupId and t.SportId = g.SportType
	where g.GroupId is null and g.SportType is null
End

--Union with list sporttype that is not have setting for sporttype


RETURN
  
END


