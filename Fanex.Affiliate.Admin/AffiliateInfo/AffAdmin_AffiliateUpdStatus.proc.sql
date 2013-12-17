CREATE PROCEDURE [dbo].[AffAdmin_AffiliateUpdStatus]  
 @AffID int,  
 @UserID int,  
 @Status varchar(30),   
 @Password varchar(40)= NULL,    
 @GroupID int=NULL,   
 @IP varchar(20),   
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT
AS  
/*Created: 20090825@Peter  
Task : Update affiliate status from disapproved->pending , disapproved-> approved,pending-->disapproved,pending-->approved  
DB: DB052.Affiliate_ZZun  
Original : [Aff_CustomerUpdStatus]  
Revisions:  
  Long@20130911: do not check email existance in case of Kiosk
Param's Explanation:  
• @AffID : Affiliate ID  
• @userid : User update  
• @Status : Update status  
• @Password: Make a password for affiliate when approving  
• @GroupID: when approving user need to assign a new grooup  
            groupid<1000 : a common group  
            groupid>1000: a private group for this affiliate must be created before. This sp will be called from sp Aff_CommGroupIns  
                 
• @ErrCode  
• @ErrMsg  
*/  
SET NOCOUNT ON  
--Check permission-----------------------------  
EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output
   
If @ErrCode <> 0  
 RETURN  
  
IF (select at.Name
	from afftype at with(nolock), affinfo ai with(nolock)
	where ai.AffType = at.TypeID and ai.AffID = @AffId) not like '%kiosk%'
BEGIN 
	Declare @Email nvarchar(50)  
	  
	select @Email = Email from AffInfo with (nolock) where affid=@affid  
	  
	if( Exists(select 1 from AffInfo with (nolock) where affid<>@affid and Email = @Email and Status in ('approved','pending')) and @Status in ('approved','pending'))  
	Begin  
	 SELECT @ErrCode = 15  
	 return  
	End  
END
  
  
if(not exists(select 1 from AffInfo with (nolock) where affid=@affid))  
begin  
 SELECT @ErrCode = 1006  
   return  
end  
-----------------------------------------------  
if(@Status not in ('approved','disapproved','pending'))  
begin   
 SELECT @ErrCode = 1007  
  return  
end  
  
  
if @Status= 'approved' --from disapproved,pending-->approved  
 Begin  
  IF Exists(Select 1  
                  From AffInfo ai with(nolock)   
                  where ai.email=(select email from AffInfo with (nolock) where affid=@affid)  
                        and ai.affid <> @affid and lower(ai.Status)='approved')  
  BEGIN  
   SELECT @ErrCode = 15  
   return  
  END   
    if(not exists(select 1 from CommGroup with (nolock) where groupid=@groupid and IsDeleted=0))  
  BEGIN  
   SELECT @ErrCode = 1008  
   return  
  END    
  --Check Currency is valid  
  declare @Currency varchar(5)  
  Select @Currency =currency  
  from AffINfo (nolock)  
  where AffID=@AffID  
  
  
  if(not exists (Select 1 from CommGroup with (nolock) where groupid=@groupid and Currency=@Currency) )  
  begin  
   SELECT @ErrCode = 1009  
   return  
  end  
End  
  
Declare @GroupName nvarchar(100)  
  
Select @GroupName = GroupName from commgroup nolock where GroupId = @GroupID  
  
BEGIN TRANSACTION   
UPDATE AffInfo with(rowlock,updlock)   
SET [Password] = isnull(@Password,[Password]),  
 [Status]=@Status,  
 GroupID=isnull(@GroupID,GroupID),  
 ApprovedDate=(case when @Status in ('approved','disapproved') then current_timestamp else null end),  
 AffType = (case when @GroupName = 'Media' then 2 else AffType end)  
WHERE affid = @affid  
IF @@Error <> 0   
begin  
 SELECT @ErrCode = 1010  
 ROLLBACK TRANSACTION  
 return  
end  
  
COMMIT TRANSACTION  
  
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
  
SELECT @LogData = 'Update Affiliate''s Status. '  
                  + 'Status=' + dbo.Aff_ToString(@Status)  
                  + '. Password=' + dbo.Aff_ToString(@Password)  
                  + '. GroupID=' + dbo.Aff_ToString(@GroupID)    
select @SPName=OBJECT_NAME(@@ProcID)  
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData    
  




