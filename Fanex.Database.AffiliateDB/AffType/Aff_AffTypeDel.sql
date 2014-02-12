USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeDel]    Script Date: 02/27/2013 13:45:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_AffTypeDel]
	@Updatedby int ,
	@IDList varchar(max),
	@IP nvarchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:


Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

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
	

delete [dbo].[AffType]
where TypeID in (select val from dbo.strsplit(@IDList, ',') )

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete AffType. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'AffType', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeDel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeDel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeDel] TO [bodbDownlineNetView]

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffTypeDel] TO [vnteam]