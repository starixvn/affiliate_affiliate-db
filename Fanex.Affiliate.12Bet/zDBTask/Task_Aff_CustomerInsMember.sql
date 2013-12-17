ALTER PROCEDURE [dbo].[Task_Aff_CustomerInsMember]
	@Affid int = null,
	@CreatedDate smalldatetime = null--if this param is null => run for today
AS
/*  
	Created: 20120704@Johnny
	Task : Task Add members are missed in Deposit DB into MemberInfo table
	DB: DB052.Affiliate_12BET
	Revisions:    

*/ 
SET NOCOUNT ON
-- run to import yesterday missing members  
select @CreatedDate = convert(varchar(10), ISNULL(@CreatedDate, dateadd(d, -1, current_timestamp)), 120)  

DECLARE @TmpResult TABLE(IBCCustID int primary key, AffId int, UserName nvarchar(30), IBCUserName varchar(30), CreatedDate smalldatetime, 
	DepositCustID int, FirstName nvarchar(50), LastName nvarchar(50), Currency int, Recommend int, Email nvarchar(50), RegisteredDate smalldatetime, ClickId bigint)


INSERT INTO @TmpResult (
	IBCCustID,
	AffID,
	UserName,
	IBCUserName,
	CreatedDate,
	--IsRemoved,
	DepositCustID,
	FirstName,
	LastName,
	Currency,
	Recommend,
	Email,
	RegisteredDate,
	ClickId
)
select d.IBCCustID,
	AffiliateId as AffId,
	d.UserName,
	d.IBCUserName,
	CURRENT_TIMESTAMP as CreatedDate,
	--IsRemoved,
	d.CustId as DepositCustID,
	d.FirstName,
	d.LastName,
	d.Currency,
	d.IBCAgentID as Recommend,
	d.Email,
	d.creatdate as RegisteredDate,
	d.ClickId
from [DBDeposit].deposit_db.dbo.Deposit_Customer d with (nolock)
	left join MemberInfo m with(nolock) on d.AffiliateId = m.AffID and d.IBCCustID = m.IBCCustID
where DATEDIFF(d, CreatDate, @CreatedDate) = 0
	and AffiliateId > 0
	and (@Affid is null or AffiliateId = @Affid)
	and ActStatus in (2, 9)	
	and m.IBCCustID is null--These members in @CreatedDate does not exists in memberinfo 
	and  d.IBCCustID is not null
	--and DATEDIFF(d, m.RegisteredDate, @CreatedDate) = 0

if ((select count(*) from @TmpResult) > 0)
Begin
	------Insert data to MemberInfo table-----------
	insert into MemberInfo([IBCCustID]
		  ,[AffID]
		  ,[UserName]
		  ,[IBCUserName]
		  ,[CreatedDate]
		  ,[RegisteredDate]
		  ,[IsRemoved]
		  ,[DepositCustID]
		  ,[FirstName]
		  ,[LastName]
		  ,[Currency]
		  ,[Email]
		  ,[Recommend]
		  ,[ClickId])
	output inserted.UserName,inserted.CreatedDate into MissedMembers 
	select IBCCustID,
		AffID,
		'12bet$' + UserName,
		IBCUserName,
		CreatedDate,
		RegisteredDate,
		0 as IsRemoved,--default IsRemove = 0
		DepositCustID,
		FirstName,
		LastName,
		Currency,
		Email,
		Recommend,
		ClickId
	from @TmpResult


	Update ClickStatistics1 with (rowlock, updlock)
	set [status] = 2
	where ClickId in (Select ClickId from @TmpResult)

	if(exists(select 1 from ClickStatistics1_bk with (nolock) where ClickId in (Select min(ClickId) from @TmpResult)))
	Begin
		Declare @MinDateClick smalldatetime--To know start date and end date to update Summary table
		select @MinDateClick = [Date]
		from ClickStatistics1_bk nolock
		where ClickId in (Select min(ClickId) from @TmpResult)

		----Update status in backup table
		Update ClickStatistics1_bk with (rowlock, updlock)
		set [status] = 2
		where ClickId in (Select ClickId from @TmpResult)
			and [Date] between @MinDateClick and @CreatedDate
		
		----Update number deposit member in summary table
		Update cs		
		set TotalDeposit = 
				(Select COUNT(*) 
				from ClickStatistics1_bk ck with(nolock) 
				where ck.AffId = cs.AffId 
					and ck.[Date] = cs.[Date]
					and [status] = 2
					and DomainReferrer = cs.DomainReferrer
					and SportCode = cs.SportCode
					and LanguageCode = cs.LanguageCode)
		from ClickStatistics1Sum cs with (rowlock, updlock)
		where [Date] between @MinDateClick and @CreatedDate
	End
End

GO

GRANT EXECUTE ON [dbo].[Task_Aff_CustomerInsMember] TO [Dot_Member]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_CustomerInsMember] TO [vnteam]