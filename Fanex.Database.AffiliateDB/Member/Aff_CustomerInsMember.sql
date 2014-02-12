ALTER PROCEDURE [dbo].[Aff_CustomerInsMember]	
	@Ref varchar(50),
	@Username varchar(30),	
	@DepositCustID varchar(50),
	@FirstName nvarchar(50),
	@LastName nvarchar(50),
	@Currency int,	
	@Email nvarchar(50),	
	@IP varchar(22),	
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT	
AS
/*  
	Created: 20090724@VietHoang
	Task : Add new member when customer is first registered
	DB: DB052.Affiliate_ZZun
*/ 
SET NOCOUNT ON
Declare @AffID int,@TrackingID uniqueidentifier
begin try
  Set @TrackingID=(Select cast (val as uniqueidentifier) 
					from dbo.strsplit(@Ref, '_')
					where rank=1
					) 
  Set @AffID=(Select cast (val as int) 
					from dbo.strsplit(@Ref, '_')
					where rank=2
					) 					
end try

begin catch
     Select @ErrCode=1001,@ErrMsg=N'Invalid Ref tracking code !!!'
     return
end catch

if (exists (Select 1 from MemberInfo(nolock) where UserName=@Username))
BEGIN
	 Select @ErrCode=1002,
			@ErrMsg = case @Language 
							when 'en-US' then 'User has been existed in the system!'
							when 'zh-CN' then N'使用者已經存在在這個系統中!'
							when 'zh-TW' then N'使用者已经存在在这个系统中！'
							else N'User has been existed in the system!'
						end
     return
END
Declare @RegisteredDate datetime
set @RegisteredDate=current_timestamp

INSERT INTO MemberInfo (	
	AffID,
	UserName,		
	IsRemoved,
	DepositCustID,
	FirstName,
	LastName,
	Currency,	
	Email,
	RegisteredDate,
	TrackingID
)
VALUES (	
	@AffID,
	@UserName,
	0, 
	@DepositCustID,
	@FirstName,
	@LastName,
	@Currency,	
	@Email,
	@RegisteredDate,
	@TrackingID
)

Declare @LogData nvarchar(4000), @SPName varchar(100) 
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Insert new member. UserName=' + dbo.Aff_ToString(@UserName)                 
                  + '.PlayerCustID=' + dbo.Aff_ToString(@DepositCustID)
                  + '.FirstName=' + dbo.Aff_ToString(@FirstName)
                  + '.LastName=' + dbo.Aff_ToString(@LastName)
                  + '.Currency=' + dbo.Aff_ToString(@Currency)                  
                  + '.Email=' + dbo.Aff_ToString(@Email)
				  + '.RegisteredDate=' + dbo.Aff_ToString(@RegisteredDate)
                  + '.Ref=' + dbo.Aff_ToString(@Ref)
EXEC [dbo].[Aff_WriteLog]
	@Creator=@AffID,	
	@AffID=@AffID,
	@Typename= 'Member',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData	
GO

GRANT EXECUTE ON [dbo].[Aff_CustomerInsMember] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerInsMember] TO [vnteam]