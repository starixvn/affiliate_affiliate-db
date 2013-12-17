ALTER Procedure [dbo].[AffAdmin_AffiliateUnlock]  
	@UserId int,   
	@AffId int,      
	@Ip varchar(20),  
	@ErrCode int = 0 OUTPUT 
AS  
/*  
Created: 20131112@JohnnyTrinh
Task : Unlock affiliate
DB: DB052.Affiliate_AoncashUAT
Original:  
  
Revisions:  
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@@AffID: AffID   
.@IP : IP of admin user               
.@ErrCode:    
              0 : no error raised  
              >0 : there was an error                             
                            
*/  
SET NOCOUNT ON  
--Check permission  
EXEC [dbo].[Aff_Con_CheckPermission]  
	@custid=@UserID,
	@funcname='[Affiliate]',  
	@System = 'AFFILIATE',  
	@ErrCode=@ErrCode output
   
if(@ErrCode<>0)  
	return  
  
  
--Check AffIDList  
/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/  
declare @NoAff int  
  
update AffInfo with (rowlock,updlock)  
set IsLocked=0 
where AffID = @AffID
  
UPDATE AffDetail with (rowlock, updlock)  
SET logincount = 0  
WHERE AffID = @AffID  
  
 --Write the log   
DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
    
SELECT @LogData = N'Unlock Affiliate.AffID=' + dbo.Aff_ToString(@AffID)
  
select @SPName=OBJECT_NAME(@@ProcID)  

EXEC [dbo].[Aff_WriteLog]  
		@Creator=@UserId,   
		@AffID=@AffID,  
		@Typename= 'Affiliate',   
		@SPName=@SPName,  
		@IP=@IP,  
		@Details=@LogData  

GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUnlock] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateUnlock] TO [vnteam]