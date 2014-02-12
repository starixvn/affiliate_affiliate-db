ALTER PROCEDURE [dbo].[Aff_CustomerInsMemberManually]	
	@AffUserName varchar(30),
	@Username varchar(30),	
	@DepositCustID varchar(50) = null,
	@FirstName nvarchar(50)= null,
	@LastName nvarchar(50)= null,
	@Currency varchar(6),	
	@Email nvarchar(50)= null,	
	@IBCCustID int,	
	@IBCUserName varchar(30)= null,
	@AgentID int,	
	@CreatedDate datetime = null,
	@RegisterDate datetime,
	@Btag varchar(100) = null,
	@ClickID bigint = null,
	@IP varchar(22),	
	@Language varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(2000) = '' OUTPUT	
AS
/*  
	Created: 20090724@VietHoang
	Task : Add new member existing in the system to Affiliate System
	DB: DB052.Affiliate_ZZun
*/ 
SET NOCOUNT ON
Declare @AffID int

Select @AffID=AffID
from AffInfo (nolock)
where username=@AffUserName

if(@AffID is null)
BEGIN
		 Select @ErrMsg = case @Language 
								when 'en-US' then 'Invalid Affiliate''s username!'
								when 'zh-CN' then N'無效的合作夥伴的使用者名稱!'
								when 'zh-TW' then N'无效的合作伙伴的使用者名称！'
								else N'Invalid Affiliate''s username!'
							end
			, @ErrCode=1001
     return
END

if (exists (Select 1 from MemberInfo(nolock) where UserName=@Username and IsRemoved!=1))
BEGIN
	 Select @ErrCode=1002
			, @ErrMsg = case @Language 
							when 'en-US' then 'User has been existed in the system!'
							when 'zh-CN' then N'使用者已經存在在這個系統中!'
							when 'zh-TW' then N'使用者已经存在在这个系统中！'
							else N'User has been existed in the system!'
						end
     return
END

Declare @CurrencyID int 

select @CurrencyID = ExchangeID from [CurrencyConverter] Where [PartnerCurrency] = @Currency

if (exists (Select 1 from MemberInfo(nolock) where UserName=@Username and IsRemoved=1))
BEGIN
	 UPDATE [dbo].[MemberInfo]
   SET [AffID] = @AffID      
      ,[RegisteredDate] = @RegisterDate
      ,[CreatedDate]=@CreatedDate
      ,[DepositCustID] = @DepositCustID
      ,[Currency] = @CurrencyID
      ,[FirstName] = @FirstName
      ,[LastName] = @LastName
      ,[Email] = @Email
      ,[IsRemoved] = 0
      ,[IBCCustID] = @IBCCustID
      ,[IBCUserName] = @IBCUserName
      ,Recommend = @AgentID
      ,Btag = @Btag
      ,ClickID = @ClickID    
	WHERE UserName = @Username
	
	Delete from dbo.MemberRemoval Where UserName = @Username

END
ELSE
BEGIN
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
		CreatedDate,
		IBCCustID,	
		IBCUserName,
		Recommend,
		Btag,
		ClickID
	)
	VALUES( 
		@AffID,
		@UserName,
		0, 
		@DepositCustID,
		@FirstName,
		@LastName,
		@CurrencyID,
		@Email,
		@RegisterDate,
		@CreatedDate,		
		@IBCCustID,	
		@IBCUserName,
		@AgentID,
		@Btag,
		@ClickID
	)
END

Declare @LogData nvarchar(4000), @SPName varchar(100) 
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Insert new member. UserName=' + dbo.Aff_ToString(@UserName)                 
                  + '.PlayerCustID=' + dbo.Aff_ToString(@DepositCustID)
                  + '.FirstName=' + dbo.Aff_ToString(@FirstName)
                  + '.LastName=' + dbo.Aff_ToString(@LastName)
                  + '.Currency=' + dbo.Aff_ToString(@Currency)                  
                  + '.Email=' + dbo.Aff_ToString(@Email)
				  + '.RegisteredDate=' + dbo.Aff_ToString(@RegisterDate)
				  + '.CreatedDate=' + dbo.Aff_ToString(@CreatedDate)
                  + '.IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
                  + '.IBCUserName=' + dbo.Aff_ToString(@IBCUserName)
                  + '.Recommend=' + dbo.Aff_ToString(@AgentID)
                  + '.Btag=' + dbo.Aff_ToString(@Btag)
                  + '.ClickID=' + dbo.Aff_ToString(@ClickID)
EXEC [dbo].[Aff_WriteLog]
	@Creator=@AffID,	
	@AffID=@AffID,
	@Typename= 'Member',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData


GRANT EXECUTE ON [dbo].[Aff_CustomerInsMemberManually] TO [bodbadminNet]


GRANT EXECUTE ON [dbo].[Aff_CustomerInsMemberManually] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerInsMemberManually] TO [vnteam]