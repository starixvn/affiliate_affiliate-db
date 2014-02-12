   ALTER PROCEDURE [dbo].[Aff_MemberUpdIBCInfo]
	@UserName varchar(30),
	@IBCCustID int,	
	@IBCUserName varchar(30),
	@AgentID int,	
	@IP varchar(22),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20090910@Peter
Task : Update IBC Info for a member when member first transfer/deposit and inserted to IBC DB
DB: DB05.Affiliate_ZZun
Original: 

Revisions:

Param's Explanation:
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.
• @ErrMsg: Error description.
Write Log on the website
*/
begin
 SET NOCOUNT ON
 if (not exists (Select 1 from MemberInfo(nolock) where UserName=@Username))
  BEGIN
	 Select @ErrCode=1001,@ErrMsg=N'User does not exist in the system!!!'
     return
  END

Declare @CreatedDate datetime
set @CreatedDate=current_timestamp

 begin try
  update MemberInfo with (rowlock,updlock)
  Set IBCCustID=@IBCCustID,
	  IBCUserName=@IBCUserName,
	  Recommend=@AgentID,
	  CreatedDate=@CreatedDate
  where UserName=@UserName
  
 end try
 begin catch		
        SELECT @ErrMsg ='Update failed!', @ErrCode = 1002  
        return
 end catch 
end

Declare @LogData nvarchar(max), @SPName varchar(100) 
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Update Info member. UserName=' + dbo.Aff_ToString(@UserName)                 
                  + '.IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
                  + '.IBCUserName=' + dbo.Aff_ToString(@IBCUserName)
                  + '.AgentID=' + dbo.Aff_ToString(@AgentID)
                  + '.CreatedDate=' + dbo.Aff_ToString(@CreatedDate)                  
                  
EXEC [dbo].[Aff_WriteLog]
	@Creator=8,	
	@AffID=0,
	@Typename= 'Member',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData	
	
GO
GRANT EXECUTE ON [dbo].[Aff_MemberUpdIBCInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberUpdIBCInfo] TO [vnteam]
GO