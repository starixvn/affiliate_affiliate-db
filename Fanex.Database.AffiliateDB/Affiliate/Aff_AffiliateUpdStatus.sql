/****** Object:  StoredProcedure [dbo].[Aff_AffiliateUpdStatus]    Script Date: 09/13/2013 04:25:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 ALTER PROCEDURE [dbo].[Aff_AffiliateUpdStatus]  
 @AffID int,  
 @UserID int,  
 @Status varchar(30),   
 @Password varchar(40)= NULL,    
 @GroupID int=NULL,   
 @IP varchar(20),   
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*Created: 20090825@Peter  
Task : Update affiliate status from disapproved->pending , disapproved-> approved,pending-->disapproved,pending-->approved  
DB: DB052.Affiliate_ZZun  
Original : [Aff_CustomerUpdStatus]  
Revisions:  
 Long: 20130913: do not check email existance in case of Kiosk
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
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
  
declare @AffType varchar(10)
select @AffType=at.Name
 from afftype at with(nolock)
    inner join affinfo ai with(nolock) on ai.AffType = at.TypeID
 where ai.AffID = 10112  
  
IF @AffType not like '%kiosk%'
BEGIN 
 Declare @Email nvarchar(50)  
   
 select @Email = Email from AffInfo with (nolock) where affid=@affid  
   
 if( Exists(select 1 from AffInfo with (nolock) where affid<>@affid and Email = @Email and Status in ('approved','pending')) and @Status in ('approved','pending'))  
 Begin  
  SELECT @ErrMsg = case @Language 
        when 'en-US' then 'Email Address has been used. Please choose another one!'
        when 'zh-CN' then N'電子郵件地址已經被使用.請選擇另一個!'
        when 'zh-TW' then N'电子邮件地址已经被使用，请选择另一个！'
        else N'Email Address has been used. Please choose another one!'
       end
     , @ErrCode = 1007  
  return  
 End  
END
  
  
if(not exists(select 1 from AffInfo with (nolock) where affid=@affid))  
begin  
 SELECT @ErrMsg = case @Language 
       when 'en-US' then 'Invalid Affiliate!'
       when 'zh-CN' then N'無效的工作夥伴!'
       when 'zh-TW' then N'无效的工作伙伴！'
       else N'Invalid Affiliate!'
      end, @ErrCode = 1005  
   return  
end  
-----------------------------------------------  
if(@Status not in ('approved','disapproved','pending'))  
begin   
 SELECT @ErrMsg = case @Language 
       when 'en-US' then 'Invalid status!'
       when 'zh-CN' then N'無效的狀態!'
       when 'zh-TW' then N'无效的状态！'
       else N'Invalid Affiliate!'
      end, @ErrCode = 1006  
  return  
end  
  
  
if @Status= 'approved' --from disapproved,pending-->approved  
 Begin  
  IF @AffType not like '%kiosk%' and Exists(Select 1  
                  From AffInfo ai with(nolock)   
                  where ai.email=(select email from AffInfo with (nolock) where affid=@affid)  
                        and ai.affid <> @affid and lower(ai.Status)='approved')  
  BEGIN  
   SELECT @ErrMsg = case @Language 
       when 'en-US' then 'Email Address has been used. Please choose another one!'
       when 'zh-CN' then N'電子郵件地址已經被使用.請選擇另一個!'
       when 'zh-TW' then N'电子邮件地址已经被使用，请选择另一个！'
       else N'Email Address has been used. Please choose another one!'
      end, @ErrCode = 1007  
   return  
  END   
    if(not exists(select 1 from CommGroup with (nolock) where groupid=@groupid and IsDeleted=0))  
  BEGIN  
   SELECT @ErrMsg = case @Language 
       when 'en-US' then 'Invalid group!'
       when 'zh-CN' then N'無效的群組!'
       when 'zh-TW' then N'无效的群组！'
       else N'Invalid group!'
      end
   , @ErrCode = 1008  
   return  
  END    
  --Check Currency is valid  
  declare @Currency varchar(5)  
  Select @Currency =currency  
  from AffINfo (nolock)  
  where AffID=@AffID  
  
  
  if(not exists (Select 1 from CommGroup with (nolock) where groupid=@groupid and Currency=@Currency) )  
  begin  
   SELECT @ErrMsg = case @Language 
       when 'en-US' then 'Currency does not match with the selected group. Please check!'
       when 'zh-CN' then N'貨幣和所選擇的群組不相配.請確認!'
       when 'zh-TW' then N'货币和所选择的群组不相配。请确认！'
       else N'Currency does not match with the selected group. Please check!'
      end
   , @ErrCode = 1009  
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
 SELECT @ErrMsg = case @Language 
       when 'en-US' then 'There was an error when updating data.'
       when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
       when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
       else N'There was an error when updating data.'
      end
  , @ErrCode = 1008  
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
  


GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdStatus] TO [vnteam] AS [dbo]