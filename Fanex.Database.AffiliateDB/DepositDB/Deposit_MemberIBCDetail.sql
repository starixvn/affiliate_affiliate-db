--DB: DB052.Affiliate_ZZun for Testing
ALTER PROCEDURE [dbo].[Deposit_MemberIBCDetail]
	@DepUserName varchar(50), 
	@IBCCustid int, 
	@IBCUserName varchar(30), 
	@ErrorCode int output,  
	@ErrorMsg varchar(30) output
AS
	Declare @DepCustId int 
	Declare @UserCnt int
	Declare @prIBCUserName varchar(30) 
	Declare @prIBCCustID int
	Declare @DepActStatus int  
	
	Select @DepCustId = 0
	Select @UserCnt = 0 
	Select @prIBCUserName = ''
	Select @prIBCCustID = 0
	Select @DepActStatus = 0   
    --Check User name in Deposit Customer DB 
    if not exists (Select *  from Deposit_Customer (nolock) where username = @DepUserName)
		begin 
			Select @ErrorCode = 101, @ErrorMsg = 'User not find'
			--No se ha encontrado el usuario
		end 
	else 
		begin 
			-- Get deposit User ID 
			Select @DepCustId = custid  from Deposit_Customer (nolock) where username = @DepUserName
			--Check User 
			Select @DepActStatus = ActStatus, @prIBCUserName = isnull(IBCusername,'') , @prIBCCustID = isnull(IBCCustID,0)  from Deposit_Customer(nolock) where Custid = @DepCustId

			if (@DepActStatus = 2 or @prIBCUserName <> '' or @prIBCCustID <> 0) 
				begin 
					Select @ErrorCode = 102, @ErrorMsg = 'User already have account'
					--El usuario ya dispone de una cuenta de IBC
				end  
			else
				begin
					--Update Deposit Customer info 
					update deposit_customer set IBCusername = @IBCUserName , IBCCustID = @IBCCustid , ActStatus = 2 , LastModifyDate = getdate() where Custid = @DepCustId

					-- Write Log 
					--exec Deposit_WriteUserLog(0,'Update member IBC data from systme','',0)
					Select @ErrorCode = 0, @ErrorMsg = ''
				end 

		end 	


GO
GRANT EXECUTE ON [dbo].[Deposit_MemberIBCDetail] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Deposit_MemberIBCDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Deposit_MemberIBCDetail] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Deposit_MemberIBCDetail] TO [vnTeam]
GO