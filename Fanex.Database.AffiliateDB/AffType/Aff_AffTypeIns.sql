USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeIns]    Script Date: 02/27/2013 13:33:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_AffTypeIns]
	@Updatedby int ,	
	@Name nvarchar(50),	
	@Description nvarchar(100)=NULL,		
	@IP nvarchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
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
	
end
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeIns] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeIns] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeIns] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffTypeIns] TO [vnteam]