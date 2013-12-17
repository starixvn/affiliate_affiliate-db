ALTER PROCEDURE [dbo].[Aff_CustomerInsMember]
	@IbcCustID int,
	@AffID int,
	@Username varchar(30),
	@IBCUsername varchar(30),
	@DepositCustID int,
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Currency int,
	@Recommend int,
	@Email nvarchar(50)
AS
/*  
	Created: 20090724@VietHoang
	Task : Add new member when customer is first deposit
	DB: DB052.Affiliate_12BET
	Revisions:    
		- 20120110@Johnny: Update click Status when member deposit money at 1st time
		- 20120409@Johnny: Make local test version is the same as live version
*/ 
SET NOCOUNT ON

declare @RegisteredDate datetime, @ClickId bigint
select @RegisteredDate=creatdate, @ClickId = ClickId
from [DBDeposit].deposit_db.dbo.Deposit_Customer with (nolock)
where custid=@DepositCustID

INSERT INTO MemberInfo (
	IBCCustID,
	AffID,
	UserName,
	IBCUserName,
	CreatedDate,
	IsRemoved,
	DepositCustID,
	FirstName,
	LastName,
	Currency,
	Recommend,
	Email,
	RegisteredDate,
	ClickId
)
VALUES (
	@IBCCustID,
	@AffID,
	@UserName,
	@IBCUserName,
	CURRENT_TIMESTAMP,
	0, --IsRemoved
	@DepositCustID,
	@FirstName,
	@LastName,
	@Currency,
	@Recommend,
	@Email,
	@RegisteredDate,
	@ClickId
)

if (@ClickId is not null)--Update click status for FDM click
Begin
	if exists(select 1 from ClickStatistics1 where ClickId = @ClickId and AffId = @AffID)
	Begin
		Update ClickStatistics1 with (rowlock, updlock)
		set [status] = 2
		where ClickId = @ClickId
	End
	Else 
	Begin--update click status in bk and update sum
		Declare @DateClick smalldatetime
		select @DateClick = (select [Date] from ClickStatistics1_bk where ClickId = @ClickId and AffId = @AffID)
		if(@DateClick is not null)
		Begin
			Update ClickStatistics1_bk with (rowlock, updlock)
			set [status] = 2
			where ClickId = @ClickId


			Update cs		
			set TotalDeposit = 
					(Select COUNT(*) 
					from ClickStatistics1_bk ck with(nolock) 
					where ck.AffId = @AffID
						and [Date] = @DateClick 
						and [status] = 2
						and DomainReferrer = cs.DomainReferrer
						and SportCode = cs.SportCode
						and LanguageCode = cs.LanguageCode)
			from ClickStatistics1Sum cs with (rowlock, updlock)
			where [DATE] = @DateClick and AffId = @AffID

			/*
			Update ClickStatistics1Sum with (rowlock, updlock)
			set TotalDeposit = TotalDeposit + 1
			where [DATE] = @DateClick and AffId = @AffID*/
		End
	End
End


Declare @LogData nvarchar(4000), @SPName varchar(100) 
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Insert new member. IBCCustid =' + dbo.Aff_ToString(@IbcCustID) 
				  + '.UserName=' + dbo.Aff_ToString(@UserName)
				  + '.IBCUserName=' + dbo.Aff_ToString(@IBCUserName)
				  + '.DepositCustID=' + dbo.Aff_ToString(@DepositCustID)
				  + '.FirstName=' + dbo.Aff_ToString(@FirstName)
				  + '.LastName=' + dbo.Aff_ToString(@LastName)
				  + '.Currency=' + dbo.Aff_ToString(@Currency)
				  + '.Recommend=' + dbo.Aff_ToString(@Recommend)
				  + '.Email=' + dbo.Aff_ToString(@Email)
				 + '.RegisteredDate=' + dbo.Aff_ToString(@RegisteredDate)
				 + '.ClickId=' + dbo.Aff_ToString(@ClickId)
EXEC [dbo].[Aff_WriteLog]
	@Creator=@AffID,	
	@AffID=@AffID,
	@Typename= 'Member',	
	@SPName=@SPName,
	@IP ='127.0.0.1',
	@Details=@LogData	
GO

GRANT EXECUTE ON [dbo].[Aff_CustomerInsMember] TO [Dot_Member]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerInsMember] TO [vnteam]