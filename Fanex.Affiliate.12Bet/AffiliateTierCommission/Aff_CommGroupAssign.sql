ALTER PROC [dbo].[Aff_CommGroupAssign]  
	@UserId int,  
	@GroupId int,  
	@AffIDList nvarchar(4000),      
	@IP varchar(20),  
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT,  
	@RefNo bigint = null OUTPUT  
AS  
/*  
Created: 20090719@DungTong  
Task : Assign a commission group (GroupID<1000) for multiple Affilites   
DB: DB052.Affiliate_12Bet  
Original:  
  
Revisions:  
		- 20121207@Johnny: Update Casino Affiliate Joined Date if this GroupId has Casino
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID separated by semi colon.Maximum of 200 AffIDs are assiged each time                  
.@IP : IP of admin user               
.@ErrCode:    
              0 : no error raised  
              >0 : there was an error  
.@ErrMsg :     
              empty: no error raised  
              others : the error message detail                            
                            
*/  
SET NOCOUNT ON  
--Check permission  
/*EXEC [dbo].[Aff_Con_CheckPermission_xpre]  
 @custid=@UserID,@funcname='Affiliate',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output*/  
  
Declare @AffId int, @IsCasinoGroup bit, @CasinoId int
  
select @AffId = AffID  
from (select top 1 cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';')) tmp  
  
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
if(@ErrMsg<>'')  
  return  
  
if (@GroupID>1000 or  not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
   select @ErrCode=101,@ErrMsg='Invalid Group. Please check.'      
    return  
  end  
  
--Check AffIDList  
/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/  
declare @NoAff int  
BEGIN TRY  
    select @NoAff=sum(1)  
 from AffInfo with(nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';'))  
   and status='approved' -- and IsClosed=0  
      
 if(@NoAff<> (select sum(1) from dbo.strsplit(@AffIDList, ';')))  
 begin  
  select @ErrCode=102,@ErrMsg='Invalid Affiliate List. Please check.'      
  return  
 end   
  
ENd TRY  
BEGIN CATCH  
 select @ErrCode=103,@ErrMsg='Invalid Affiliate List. Please check.'      
    return  
END CATCH  

Select @IsCasinoGroup = 0--default is 0
		, @CasinoID = dbo.Aff_GetSportID('Casino')
if Exists(select 1 from GroupSetting nolock where GroupId = @GroupId and sporttype = @CasinoID)
	select @IsCasinoGroup = 1


--BEGIN TRANSACTION AFTER CHECKING VALID INPUT DATA  
BEGIN TRANSACTION    
  --Delete GroupID>1000 where GroupID in AffiliateID list and already assigned before  
  Delete DeductionSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 105  
     return   
   end  
     
  Delete GroupSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 106  
     return   
   end   
    
  Delete CommGroup     
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                       and AffID=GroupID  
    )   
        
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 103  
     return   
   end  
  
  Update AffInfo with (rowlock,updlock)  
  set GroupID=@GroupID        
  where AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ';'))         

	if(@IsCasinoGroup = 1)--Update CasinoJoinedDate if this group has casino setting
	Begin
		Update AffInfo with (rowlock,updlock)  
		set CasinoJoinedDate = convert(varchar(10), current_timestamp, 120)
		where AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ';'))         
			and CasinoJoinedDate is null
	End
		
     
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = N'There was an error when updating data.Please try again!', @ErrCode = 104  
     return   
   end  
          
commit transaction  
 --Write the log   
DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
if ((select count(1) from dbo.strsplit(@AffIDList, ';'))=1)  
  select @AffID=cast(@AffIDList as int)  
else  
  select @AffID=0     
SELECT @LogData = N'Assign a common commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
                  + '\n AffIDList=' + dbo.Aff_ToString(@AffIDList)     
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'CommissionGroup',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @RefNo = @RefNo OUTPUT,   
 @Details=@LogData

