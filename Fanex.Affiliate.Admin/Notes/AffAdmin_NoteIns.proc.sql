ALTER PROCEDURE [dbo].[AffAdmin_NoteIns]  
 @Content [nvarchar](1000),  
 @AffId [int],  
 @Updatedby [int],  
 @IP [nvarchar](15) = '',  
 @Language varchar(5)= 'en-US', 
 @ErrCode [int] = 0 OUTPUT

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
. @AffId: Affiliate ID  
. @Updatedby: User cust id  
  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert note unsuccessfully!  
  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  

DECLARE @Noteid int

EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@Updatedby,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output
   
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
 @Content ,  
 GETDATE(),  
 @AffId ,  
 @Updatedby   
)  
IF @@ERROR <> 0  
BEGIN  
 ROLLBACK TRANSACTION  
 Select @ErrCode = 50  
 return  
END  
  
SELECT @Noteid = SCOPE_IDENTITY()  
COMMIT TRANSACTION  
  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Create Note ID:' + dbo.Aff_ToString(@Noteid)  
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @Updatedby,  
 @AffID = @AffId,  
 @Typename = 'UserNote', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
   
end  