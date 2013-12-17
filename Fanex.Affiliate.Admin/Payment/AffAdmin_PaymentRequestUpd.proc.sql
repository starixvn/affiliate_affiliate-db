ALTER PROCEDURE [dbo].[AffAdmin_PaymentRequestUpd]
	@TransID bigint,   
	@Status nvarchar(50),  
	@AdminDesc nvarchar(300) = null,  
	@AffDesc nvarchar(300) = null,  
	@PreferredLanguage varchar(20)='en-US' OUTPUT,  
	@MailOption bit = 0 OUTPUT,  
	@UserID int,   
	@IP varchar(15) = '',  
	@RefNo bigint=0,
	@IbcRefNo bigint = 0,  
	@IbcTransId bigint = 0,  
	@IBCUsername varchar(50) = '',  
	@ErrCode int = 0 OUTPUT
AS  
-- DB: DB052.Affiliate_MYM  
/*  
Creator : Peter@20090910  
Task : Update Payment status ('Approved','Rejected','Cancelled')  
  
Input   
    1) @AffId (For Double check)   
    2) @RefID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )  
    3) @Status Status of transaction  
    3) @AdminDesc Description for this payment from Admin  
    4) @AffDesc Description visible for Affiliate  
    5) @userid ID of Admin update this payment  
    6) @IP IP update payment  
     
Revisions:  
	- Johnny@20131126: Update field BF in table AffInfo
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
• @ErrMsg: Error description.  
*/  
  
  
--Check whether this is pending payment request   
SET NOCOUNT ON  
Declare @AffID int, @RefID bigint , @TransType int  
Select @TransType = 202  
Select @AffID=AffID,@RefID=RefID  
from AffTrans (nolock)  
where TransID=@TransID and TransType= @TransType and Status='pending'  
  
if(@AffID is null or @RefID is null)  
BEGIN  
           Select @ErrCode = 1  
 return  
END  
  
/*Check Condition to excute this sp  
  + From Affiliate Site : @UserID=@AffID and  @Status='Cancelled'  
  + From AffAdmin Site: @UserID<> @AffID and Status in ('Approved','Rejected')   
*/  
if( @UserID<>@AffID)  
BEGIN  
 --Check permission-----------------------------  
 EXEC [dbo].[Aff_Con_CheckPermission]  
  @custid=@UserID,@funcname='[Payment]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output
 If @ErrCode <> 0  
  RETURN  
     if(@Status not in ('Approved','Rejected'))  
  BEGIN  
       Select @ErrCode = 2  
   return  
  END  
END  
  
if(@UserID=@AffID and  @Status<>'Cancelled')  
BEGIN  
           Select @ErrCode = 2  
 return  
END  
  
  
  
BEGIN TRANSACTION  
BEGIN TRY  
    declare @CompletedDate datetime  
     Select @PreferredLanguage=PreferredLanguage  
   , @MailOption = MailOption  
     from AffDetail (nolock)  
     where AffID=@AffID   
       
    Select @CompletedDate=current_timestamp  
    Update  AffPayout with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        AdminDesc=isnull(@AdminDesc,AdminDesc),  
        AffDesc=isnull(@AffDesc,AffDesc),  
	  IbcRefNo = @IbcRefNo,  
	  IbcTransId = @IbcTransId
	  ,IBCUsername = (case when isnull(IBCUsername, '') = '' then @IBCUsername else IBCUsername end)  
    where RefID=@RefID and AffID=@AffID  
      
    Update  AffTrans with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        Creator=@UserID  
    where TransID=@TransID and AffID=@AffID   
	
	-- Recalculate BF in AffInfo table  
	update AffInfo with (rowlock,updlock)  
	Set BF=dbo.Aff_GetAffBalance (AffID)  
	where AffID=@AffID      
END TRY  
  
BEGIN CATCH  
 rollback transaction   
    Select @ErrCode = 3  
 return  
    RETURN  
END CATCH  
  
COMMIT TRANSACTION   
  
  
declare @SPName varchar(50), @LogData nvarchar(4000)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
Select @LogData =  'Update status for payout Request. TransID = ' + dbo.Aff_ToString(@TransID) + '. Status = ' + dbo.Aff_ToString(@Status)  
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserID,   
 @AffID=@AffID,  
 @Typename= 'Payout',   
 @SPName=@SPName ,  
 @RefNo=@RefNo,  
 @IP =@IP,  
 @Details=@LogData

 GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequestUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_PaymentRequestUpd] TO [vnteam]