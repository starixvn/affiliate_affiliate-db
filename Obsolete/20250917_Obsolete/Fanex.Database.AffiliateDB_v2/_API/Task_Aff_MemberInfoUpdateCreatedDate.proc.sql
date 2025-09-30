ALTER PROCEDURE [dbo].[Task_Aff_MemberInfoUpdateCreatedDate]   
	@XmlData XML,  
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(500) = '' OUTPUT  
AS   
/*
	Task : Update created date for users deposited
	Author : Johnny@20130328
	DB: DB052.Affiliate_ZZun
	Original: [Aff_MemberInfoImportData]
	Revisions: 		
		Johnny@2013Mar27: Fix to update Clickstatistics, Clickstatistics_bk and ClickstatisticsSum table
*/

--Import new Data here 
DECLARE @TmpClick TABLE (ClickId  bigint)
 
DECLARE @TempTrans TABLE(UserName varchar(30), IBCUserName varchar(50), Date datetime)  
  
insert into @TempTrans --Convert xml to table  
  
Select      
	[Table].[Column].value('./@username', 'varchar(30)') as [UserName],    
	[Table].[Column].value('./@ibcusername', 'varchar(50)') as [IBCUserName],    
	[Table].[Column].value('./@date', 'datetime') as [Date]  
from @XmlData.nodes('/root/trans') as [Table]([Column])  

UPDATE m  
SET m.CreatedDate= temp.Date   
	, m.IBCUsername = temp.IBCUserName
OUTPUT Inserted.ClickId INTO @TmpClick
FROM MemberInfo AS m   
	INNER JOIN @TempTrans AS temp ON m.UserName = temp.UserName;  



--Update Click Statistics
Declare @MinClickID bigint, @MinClickID_Statistics bigint

Select @MinClickID = min(ClickId)
from @TmpClick

select @MinClickID_Statistics = min(ClickId)
from ClickStatistics nolock

if @MinClickID < @MinClickID_Statistics
begin
	--Temp table to insert click value to update to clickstatisticsSum table
	Declare @TmpClickDetail table ([date] smalldatetime)

	insert into @TmpClickDetail(date)
	Select distinct c.date
	from @TmpClick as t
		inner join ClickStatistics_bk as c on t.[clickId] = c.ClickID
	where c.ClickId < @MinClickID_Statistics
	
	Delete ClickStatisticsSum
	where Date in (Select [DATE] from @TmpClickDetail)
	 --Summary for Daily by Domain and Date
	insert into ClickStatisticsSum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
	select  c.AffID,
			DomainReferrer,
			c.[Date] as [Date],
			SportCode,
			LanguageCode,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM 
	from ClickStatistics_bk c with (nolock)
		inner join @TmpClickDetail t on c.Date = t.Date
		left join 
			(Select ClickId, 
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from MemberInfo m with (nolock) 			
			group by ClickId
			) as m on c.ClickId = m.ClickId
	group by c.AffID, DomainReferrer, c.[Date], SportCode, LanguageCode
end

GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoUpdateCreatedDate] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoUpdateCreatedDate] TO [bodbDownlineNetView]
GO