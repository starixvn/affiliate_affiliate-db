USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountryIns]    Script Date: 02/28/2013 13:31:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_CountryIns]
	@Updatedby int ,
	@CountryID nvarchar(6),
	@CountryName nvarchar(255),	
	@Description nvarchar(100)=NULL,	
	@Icon nvarchar(100)=NULL,
	@DisplayOrder smallint=1,
	@IsEnabled bit=1,
	@IP nvarchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Insert Country
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
	

INSERT INTO [Affiliate_ZZun].[dbo].[Country]
           ([CountryID]
           ,[CountryName]
           ,[Description]
           ,[Icon]
           ,[DisplayOrder]
           ,[IsEnabled])
     VALUES
           (@CountryID
           ,@CountryName
           ,@Description
           ,@Icon
           ,@DisplayOrder
           ,@IsEnabled)


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Country. ID= ' + @CountryID +
	 '. Description=' + isnull(@Description,'')
	 

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Country', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
