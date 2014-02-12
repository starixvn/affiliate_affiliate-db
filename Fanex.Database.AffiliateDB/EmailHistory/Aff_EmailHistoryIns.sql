ALTER PROCEDURE [dbo].[Aff_EmailHistoryIns]  
 @MID int OUTPUT,  
 @creator int=-1,  
 @content nvarchar(4000),  
 @sender nvarchar(100),  
 @affiliate varchar(30)=null,  
 @email nvarchar(50),  
 @subject nvarchar(2000),  
 @ip nvarchar(15),  
 @browser nvarchar(100),  
 @sessionid nvarchar(100),  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
begin  
/*  
Created: 20090626@VinhTrinh  
Task : Insert new email for EmailHistory  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
  
  
Param's Explanation:  
.@MID: OUTPUT of mail id,  
.@creator : id of customer sent this email  
.@content: content of this email,  
.@sender: sender name,  
.@affiliate: name of affiliate in the system,  
.@email: email of sender,  
.@subject: email subject,  
.@ip: ip of computer sent,  
.@browser: name of browser,  
.@sessionid: ASP.NET session id,  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert unsuccessful.  
  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
  
--check all of parameter is valid.  
declare @affiliateid int,@maximumPer10minutes int --maximum of 20 emails per 10 minutes for each session  
  
select @affiliateid=-1,@maximumPer10minutes=20  
--Check creator name  
if(@creator<>-1 and not exists(select 1 from AffInfo with (nolock) where AffId=@creator))  
begin  
 begin   
            select @ErrMsg='Invalid creator!',@ErrCode=101  
            return  
      end   
end  
--check affiliate username  
if(@affiliate is not null)  
begin  
     select @affiliateid=AffID  
     from AffInfo  with (nolock)    
     where username=@affiliate  
    if (@@rowcount<>1)  
      begin   
   select @affiliateid=-1              
      end             
end  
  
--check content  
if (isnull(@content,'')='')  
  begin  
      select @ErrMsg='Invalid mail content!',@ErrCode=102  
            return  
  end  
--check sender name  
 if (isnull(@sender,'')='')  
  begin  
      select @ErrMsg='Invalid sender name!',@ErrCode=103  
            return  
  end  
   
--check email  
if (isnull(@email,'')='')  
  begin  
      select @ErrMsg='Invalid  email address!',@ErrCode=104  
            return  
  end  
  
--check mail subject  
if (isnull(@subject,'')='')  
  begin  
      select @ErrMsg='Invalid  mail subject!',@ErrCode=105  
            return  
  end  
  
--check ip  
if (isnull(@ip,'')='')  
  begin  
      select @ErrMsg='Invalid sender ip!',@ErrCode=106  
            return  
  end  
  
--check browser  
if (isnull(@browser,'')='')  
  begin  
      select @ErrMsg='Invalid browser name!',@ErrCode=107  
            return  
  end  
  
--check session id  
if (isnull(@sessionid,'')='')  
  begin  
      select @ErrMsg='Invalid ASP.NET session id!',@ErrCode=108  
            return  
  end  
--Check is allow to send email (just allow to send maximum of @maximumPer10minutes per 10 minutes)  
--if (@affiliateid<>-1)  
--begin  
 declare @count int  
 select @count=count(1) from [EmailHistory] with (nolock)  
 where sessionid=@sessionid and datediff(mi,createddate,current_timestamp)<=10  
  
 if(@count>@maximumPer10minutes)  
 begin  
   select @ErrMsg='You are just allowed to send maximum of ' + cast(@maximumPer10minutes as varchar(5)) + ' emails per 10 minutes!',@ErrCode=102  
    return  
 end  
--end  
BEGIN TRANSACTION  
INSERT INTO [dbo].[EmailHistory]  
           ([content]  
           ,[sender]  
           ,[creator]  
           ,[AffID]  
           ,[affname]  
           ,[email]  
           ,[subject]  
           ,[createddate]  
           ,[ip]  
           ,[browser]  
           ,[sessionid]  
           )  
     VALUES  
           (@content  
           ,@sender  
           ,@creator  
           ,@affiliateid  
           ,@affiliate  
           ,@email  
           ,@subject  
           ,getdate()  
           ,@ip  
           ,@browser  
           ,@sessionid)  
             
IF @@ERROR <> 0  
BEGIN  
 ROLLBACK TRANSACTION  
 Select @ErrMsg = N'Error! Insert email unsuccessfully!', @ErrCode = 1001  
 return  
END  
  
SELECT @MID = SCOPE_IDENTITY()  
COMMIT TRANSACTION  
  
DECLARE @LogData nvarchar(200)  
SELECT @LogData = 'Insert into EmailHistory MID:' + dbo.Aff_ToString(@MID)  
  
declare @SPName varchar(50)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@creator,   
 @AffID = @affiliateid,   
 @TypeName= 'Email',   
 @SPName=@SPName,  
 @IP =@IP,  
 @Details=@LogData  
   
end  

GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistoryIns] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EmailHistoryIns] TO [vnteam]
GO