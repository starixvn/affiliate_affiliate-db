ALTER PROCEDURE [dbo].[Aff_CustomerInsMember_Temp]
	@IbcCustID int,
	@AffID int,
	@Username varchar(30),
	@IBCUsername varchar(30),
	@DepositCustID int,
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Currency int,
	@Recommend int,
	@Email nvarchar(50),
	@RegisteredDate datetime
AS
/*  
	Created: 20090724@Peter
	Task : ImportMissingMembersManually
	DB: DB052.Affiliate_12BET
	Revisions:    
		
*/ 
SET NOCOUNT ON


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
	0
)

Declare @LogData nvarchar(4000), @SPName varchar(100) 
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Insert new member manually (Request by Izhar). IBCCustid =' + dbo.Aff_ToString(@IbcCustID) 
				  + '.UserName=' + dbo.Aff_ToString(@UserName)
				  + '.IBCUserName=' + dbo.Aff_ToString(@IBCUserName)
				  + '.DepositCustID=' + dbo.Aff_ToString(@DepositCustID)
				  + '.FirstName=' + dbo.Aff_ToString(@FirstName)
				  + '.LastName=' + dbo.Aff_ToString(@LastName)
				  + '.Currency=' + dbo.Aff_ToString(@Currency)
				  + '.Recommend=' + dbo.Aff_ToString(@Recommend)
				  + '.Email=' + dbo.Aff_ToString(@Email)
				 + '.RegisteredDate=' + dbo.Aff_ToString(@RegisteredDate)
				 + '.ClickId=' + dbo.Aff_ToString(0)
EXEC [dbo].[Aff_WriteLog]
	@Creator=@AffID,	
	@AffID=@AffID,
	@Typename= 'Member',	
	@SPName=@SPName,
	@IP ='127.0.0.1',
	@Details=@LogData	
GO


GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerInsMember_Temp] TO [vnteam]