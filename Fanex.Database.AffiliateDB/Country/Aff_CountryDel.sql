USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountryDel]    Script Date: 01/22/2013 15:13:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_CountryDel]
	@Updatedby int ,
	@IDList varchar(max),
	@IP nvarchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
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
	

delete [dbo].[Country]
where CountryID in (select val from dbo.strsplit(@IDList, ',') )

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Country. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Country', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
