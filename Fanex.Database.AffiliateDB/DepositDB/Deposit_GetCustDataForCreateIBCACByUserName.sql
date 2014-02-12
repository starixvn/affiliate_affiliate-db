--DB: DB052.Affiliate_ZZun for Testing
ALTER PROCEDURE [dbo].[Deposit_GetCustDataForCreateIBCACByUserName]
	@deposit_username varchar(30)  
AS
SET NOCOUNT ON
DECLARE @Success int 
DECLARE @FirstName nvarchar(50) 
DECLARE @LastName nvarchar(50) 
DECLARE @Email nvarchar(50) 
DECLARE @DepositUserName varchar(50) 
DECLARE @Password varchar(40)
DECLARE @OddsType varchar(5)
DECLARE @AgentID int
DECLARE @Currency int
DECLARE	@AffiliateId int 
DECLARE	@AgentType int
-- below for PT create accout used 
Declare @address nvarchar(200)
Declare @City nvarchar(50)
Declare @birthday smalldatetime 
Declare @country nvarchar(50)
Declare @phone varchar(50)
Declare @gender tinyint
Declare @state nvarchar(50)
Declare @ZipCode nvarchar(50)
--Declare @CasinoFlag tinyint 
Declare @BonusCode varchar(50)
Declare @DepositUserId int 
 
select @Success=0
select @FirstName='' 
select @LastName='' 
select @Email='' 
select @DepositUserName='' 
select @Password=''
select @OddsType=''
select @AgentID=''
select @Currency=''
select @AffiliateId = 0 
select @AgentType = 0
select @address= ''
select @City = ''
select @birthday = ''
select @country = ''
select @phone = ''
select @gender = 1
select @state= ''
select @ZipCode = ''
--select @CasinoFlag = 0 
Select @BonusCode = ''
select @DepositUserId = 0

	if not exists(select 1 from Deposit_Customer with (NOLOCK) where username=@deposit_username) 
		BEGIN
			Select @Success = 1 
		END
	if @@ERROR > 0 
		BEGIN 
			Select @Success = @@ERROR
		End 
	if (@Success = 0) 
	Begin 
		Select @DepositUserId = isnull(custid,0) from Deposit_Customer with (NOLOCK) where username=@deposit_username
		if (@DepositUserId <> 0) 
		begin 
				Select	@FirstName = firstname , 
							@LastName = lastname , 
							@Email = email, 
							@DepositUserName = username ,
							@Password = userpwd,
							@Currency = currency, 
							@OddsType = OddsType,
							@AffiliateId = AffiliateID,
							@address= address,
							@City = city,
							@birthday = birthday,
							@country = country,
							@phone = phone,
							@gender = gender,
							@state= state,
							@AgentID = IBCAgentID,
							@ZipCode = ZipCode,
							--@CasinoFlag = isnull(CasinoFlag,0),
							@BonusCode = isnull(BonusCode,'') 
					from Deposit_Customer with(NOLOCK) 
					where custid = @DepositUserId 
				if (@AffiliateId > 0 )
					Begin 
						select @AgentType = 1	
					end  
				
				if (@OddsType = 'de')
					begin 
						select @OddsType = 'hka'
					end 
    			if @@ERROR > 0 
				BEGIN 
					Select @Success = @@ERROR
				End 
		end
		else 
		begin 
			Select @Success = 1
		end  
	End 
select Success = @Success,
      FirstName = @FirstName ,
			LastName = @LastName ,
			Email = @Email ,
			DepositUserName = @DepositUserName,	
			Password = @Password ,	
			OddsType = @OddsType,
			AgentID = @AgentID,
			Currency = @Currency,
			AffiliateId = @AffiliateId,
			address = @address,
			city = @City,
			birthday = @birthday ,
			country = @country,
			phone = @phone,
			gender = @gender,
			state = @state,
			ZipCode = @ZipCode,
			--CasinoFlag = @CasinoFlag,
			BonusCode = @BonusCode,
			DepositUserId =  @DepositUserId



GO
GRANT EXECUTE ON [dbo].[Deposit_GetCustDataForCreateIBCACByUserName] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Deposit_GetCustDataForCreateIBCACByUserName] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Deposit_GetCustDataForCreateIBCACByUserName] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Deposit_GetCustDataForCreateIBCACByUserName] TO [vnTeam]
GO