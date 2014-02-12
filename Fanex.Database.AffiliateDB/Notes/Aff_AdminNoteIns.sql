ALTER PROCEDURE [dbo].[Aff_AdminNoteIns]  
 @Noteid [int] OUTPUT,  
 @Note [nvarchar](1000),  
 @CustID [int],  
 @Updatedby [int],  
 @IP [nvarchar](15) = '',  
	@Language varchar(5)= 'en-US', 
 @ErrCode [int] = 0 OUTPUT,  
 @ErrMsg [nvarchar](4000) = '' OUTPUT  
WITH EXECUTE AS CALLER  
AS  
begin   
/*  
Created: 20090122@TrangLe  
Task : [description of SP]  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
- 20090122@[Reviewer]: [Description of revision]   
  
Param's Explanation:  
. @Noteid : autonumber output  
. @Note: content of the note  
. @CustID: Affiliate ID  
. @Updatedby: User cust id  
  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert note unsuccessfully!  
  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
  
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@Updatedby,  
 @AffId=@CustID,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
BEGIN TRANSACTION  
INSERT INTO AdminNotes  
(    
 [Note] ,  
 [Updateddate] ,  
 [AffID] ,  
 [Updatedby]   
)  
VALUES  
(   
 @Note ,  
 GETDATE(),  
 @CustID ,  
 @Updatedby   
)  
IF @@ERROR <> 0  
BEGIN  
 ROLLBACK TRANSACTION  
 Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! Insert note unsuccessfully!' 
					when 'zh-CN' then N'錯誤!插入註解不成功!'
					when 'zh-TW' then N'错误！插入注解不成功！'
					else N'Error! Insert note unsuccessfully!' 
				end, @ErrCode = 1001  
 return  
END  
  
SELECT @Noteid = SCOPE_IDENTITY()  
COMMIT TRANSACTION  
  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Create Note ID:' + dbo.Aff_ToString(@Noteid)  
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @Updatedby,  
 @AffID = @CustID,  
 @Typename = 'UserNote', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
   
end  