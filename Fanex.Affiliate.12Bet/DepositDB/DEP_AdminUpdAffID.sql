ALTER PROCEDURE [dbo].[DEP_AdminUpdAffID]
	@DepositCustID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
begin
/*
Created: 20090910@Peter
Task : Remove a member  from Affiliate
DB: [DBDeposit].Deposit_DB
Original: 

Revisions:

Param's Explanation:

@ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.
@ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check DepositCustID
if(not exists (select top(1) 1 from Deposit_Customer with (nolock) where CustID=@DepositCustID and isnull(AffiliateID,0)>0))
begin
	SELECT @ErrMsg ='This member does not exist in Affiliate System or be removed before!', @ErrCode = 1001
	RETURN
end


 begin try

  update Deposit_Customer with (rowlock,updlock)
  set AffiliateID = 0,
	  LastModifyDate=current_timestamp
  where CustID=@DepositCustID
  
 end try
 begin catch
		
		SELECT @ErrMsg ='Remove member failed!', @ErrCode = 1002  
		return
 end catch 

end 

GO
GRANT EXECUTE ON [dbo].[DEP_AdminUpdAffID] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_AdminUpdAffID] TO [vnTeam]
GO