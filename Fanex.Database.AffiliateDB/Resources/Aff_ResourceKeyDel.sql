USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourceKeyDel]    Script Date: 02/28/2013 14:17:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_ResourceKeyDel]
	@Updatedby int ,
	@IDList varchar(max),
	@IP nvarchar(15)='',	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@Updatedby,@funcname='[Resources]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
	
If @ErrCode <> 0
	RETURN
	
/*
Declare @Temp table(RefID varchar(50),ResourceKey varchar(50))
Insert into @Temp(RefID,ResourceKey)
Select distinct RefID,ResourceKey
from [dbo].[RefResources] (nolock)
where ResourceID in (select val from dbo.strsplit(@IDList, ',') )
*/
Delete r
From [dbo].[RefResources] r (nolock)
WHERE ResourceID in (select val from dbo.strsplit(@IDList, ','))
--inner join @Temp t on t.RefID=r.RefID and t.ResourceKey=r.ResourceKey

declare @SPName varchar(50), @Detail nvarchar(max) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete a Resource. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Resources', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
