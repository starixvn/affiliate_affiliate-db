/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffTypeIns]
	@Updatedby		INT ,	
	@Name			NVARCHAR(50),	
	@Description	NVARCHAR(100)=NULL,		
	@IP				NVARCHAR(15)='',	
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
Created: 20130123@Joseph
Task : Insert AffType
DB: DB052.Affiliate_ZZun
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/

BEGIN
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@Updatedby,@funcname='[SystemSettings]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
	
If @ErrCode <> 0
	RETURN
	

INSERT INTO [Affiliate_ZZun].[dbo].[AffType]
           (
           [Name]
           ,[Description]
           ,[Creator]
           ,[CreatedDate]
           )
     VALUES
           (
           @Name
           ,@Description
           ,@Updatedby
           ,CURRENT_TIMESTAMP
           )


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New AffType. Name= ' + dbo.Aff_ToString(@Name)
	 

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'AffType', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
END
GO