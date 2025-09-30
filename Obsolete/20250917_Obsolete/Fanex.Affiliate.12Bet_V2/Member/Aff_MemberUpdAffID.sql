  ALTER PROCEDURE [dbo].[Aff_MemberUpdAffID]
	@IBCCustID int,	
	@NewAffId int,		
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20090910@Peter
Task : Update AffiliateID for a member
DB: DB02.bodb02
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
 begin try
  update CustInfo with (rowlock,updlock)
  Set AffiliateID=@NewAffId
  where CustID=@IBCCustID 
  --Write log on the sp Aff_MemberDel
 end try
 begin catch		
		SELECT @ErrMsg ='Update AffiliateID failed!', @ErrCode = 1002  
		return
 end catch 
end
GO
GRANT EXECUTE ON [dbo].[Aff_MemberUpdAffID] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberUpdAffID] TO [vnteam]
GO