ALTER PROCEDURE [dbo].[Task_Aff_MemberInfoImportData]	
	@AdminID int,	
	@XmlData XML,	
	@RegisteredDate smalldatetime,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*
	Task : Import member info from xml into table MemberInfo
	Author : Joseph@20130114
	DB: DB052.Affiliate_ZZun
	Original: [Aff_MemberInfoImportData]
	Revisions: 		
		20120122: apply currency converter
		Johnny@2013Mar27: Fix to update Clickstatistics table
		20130913@Don: Add more columns to table [MemberInfo]
*/
BEGIN  
SET NOCOUNT ON  

DECLARE @TmpTable TABLE (UserName  VARCHAR(30))
--Import new Data here
DECLARE @TempTrans TABLE(
	UserName varchar(30),
	DepositCustID int,
	Btag varchar(100), 
	AffID int,
	ClickID bigint,
	RegisteredDate datetime, 
	Currency varchar(6),
	CountryID varchar(8),
	Email varchar(8),
	FirstName varchar(8),
	LastName varchar(8),
	Phone varchar(8),
	Address varchar(8)

insert into @TempTrans --Convert xml to table

Select
		
		[Table].[Column].value('./@username', 'varchar(30)') as [UserName],
		[Table].[Column].value('./@playerid', 'int') as [DepositCustID],
		[Table].[Column].value('./@btag', 'varchar(100)') as [Btag],		
		[Table].[Column].value('./@affid', 'int') as [AffID],		
		[Table].[Column].value('./@clickid', 'int') as [ClickID],		
		@RegisteredDate as [RegisteredDate],
		[Table].[Column].value('./@currency', 'varchar(6)') as [Currency],
		[Table].[Column].value('./@country', 'varchar(8)') as [CountryID],
		[Table].[Column].value('./@Email', 'nvarchar(50)') as [Email],
		[Table].[Column].value('./@FirstName', 'nvarchar(50)') as [FirstName],
		[Table].[Column].value('./@LastName', 'nvarchar(50)') as [LastName],
		[Table].[Column].value('./@Phone', 'varchar(20)') as [Phone],
		[Table].[Column].value('./@Address', 'nvarchar(255)') as [Address]
	from @XmlData.nodes('/root/trans') as [Table]([Column])

--Update info if this user exists in Memberinfo table
UPDATE m
SET 
	m.DepositCustID = temp.DepositCustID,	
	m.Btag = temp.Btag, m.AffID = temp.AffID,
	m.ClickID = temp.ClickID,
	m.Currency = cc.ExchangeID, 
	m.RegisteredDate = temp.RegisteredDate,
	m.CountryID = temp.CountryID,
	m.Email = temp.Email,
	m.FirstName = temp.FirstName,
	m.LastName = temp.LastName,
	m.Phone = temp.Phone,
	m.Address = temp.Address

OUTPUT Inserted.UserName INTO @TmpTable
FROM 
	MemberInfo AS m 
	INNER JOIN @TempTrans AS temp ON m.UserName = temp.UserName
	INNER JOIN CurrencyConverter cc ON temp.Currency = cc.PartnerCurrency AND cc.ApplicationID = 1
	inner join AffInfo as ai with(nolock) on m.AffId = ai.AffId

--insert new members into Memberinfo table
INSERT INTO MemberInfo(
			UserName, DepositCustID, Btag, 
			AffID, ClickID, Currency, CountryID, RegisteredDate,
			Email,FirstName,LastName,Phone,Address)
SELECT temp.UserName, temp.DepositCustID, temp.Btag, 
			temp.AffID, temp.ClickID, cc.ExchangeID,
			CountryID, temp.RegisteredDate,
			temp.Email,temp.FirstName,temp.LastName,temp.Phone,temp.Address
FROM @TempTrans temp
	INNER JOIN CurrencyConverter cc ON temp.Currency = cc.PartnerCurrency AND cc.ApplicationID = 1
	inner join AffInfo as ai with(nolock) on temp.AffId = ai.AffId
WHERE temp.UserName NOT IN (SELECT UserName FROM @TmpTable);


--Update Click Statistics
Declare @MinClickID bigint, @MinClickID_Statistics bigint

Select @MinClickID = min(ClickId)
from @TempTrans

select @MinClickID_Statistics = min(ClickId)
from ClickStatistics nolock

if @MinClickID < @MinClickID_Statistics
begin
	--Temp table to insert click value to update to clickstatisticsSum table
	Declare @TmpClickDetail table ([date] smalldatetime)

	insert into @TmpClickDetail(date)
	Select distinct c.date
	from @TempTrans as t
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


END  


GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoImportData] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberInfoImportData] TO [vnteam]