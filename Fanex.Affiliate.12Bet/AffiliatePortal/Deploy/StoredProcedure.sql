 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[UpdateEmbeddableSample]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateEmbeddableSample]
	-- Add the parameters for the stored procedure here
	@embeddableId int,
	@name nvarchar(256),
	@description nvarchar(1024)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update EmbeddableSamples  with(rowlock,updlock)
	set name = @name,
		[description] = @description
	where embeddableId = @embeddableId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END

GO
GRANT EXECUTE ON [dbo].[UpdateEmbeddableSample] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEmbeddableSample] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[ToggleEnableEmbeddableSample]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ToggleEnableEmbeddableSample]
	-- Add the parameters for the stored procedure here
	@embeddableId int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update EmbeddableSamples  with(rowlock,updlock)
	set [enable] = ~[enable]
	where embeddableId = @embeddableId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END

GO
GRANT EXECUTE ON [dbo].[ToggleEnableEmbeddableSample] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[ToggleEnableEmbeddableSample] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[DeleteLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @code nvarchar(50)
	declare @result bit
	-- Insert statements for procedure here
	
	set @code = (select code from Languages (nolock) where languageId = @languageId)
	
	delete from Languages
	where languageId = @languageId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
	begin try
	--delete related data
	begin transaction
	delete from EmbeddableLanguages
	where languageCode = @code
	
	delete from TermLanguages
	where languageCode = @code
	
	delete from ThemeLanguages
	where languageCode = @code
	commit transaction
	end try
	begin catch
		rollback transaction
		print ERROR_MESSAGE()
		set  @result = convert(bit,0)
	end catch
	
	
	select @result
END

GO
GRANT EXECUTE ON [dbo].[DeleteLanguage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteLanguage] TO [vnteam]

GO
/****** Object:  StoredProcedure [dbo].[UpdateLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int,
	@code nvarchar(50),
	@name nvarchar(64)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @oldCode nvarchar(50)
	declare @result bit
	-- Insert statements for procedure here
	set @oldCode = (select code from Languages (nolock) where languageId = @languageId)
	
	begin try
	--delete related data
	begin transaction
	update Languages  with(rowlock,updlock)
	set code = @code, name = @name
	where languageId = @languageId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
		
	--update related data
	if @code <> @oldCode
	begin
		update EmbeddableLanguages  with(rowlock,updlock)
		set languageCode = @code
		where languageCode = @oldCode
		
		update TermLanguages  with(rowlock,updlock)
		set languageCode = @code
		where languageCode = @oldCode
		
		update ThemeLanguages  with(rowlock,updlock)
		set languageCode = @code
		where languageCode = @oldCode
	end
	
	commit transaction
	end try
	begin catch
		rollback transaction
		print ERROR_MESSAGE()
		set  @result = convert(bit,0)
	end catch
	
	select @result
	
END
GO
GRANT EXECUTE ON [dbo].[UpdateLanguage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateLanguage] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetThemesByLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/27/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetThemesByLanguage]
	-- Add the parameters for the stored procedure here
	@languageCode nvarchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Themes.themeId, ThemeLanguages.name,Themes.folder, Themes.[enable],Themes.[level]
	from Themes (nolock)
	inner join ThemeLanguages (nolock) on Themes.themeId = ThemeLanguages.themeId
	where ThemeLanguages.languageCode = @languageCode and Themes.[enable] = 1
END
GO
GRANT EXECUTE ON [dbo].[GetThemesByLanguage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetThemesByLanguage] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetThemesByLanguage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetThemesByLanguage] TO [vnteam]
GO


-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertWidget]
	-- Add the parameters for the stored procedure here
	@embeddableId int,
	@bucket nvarchar(64),
	@pageId uniqueidentifier,
	@title nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @rootEmbeddableId int
	declare @isEmbeddableSample bit
	declare @instanceId int
	declare @orderNo int
	set @orderNo = dbo.GetMaxWidgetOrderNo(@pageId,@bucket) + 1
	
	if @embeddableId > 9999
	begin
		select @rootEmbeddableId = fromEmbeddableId
		from EmbeddableSamples (nolock)
		where embeddableId = @embeddableId
		
		set @isEmbeddableSample = 1
	end
	else
	begin
		set @rootEmbeddableId = @embeddableId
		set @isEmbeddableSample = 0
	end
	begin try
	-- Insert statements for procedure here
	begin tran
	insert into PageEmbeddableTemps(pageId,bucket,embeddableId,title,[status],orderNo)
	values(@pageId,@bucket,@embeddableId,@title,0,@orderNo)
	
	IF @@ERROR <> 0
		set @instanceId = 0
	ELSE
		set @instanceId = cast(SCOPE_IDENTITY() as int)
	
	if @isEmbeddableSample = 1 and @instanceId <> 0
	begin
		--copy metadata from EmbeddableMeta -> PageEmbeddableMeta
		insert into PageEmbeddableMetaTemps(instanceId,[key],value)
		select @instanceId,[key],value
		from EmbeddableMeta (nolock)
		where EmbeddableMeta.embeddableId = @embeddableId
	end
	commit tran
	end try
	begin catch
		rollback tran
		set @instanceId=0
	end catch
	select @instanceId
END
GO
GRANT EXECUTE ON [dbo].[InsertWidget] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertWidget] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[InsertWidget]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith

/****** Object:  StoredProcedure [dbo].[GetBuckets]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBuckets]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select * 
	from Buckets (nolock)
	order by inBody desc
END
GO
GO
GRANT EXECUTE ON [dbo].[GetBuckets] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetBuckets] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetBuckets] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetBuckets] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[DeletePage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith Tran
-- Create date: 3:29 PM 9/21/2010
-- Description:	Delete page and related data
-- =============================================
CREATE PROCEDURE [dbo].[DeletePage]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	begin try
	begin tran
	-- delete page
	delete from PageTemps
	where pageId = @pageId
	
	set @result = cast(@@rowcount as bit)
	
	-- update master page
	update PageTemps with (rowlock,updlock)
	set masterId = null
	where masterId = @pageId
	
	-- update menu
	update MenuTemps with (rowlock,updlock)
	set pageId = null
	where pageId = @pageId
	
	-- delete AliasURLs
	delete from AliasURLs
	where pageId = @pageId
	
	-- delete PageEmbeddableMeta
	delete from PageEmbeddableMetaTemps
	where instanceId in (	select instanceId
							from PageEmbeddableTemps (nolock)
							where pageId = @pageId)
	
	-- delete PageEmbeddables
	delete from PageEmbeddableTemps
	where pageId = @pageId
	
	-- delete SEOMetaData
	delete from SEOMetaData
	where pageId = @pageId
	commit tran
	end try	
	begin catch
	 rollback tran
	 print ERROR_MESSAGE()
	 set @result = cast(0 as bit)
	end catch
	select @result
END
GO
GRANT EXECUTE ON [dbo].[DeletePage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[DeletePage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeletePage] TO [vnteam]






GO
/****** Object:  StoredProcedure [dbo].[DeleteSiteTemp]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/06/2010
-- Update data: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteSiteTemp]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	declare @result bit
	begin try
	--site
	begin tran
	delete from SiteMetaTemps
	where siteId = @siteId
	delete from SiteMetaHistories
	where siteId = @siteId
	
	delete from SiteHistories
	where siteId = @siteId
	delete from SiteTemps
	where siteId = @siteId
	
	
	--widget(page embeddable)
	declare @Widget table (instanceId int)
	insert into @Widget(instanceId)
	select instanceId from PageEmbeddables
	where pageId in (select pageId from Pages where siteId = @siteId)
	
	
	
	delete from PageEmbeddableTemps
	where instanceId in (select instanceId from @Widget)
	delete from PageEmbeddableHistories
	where instanceId in (select instanceId from @Widget)
	
	
	delete from PageEmbeddableMetaTemps
	where instanceId in (select instanceId from @Widget)
	delete from PageEmbeddableMetaHistories
	where instanceId in (select instanceId from @Widget)
	
	
	
	--page
	
	delete from PageTemps
	where siteId = @siteId
	delete from PageHistories
	where siteId = @siteId
	
	
	delete from MenuTemps
	where siteId = @siteId
	delete from MenuHistories
	where siteId = @siteId
	commit tran
	set @result=cast(1 as bit)
	end try
	begin catch
		rollback tran
		print ERROR_MESSAGE() 
		select cast(0 as bit)		
	end catch
	
	select @result
END
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEmbeddableSample] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[CopySiteFromMainToHistory]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CopySiteFromMainToHistory]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	if(not exists (select 1 from Sites (nolock) where SiteId=@siteId))
	begin
		--invalid SiteID
		select cast(0 as bit)
		return
	end
 begin try   
   begin transaction 
	if(exists (select 1
				from SiteHistories sh (nolock) 
				 inner join Sites s (nolock) on s.siteId=sh.siteId and s.[currentRevision]=sh.versionId				
				where s.SiteId=@siteId))
	begin
		--already copied
		select cast(1 as bit)
		return
	end
	
	declare @versionId int
	select @versionId=[currentRevision]
	from Sites (nolock)
	where siteId=@siteId
	--TODO:
	--Sites -> SiteHistories 
	INSERT INTO [dbo].[SiteHistories]
		   ([siteId]
		   ,[versionId]
		   ,[siteName]
		   ,[siteHost]
		   ,[siteTitle]
		   ,[displayName]
		   ,[copyright]           
		   ,[bodyLayoutId]
		   ,[footerLayoutId]
		   ,[homePageId])
	SELECT [siteId]
	  ,[currentRevision]		
	  ,[siteName]
	  ,[siteHost]
	  ,[siteTitle]
	  ,[displayName]
	  ,[copyright]      
	  ,[bodyLayoutId]
	  ,[footerLayoutId]
	  ,[homePageId]
  FROM [dbo].[Sites] (nolock)
  where   siteId=@siteId         
	--SiteMeta -> SiteMetaHistories
	INSERT INTO [dbo].[SiteMetaHistories]
		   ([siteId]
		   ,[versionId]
		   ,[key]
		   ,[value])
	  SELECT [siteId]
	  ,@versionId
	  ,[key]
	  ,[value]
	  FROM [dbo].[SiteMeta] (nolock)
	  where   siteId=@siteId     
	--Menu -> MenuHistories
	set identity_insert [dbo].[MenuHistories] on
	INSERT INTO [dbo].[MenuHistories]
		   ([menuId],
		   [siteId]
		   ,[versionId]
		   ,[parentId]
		   ,[level]
		   ,[orderNo]
		   ,[name]
		   ,[link]
		   ,[pageId])
	  SELECT [menuId]
	  ,[siteId]
	  ,@versionId
	  ,[parentId]
	  ,[level]
	  ,[orderNo]
	  ,[name]
	  ,[link]
	  ,[pageId]
	 FROM [dbo].[Menu]  (nolock)
	  where   siteId=@siteId  
	set identity_insert [dbo].[MenuHistories] off    
	--Pages -> PageHistories
	INSERT INTO [dbo].[PageHistories]
		   ([pageId]
		   ,[siteId]
		   ,[versionId]
		   ,[url]
		   ,[title]
		   ,[masterId]
		   ,[enable]
		   ,[createdDate]
		   ,[updatedDate])
	   SELECT [pageId]
	  ,[siteId]
	  ,@versionId
	  ,[url]
	  ,[title]
	  ,[masterId]
	  ,[enable]
	  ,[createdDate]
	  ,[updatedDate]
	FROM [dbo].[Pages] (nolock)
	 where   siteId=@siteId    
	--PageEmbeddables -> PageEmbeddableHistories
	set identity_insert [dbo].[PageEmbeddableHistories] on
	INSERT INTO [dbo].[PageEmbeddableHistories]
		   ([instanceId]
		   ,[versionId]
		   ,[pageId]
		   ,[bucket]
		   ,[embeddableId]
		   ,[title]
		   ,[status]
		   ,[orderNo])
	 SELECT pe.[instanceId]
	   ,@versionId
	  ,pe.[pageId]
	  ,pe.[bucket]
	  ,pe.[embeddableId]
	  ,pe.[title]
	  ,pe.[status]
	  ,pe.[orderNo]
  FROM [dbo].[PageEmbeddables] pe (nolock)      
	   inner join Pages p (nolock) on p.pageid=pe.pageId
  where p.siteId=@siteId       
  set identity_insert [dbo].[PageEmbeddableHistories] off
   --PageEmbeddableMeta -> PageEmbeddableMetaHistories
	INSERT INTO [dbo].[PageEmbeddableMetaHistories]
		   ([instanceId]
			,[versionId]
		   ,[key]
		   ,[value])
	SELECT pm.[instanceId]
	   ,@versionId	
	  ,pm.[key]
	  ,pm.[value]
  FROM [dbo].[PageEmbeddableMeta] pm (nolock)  
	  inner join dbo.PageEmbeddables pe (nolock) on pe.instanceId=pm.instanceId
	   inner join Pages p (nolock) on p.pageid=pe.pageId
   where p.siteId=@siteId       
	-- return
	select cast(1 as bit)
	-- Insert statements for procedure here
	-- return
	
	
	commit transaction
  end try
  
  begin catch  
		rollback transaction
		print ERROR_MESSAGE()	
		select cast(0 as bit)
  end catch	
	 
END

GO
GRANT EXECUTE ON [dbo].[CopySiteFromMainToHistory] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CopySiteFromMainToHistory] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[DeleteSite]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/06/2010
-- Update data: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteSite]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	declare @result bit
	-- Insert statements for procedure here
	begin try
	begin tran
	delete from Sites
	where siteId = @siteId
	
	set @result = cast(@@rowcount as bit)
	
	--site
	delete from SiteMeta
	where siteId = @siteId
	delete from SiteMetaTemps
	where siteId = @siteId
	delete from SiteMetaHistories
	where siteId = @siteId
	
	delete from SiteHistories
	where siteId = @siteId
	delete from SiteTemps
	where siteId = @siteId
	delete from SiteVersions
	where siteId = @siteId
	
	--widget(page embeddable)
	declare @Widget table (instanceId int)
	insert into @Widget(instanceId)
	select instanceId from PageEmbeddables
	where pageId in (select pageId from Pages where siteId = @siteId)
	
	delete from PageEmbeddables
	where instanceId in (select instanceId from @Widget)
	
	delete from PageEmbeddableTemps
	where instanceId in (select instanceId from @Widget)
	delete from PageEmbeddableHistories
	where instanceId in (select instanceId from @Widget)
	
	delete from PageEmbeddableMeta
	where instanceId in (select instanceId from @Widget)
	delete from PageEmbeddableMetaTemps
	where instanceId in (select instanceId from @Widget)
	delete from PageEmbeddableMetaHistories
	where instanceId in (select instanceId from @Widget)
	
	--page data
	delete from SEOMetaData
	where pageId in (select pageId from Pages where siteId = @siteId)
	
	--page
	delete from Pages
	where siteId = @siteId
	delete from PageTemps
	where siteId = @siteId
	delete from PageHistories
	where siteId = @siteId
	
	--comment
	delete from Comments
	where postId in (select postId from Posts where siteId = @siteId)
	
	--post
	delete from Posts
	where siteId = @siteId
	
	--taxonomy
	declare @MyTaxonomy table (taxonomyId int)
	insert into @MyTaxonomy
	select taxonomyId from Taxonomy
	where termId in (select termId from Terms where siteId = @siteId)
	
	delete from TermRelationships
	where taxonomyId in (select taxonomyId from @MyTaxonomy)
	
	delete from Taxonomy
	where taxonomyId in (select taxonomyId from @MyTaxonomy)
	
	delete from TermLanguages
	where termId in (select termId from Terms where siteId = @siteId)
	
	delete from Terms
	where siteId = @siteId
	
	--menu
	delete from Menu
	where siteId = @siteId
	delete from MenuTemps
	where siteId = @siteId
	delete from MenuHistories
	where siteId = @siteId
	commit tran
	set @result=cast(1 as bit)
	end try
	begin catch
		rollback tran
		print ERROR_MESSAGE()
		set @result=cast(0 as bit)
	end catch
	select @result
END

GO
GRANT EXECUTE ON [dbo].[DeleteSite] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteSite] TO [vnteam]

GO


/****** Object:  StoredProcedure [dbo].[GetLayouts]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetLayouts]
	-- Add the parameters for the stored procedure here
	@isBody bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select *
	from Layouts (nolock)
	where isBody = @isBody
	--disable some layout
	and layoutId not in (8,10,11,12)
END
GO
GRANT EXECUTE ON [dbo].[GetLayouts] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetLayouts] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetLayouts] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetLayouts] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[UpdateFooterLayout]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateFooterLayout]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@footerLayout int
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--TODO:
	--1. if new footerlayoutId = old footerlayoutId -> STOP!
	declare @newLayoutName nvarchar(256),@oldLayoutName nvarchar(256)
	select @newLayoutName=[layoutFile] from Layouts (nolock) where layoutId=@footerLayout
	if(not exists (select 1 from SiteTemps(nolock) where siteId=@siteId) or @newLayoutName is null)
	begin  
	  select cast(0 as bit)
	  return       
	end  
	
	declare @currentFooterLayoutId int
	
	select @currentFooterLayoutId=footerLayoutId 
	from SiteTemps (nolock)
	where siteId=@siteId
	
	if(@newLayoutName is not null and @currentFooterLayoutId is not null and @currentFooterLayoutId<>@footerLayout) 
	begin         
		begin try
			begin transaction UpdateFooterLayout
			 --2. update SiteTemps table (footerlayoutId)
			 update SiteTemps with(rowlock,updlock)
			 set footerLayoutId=@footerLayout
			  where siteId=@siteId		
			 --Current footer layout is Footer
			 select @oldLayoutName=[layoutFile] from Layouts (nolock) where layoutId=@currentFooterLayoutId
			 
			 if (@oldLayoutName ='f1')
			 begin
				if(@newLayoutName in ('f2','f3'))
				begin
					--move all embeddables to footerleft buckets
					update pe
					set pe.bucket='FOOTERL'
					from PageEmbeddableTemps pe with (rowlock,updlock)
						inner join PageTemps p(nolock) on p.pageId= pe.pageId
					where p.siteId=@SiteId						     
						 and pe.bucket='FOOTER'					
				end				
			 end
			 else if (@oldLayoutName ='f2')
			 begin
				if(@newLayoutName ='f1')
				begin
				   --update FooterLeft
				   update pe
					set pe.bucket='FOOTER'
					from PageEmbeddableTemps pe with (rowlock,updlock)
						inner join PageTemps p(nolock) on p.pageId= pe.pageId
					where p.siteId=@SiteId						     
						 and pe.bucket='FOOTERL'					
					--update FooterR and position
					update pe
					set pe.bucket='FOOTER',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='FOOTER'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='FOOTERR'     					     
				  
				end
				--No need to update three columns footer
			 end
			 else if(@oldLayoutName ='f3')
			 begin				
				if(@newLayoutName ='f1')
				begin
					 --update FooterLeft
					update pe
					set pe.bucket='FOOTER'
					from PageEmbeddableTemps pe with (rowlock,updlock)
						inner join PageTemps p(nolock) on p.pageId= pe.pageId
					where p.siteId=@SiteId						     
						 and pe.bucket='FOOTERL'	
					--update FooterM and position
					update pe
					set pe.bucket='FOOTER',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='FOOTER'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='FOOTERM'   
					   
					  --update FooterR and position
					update pe
					set pe.bucket='FOOTER',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='FOOTER'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='FOOTERR'      
						 
					
				end
				else if(@newLayoutName ='f2') --f3->f2
				begin
				 --Move all FooterM embeddables to FooterL and update position
					update pe
					set pe.bucket='FOOTERL',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='FOOTERL'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='FOOTERM'      
				end
			 end				
				commit transaction UpdateFooterLayout
		end try
		begin catch 
		   rollback transaction UpdateFooterLayout
		   print ERROR_MESSAGE()
		   select cast(0 as bit)
		   return
		end catch
	
	--return true if SiteTemps tables was updated, else false
	end
   
	select cast(1 as bit)
END
GO
GRANT EXECUTE ON [dbo].[UpdateFooterLayout] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdateFooterLayout] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateFooterLayout] TO [vnteam]
GO


GO
/****** Object:  StoredProcedure [dbo].[UpdateBodyLayout]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateBodyLayout]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@bodyLayoutId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--TODO:
	 declare @newLayoutName nvarchar(256),@oldLayoutName nvarchar(256)
	select @newLayoutName=[layoutFile] from Layouts (nolock) where layoutId=@bodyLayoutId
	if(not exists (select 1 from SiteTemps(nolock) where siteId=@siteId) or @newLayoutName is null)
	begin  
	  select cast(0 as bit)
	  return       
	end  
	
	declare @currentBodyLayoutId int, @maxOrderNo int
	
	select @currentBodyLayoutId=bodyLayoutId 
	from SiteTemps (nolock)
	where siteId=@siteId
		
	if(@newLayoutName is not null and @currentBodyLayoutId is not null and @currentBodyLayoutId<>@bodyLayoutId) 
	begin         
		begin try
			begin transaction UpdateBodyLayout
			 --2. update SiteTemps table (BodylayoutId)
			 update SiteTemps with(rowlock,updlock)
			 set bodyLayoutId=@bodyLayoutId
			  where siteId=@siteId		
			 --Current body layout is Body
			 select @oldLayoutName=layoutFile from Layouts (nolock) where layoutId=@currentBodyLayoutId
			  --@oldLayoutName ='l1' no need to update , all embeddables have already been in Content buckets
			  --@newLayoutName in ('l2r','l2l','l3lr')
			 if (@oldLayoutName ='l2r')
			 begin
				if(@newLayoutName ='l2l')
				begin
				   --update RIGHT bucket to LEFT BUCKET
				   update pe
					set pe.bucket='LEFT'
					from PageEmbeddableTemps pe with (rowlock,updlock)
						inner join PageTemps p(nolock) on p.pageId= pe.pageId
					where p.siteId=@SiteId						     
						 and pe.bucket='RIGHT'
				end
				else if(@newLayoutName ='l1')
				begin
					--move all RIGHT embeddables to CONTENT and update position
					update pe
					set pe.bucket='CONTENT',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='CONTENT'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='RIGHT'
				end
				--No need to update three columns body l3lr
			 end
			 else if(@oldLayoutName ='l2l')
			 begin				
				if(@newLayoutName ='l2r')
				begin
				   --update LEFT bucket to RIGHT BUCKET
				   update pe
					set pe.bucket='RIGHT'
					from PageEmbeddableTemps pe with (rowlock,updlock)
						inner join PageTemps p(nolock) on p.pageId= pe.pageId
					where p.siteId=@SiteId						     
						 and pe.bucket='LEFT'
				end
				else if(@newLayoutName ='l1')
				begin
					--move all LEFT embeddables to CONTENT and update position
					update pe
					set pe.bucket='CONTENT',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='CONTENT'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='LEFT'
				end
				--No need to update three columns body l3lr
			 end		
			 else if(@oldLayoutName ='l3lr')		
			 begin
				 /*case new layout is l1 
					 + Move all left embeddables to content and update position
					 + Move all right embeddables to content and update position
				 */	
				 if(@newLayoutName ='l1')
				 begin
					--Move all left embeddables to content and update position
					update pe
					set pe.bucket='CONTENT',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='CONTENT'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='LEFT'
					  --Move all right embeddables to content and update position
					update pe
					set pe.bucket='CONTENT',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='CONTENT'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='RIGHT'        
				 end
				 
				 
				 /*case new layout is l2r
					+ move all left embeddables to right and update position
				 */
				 else if (@newLayoutName ='l2r')
				 begin
					-- move all left embeddables to right and update position
					update pe
					set pe.bucket='RIGHT',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='CONTENT'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='LEFT'					
				 end
				 /*case new layout is l2l
					+ move all right embeddables to left and update position
				 */
				  else if (@newLayoutName ='l2l')
				  begin
					--move all right embeddables to left and update position
					update pe
					set pe.bucket='LEFT',
						pe.orderNo=pe.orderNo +
							   isnull((select max(orderNo)
								 from PageEmbeddableTemps (nolock)
								 where pageId=pe.PageId 
									   and bucket='CONTENT'),0)
					from PageEmbeddableTemps pe with (rowlock,updlock)
						 inner join PageTemps p (nolock) on p.pageid=pe.pageid 
					where p.siteId=@SiteId	
						 and pe.bucket='RIGHT'				
				  end
				 
			 end
			commit transaction UpdateBodyLayout
		end try
		begin catch 
		   rollback transaction UpdateBodyLayout
		   print ERROR_MESSAGE()
		   select cast(0 as bit)
		   return
		end catch    
 
	end
   
	select cast(1 as bit)
	
END
GO
GRANT EXECUTE ON [dbo].[UpdateBodyLayout] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdateBodyLayout] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateBodyLayout] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetSiteBySiteId]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSiteBySiteId]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
	from Sites (nolock)
	left join Layouts LB (nolock) on Sites.bodyLayoutId = LB.layoutId
	left join Layouts LF (nolock) on Sites.footerLayoutId = LF.layoutId
	where siteId = @siteId
END
GO
GRANT EXECUTE ON [dbo].[GetSiteBySiteId] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetSiteBySiteId] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetSiteBySiteId] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSiteBySiteId] TO [vnteam]


GO
/****** Object:  StoredProcedure [dbo].[GetSiteBySiteHost]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSiteBySiteHost]
	-- Add the parameters for the stored procedure here
	@siteHost nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
	from Sites (nolock)
	left join Layouts (nolock) as LB on Sites.bodyLayoutId = LB.layoutId
	left join Layouts (nolock) as LF on Sites.bodyLayoutId = LF.layoutId
	where siteHost = @siteHost
END
GO
GRANT EXECUTE ON [dbo].[GetSiteBySiteHost] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetSiteBySiteHost] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetSiteBySiteHost] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSiteBySiteHost] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[GetSitePreviewBySiteId]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSitePreviewBySiteId] 
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select SiteTemps.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
	from SiteTemps (nolock)
	left join Layouts LB (nolock) on SiteTemps.bodyLayoutId = LB.layoutId
	left join Layouts LF (nolock) on SiteTemps.footerLayoutId = LF.layoutId
	where SiteTemps.siteId = @siteId
END
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewBySiteId] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewBySiteId] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewBySiteId] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSitePreviewBySiteId] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[GetSitePreviewBySiteHost]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSitePreviewBySiteHost]
	-- Add the parameters for the stored procedure here
	@siteHost nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select SiteTemps.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
	from SiteTemps (nolock)
	left join Layouts (nolock) as LB on SiteTemps.bodyLayoutId = LB.layoutId
	left join Layouts (nolock) as LF on SiteTemps.bodyLayoutId = LF.layoutId
	where SiteTemps.siteHost = @siteHost
END
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewBySiteHost] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewBySiteHost] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewBySiteHost] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSitePreviewBySiteHost] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[GetSites]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/21/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSites] 
	-- Add the parameters for the stored procedure here
	@pageNumber int,
	@pageSize int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
	from Sites (nolock)
	left join Layouts LB (nolock)on Sites.bodyLayoutId = LB.layoutId
	left join Layouts LF (nolock) on Sites.footerLayoutId = LF.layoutId
	where siteId > 0
END
GO
GRANT EXECUTE ON [dbo].[GetSites] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSites] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[GetTemplateSites]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetTemplateSites]
	-- Add the parameters for the stored procedure here
	@takeCareValidSite bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	if @takeCareValidSite = 0
	begin
		select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
		from Sites (nolock)
		left join Layouts LB (nolock) on Sites.bodyLayoutId = LB.layoutId
		left join Layouts LF (nolock) on Sites.footerLayoutId = LF.layoutId
		where siteId < 0
		order by siteId desc
	end
	else
	begin
		select Sites.*, LB.layoutFile as bodyLayoutFile, LF.layoutFile as footerLayoutFile
		from Sites (nolock)
		left join Layouts LB (nolock) on Sites.bodyLayoutId = LB.layoutId
		left join Layouts LF (nolock) on Sites.footerLayoutId = LF.layoutId
		where Sites.siteId < 0 and Sites.homePageId <> '00000000-0000-0000-0000-000000000000'
		order by siteId desc
	end
END
GO
GRANT EXECUTE ON [dbo].[GetTemplateSites] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetTemplateSites] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[EditWidgetMeta]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/15/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EditWidgetMeta] 
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@title nvarchar(256),
	@key varchar(MAX),
	@data nvarchar(MAX)	,	
	@editEmbeddableSample bit
	-- data structure
	-- key:		key1,key2,key3
	-- data:	data_of_key1[$$$@@@###]data_of_key2[$$$@@@###]data_of_key3
	 --TODO:
	--UPDATE PageEmbeddableMeta Table
	
	--1. if the widget don't have these keys
			-- create keys and update values
	--2. if the widget have these keys
			-- just update values

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @metadata table(instanceId int, [key] nvarchar(32), value nvarchar(MAX), orderNo int identity(1,1))
	
	if @editEmbeddableSample = 0
	begin
		 BEGIN TRY
		   begin tran
			  --update title
			if @title <> ''
			begin
				update PageEmbeddableTemps  with (rowlock,updlock)
				set title = @title
				where instanceId = @instanceId
			end
			
			  insert into @metadata(instanceId,[key],value)
			  select @instanceId,'',String from [dbo].CLRSplitStringFunction(@data,'[$$$@@@###]',1)
			  update t
			   set [key]=cast(val as varchar(max))
			   from @metadata t
				   inner join dbo.strsplit(@key, ',') t1 on t1.rank=t.orderNo
				   
			  update p
			  set p.value=p1.value
			  from  PageEmbeddableMetaTemps p with (rowlock,updlock)
					inner join @metadata p1 on p1.instanceId=p.instanceId and p1.[key]=p.[key]
					
			  insert into  PageEmbeddableMetaTemps(instanceId,[key],value)
			  select instanceId,[key],value
			  from  @metadata
			  where  [key] not in (select [key] from PageEmbeddableMetaTemps (nolock) where instanceId=@instanceId )       
			  commit tran
			  select convert(bit,1)     
						  
		  END TRY
		  BEGIN CATCH	
				rollback tran
				print ERROR_MESSAGE()					
				select convert(bit,0)	
		  END CATCH
				   
	end
	else
	--save embeddable sample
	begin
		
		
		 BEGIN TRY
			begin tran
			 --update title
		if @title <> ''
		begin
			update EmbeddableSamples  with (rowlock,updlock)
			set name = @title
			where embeddableId = @instanceId
		end
		
			  insert into @metadata(instanceId,[key],value)
			  select @instanceId,'',String from [dbo].CLRSplitStringFunction(@data,'[$$$@@@###]',1)
			  update t
			   set [key]=cast(val as varchar(max))
			   from @metadata t
				   inner join dbo.strsplit(@key, ',') t1 on t1.rank=t.orderNo
				   
			  update p
			  set p.value=p1.value
			  from  EmbeddableMeta p with (rowlock,updlock)
					inner join @metadata p1 on p1.instanceId=p.embeddableId and p1.[key]=p.[key]
					
			  insert into  EmbeddableMeta(embeddableId,[key],value)
			  select instanceId,[key],value
			  from  @metadata
			  where  [key] not in (select [key] from EmbeddableMeta (nolock) where embeddableId=@instanceId )       
			  
			  --update meta of widgets if this sample embeddalbe
			  --masked as editable = false
			  if	(select editable from EmbeddableSamples
					where embeddableId = @instanceId) = 0
			  begin
				update PageEmbeddableMeta  with(rowlock,updlock)
				set value = (select value
							from @metadata p
							where PageEmbeddableMeta.[key] = p.[key])
				where instanceId in
				(
					select instanceId 
					from PageEmbeddables
					where embeddableId = @instanceId
				)
				
				update PageEmbeddableMetaTemps  with(rowlock,updlock)
				set value = (select value
							from @metadata p
							where PageEmbeddableMetaTemps.[key] = p.[key])
				where instanceId in
				(
					select instanceId 
					from PageEmbeddableTemps
					where embeddableId = @instanceId
				)
				
			  end
			  commit tran
			  select convert(bit,1)     
						  
		  END TRY
		  BEGIN CATCH	
				rollback tran
				print ERROR_MESSAGE()					
				select convert(bit,0)	
		  END CATCH
	end
	
END
GO
GRANT EXECUTE ON [dbo].[EditWidgetMeta] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[EditWidgetMeta] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[EditWidgetMeta] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[UpdateWidgetPositions]    Script Date: 11/12/2010 15:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateWidgetPositions]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier,
	@bucketList varchar(1024),
	@embeddableList varchar(1024),	
	@ErrMsg nvarchar(4000) ='' OUTPUT
	
	/*
		@bucketList: CONTENT,RIGHT
		@embeddableList: 5,7,3;8,4,2,10
		
	*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	--check pageid from PageEmbeddableTempsTemp
	if(not exists (select 1 from PageEmbeddableTemps with (nolock) where pageid=@pageID))
	 begin
		select @ErrMsg='Invalid page!'
	 end 
	 declare @PageEmbeddableTemps table (bucket nvarchar(64),instanceId int, orderNo smallint)
	 declare @rank int,@bucketName nvarchar(64),@embeddableArray varchar(1024)
	 select @rank=min(rank) from dbo.strsplit(@bucketList, ',')	  
	 
	 if @rank is not null
	begin
			while @rank is not null
				begin
				   BEGIN TRY
					   --Voi moi Bucket
					   
					   select @bucketName=cast(val as nvarchar(64)) from dbo.strsplit(@bucketList, ',') where rank=@rank
					   select @embeddableArray=cast(val as varchar(1024)) from dbo.strsplit(@embeddableList, ';') where rank=@rank
					   Insert into @PageEmbeddableTemps(bucket,instanceId,orderNo)
						select @bucketName,cast(val as int),rank
						from dbo.strsplit(@embeddableArray, ',')	  
						select @rank=min(rank) from dbo.strsplit(@bucketList, ',') where rank>@rank  
					  
				   END TRY
				   BEGIN CATCH						
						Select @ErrMsg = ERROR_MESSAGE()
						return	
				   END CATCH
				 
				end --end outer while
	end --end if
else ---Invalid Setting Data
  begin	
	Select @ErrMsg = N'Error! Invalid Input Data !'
	return	
  end 	
 begin try
  begin tran
  update a
  set a.bucket=b.Bucket,
	  a.orderNo=b.orderNo
  from PageEmbeddableTemps a with (rowlock,updlock)
	  inner join  @PageEmbeddableTemps b on b.instanceId=a.instanceId      
   commit tran   
  end try
  begin catch
	rollback tran
	Select @ErrMsg = ERROR_MESSAGE()
  end catch    
 
 
	
  END
GO
GRANT EXECUTE ON [dbo].[UpdateWidgetPositions] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdateWidgetPositions] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateWidgetPositions] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[EditSiteMeta]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/27/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EditSiteMeta] 
	-- Add the parameters for the stored procedure here
	@siteId int,
	@key nvarchar(MAX),
	@value nvarchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	-- key:		key1,key2,key3
	-- data:	data_of_key1[$$$@@@###]data_of_key2[$$$@@@###]data_of_key3
	 --TODO:
	--UPDATE PageEmbeddableMeta Table
	
	--1. if the widget don't have these keys
			-- create keys and update values
	--2. if the widget have these keys
			-- just update values
			
	SET NOCOUNT ON;
	
	 BEGIN TRY
		   begin tran
			 declare @SiteMeta table (siteId int,[key] nvarchar(64), value nvarchar(max), orderNo int identity(1,1))
			  insert into @SiteMeta(siteId,[key],value)
			  select @siteId,'',String from [dbo].CLRSplitStringFunction(@value,'[$$$@@@###]',1)
			  update t
			   set [key]=cast(val as varchar(max))
			   from @SiteMeta t
				   inner join dbo.strsplit(@key, ',') t1 on t1.rank=t.orderNo
				   
			  update s
			  set s.value=s1.value
			  from  SiteMetaTemps s with (rowlock,updlock)
					inner join @SiteMeta s1 on s1.siteId=s.siteId and s1.[key]=s.[key]
					
			  insert into  SiteMetaTemps(siteId,[key],value)
			  select siteId,[key],value
			  from  @SiteMeta
			  where  [key] not in (select [key] from SiteMetaTemps (nolock) where siteId=@siteId )       
			commit tran  
			  select convert(bit,1)     
						  
	END TRY
	BEGIN CATCH		
			rollback tran	
			print ERROR_MESSAGE()			
				select convert(bit,0)	
	END CATCH		  
	
END
GO
GRANT EXECUTE ON [dbo].[EditSiteMeta] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[EditSiteMeta] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[EditSiteMeta] TO [vnteam]
GO




/****** Object:  StoredProcedure [dbo].[GetWidgetMeta]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/15/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetWidgetMeta]
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@isEmbeddableSample bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if @isEmbeddableSample = 0
	begin
		select * from
		(
			select [key],value
			from PageEmbeddableMeta (nolock)
			where instanceId = @instanceId
			
			union all
			
			select 'title' as [key], title as value
			from PageEmbeddables (nolock)
			where instanceId = @instanceId
		) alias
	end
	else
	begin
		select * from
		(
			select [key],value
			from EmbeddableMeta (nolock)
			where embeddableId = @instanceId
			
			union all
			
			select 'title' as [key], name as value
			from EmbeddableSamples (nolock)
			where EmbeddableSamples.embeddableId = @instanceId
		) alias
	end
END
GO
GRANT EXECUTE ON [dbo].[GetWidgetMeta] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetWidgetMeta] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetWidgetMeta] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetWidgetMeta] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[DeleteEmbeddableSample]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteEmbeddableSample]
	-- Add the parameters for the stored procedure here
	@embeddableId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @baseEmbeddableId int
	declare @result bit
	begin try
	begin tran
	--get @baseEmbeddableId
	select @baseEmbeddableId = fromEmbeddableId
	from EmbeddableSamples
	where embeddableId = @embeddableId
	
	--delete embeddable sample
	delete from EmbeddableSamples
	where embeddableId = @embeddableId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
		
	--delete metadata
	delete from EmbeddableMeta
	where embeddableId = @embeddableId 
	
	--if any widget created from this sample embeddable,
	--we'll update embeddableIds of them back to root embeddable
	update PageEmbeddables  with(rowlock,updlock)
	set embeddableId = @baseEmbeddableId
	where embeddableId = @embeddableId
	
	update PageEmbeddableTemps  with(rowlock,updlock)
	set embeddableId = @baseEmbeddableId
	where embeddableId = @embeddableId
	
	update PageEmbeddableHistories  with(rowlock,updlock)
	set embeddableId = @baseEmbeddableId
	where embeddableId = @embeddableId
	commit tran
	set @result=cast(1 as bit)
	end try
	begin catch
	rollback tran
	print ERROR_MESSAGE()
	set @result=cast(0 as bit)
	end catch
	select @result
END
GO
GRANT EXECUTE ON [dbo].[DeleteEmbeddableSample] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteEmbeddableSample] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[GetWidgetPreviewMeta]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetWidgetPreviewMeta] 
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@isEmbeddableSample bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	if @isEmbeddableSample = 0
	begin
		select * from
		(
			select [key],value
			from PageEmbeddableMetaTemps (nolock)
			where instanceId = @instanceId
			
			union all
			
			select 'title' as [key], title as value
			from PageEmbeddableTemps (nolock)
			where instanceId = @instanceId
		) alias
	end
	else
	begin
		select * from
		(
			select [key],value
			from EmbeddableMeta (nolock)
			where embeddableId = @instanceId
			
			union all
			
			select 'title' as [key], name as value
			from EmbeddableSamples (nolock)
			where EmbeddableSamples.embeddableId = @instanceId
		) alias
	end
END
GO
GRANT EXECUTE ON [dbo].[GetWidgetPreviewMeta] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetWidgetPreviewMeta] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetWidgetPreviewMeta] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetWidgetPreviewMeta] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[GetSitesWithRequestApproveInfo]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSitesWithRequestApproveInfo]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select s.siteId, s.siteHost, s.siteName, st.requestApprove, st.requestApproveDate
	from Sites s
	left join SiteTemps st
	on s.siteId = st.siteId
	order by st.requestApprove desc
END

GO
GRANT EXECUTE ON [dbo].[GetSitesWithRequestApproveInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSitesWithRequestApproveInfo] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[UpdateHomePage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateHomePage]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@homePageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update SiteTemps  with(rowlock,updlock)
	set homePageId = @homePageId
	where siteId = @siteId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[UpdateHomePage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdateHomePage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateHomePage] TO [vnteam]
GO




/****** Object:  StoredProcedure [dbo].[RequestApprove]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RequestApprove] 
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update SiteTemps
	set requestApprove = 1, requestApproveDate = getdate()
	where siteId = @siteId
											
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[RequestApprove] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[RequestApprove] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestApprove] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[RejectChanges]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[RejectChanges]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update SiteTemps
   set	requestApprove = null,
		requestApproveDate = null
	where siteId = @siteId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[RejectChanges] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[RejectChanges] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[GetBasicSetting]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/12/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBasicSetting]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT siteName,siteTitle,siteHost,displayName,copyright
	FROM SiteTemps (nolock)
	WHERE siteId = @siteId
END
GO
GRANT EXECUTE ON [dbo].[GetBasicSetting] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetBasicSetting] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetBasicSetting] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetBasicSetting] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[UpdateBasicSetting]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/12/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateBasicSetting]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@siteName nvarchar(256),
	@siteTitle nvarchar(256),
	@siteHost nvarchar(256),
	@displayName nvarchar(256),
	@copyright nvarchar(4000)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	begin try
		update SiteTemps  with(rowlock,updlock)
		set
			siteName = @siteName,
			siteTitle = @siteTitle,
			siteHost = @siteHost,
			displayName = @displayName,
			copyright = @copyright
		where
			siteId = @siteId
			
		if @@rowcount <> 0
			select convert(bit,1)
		else
			select convert(bit,0)
	end try
	begin catch
		select convert(bit,0)
	end catch
END
GO
GRANT EXECUTE ON [dbo].[UpdateBasicSetting] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdateBasicSetting] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateBasicSetting] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[CopySiteFromMainToTemp]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CopySiteFromMainToTemp]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	if(not exists (select 1 from Sites (nolock) where SiteId=@siteId))
	begin
		--invalid SiteID
		select cast(0 as bit)
		return
	end
	if(exists (select 1 from SiteTemps (nolock) where SiteId=@siteId))
	begin
		--already copied
		select cast(1 as bit)
		return
	end
	
   begin try
   begin tran 
	--TODO:
	--Sites -> SiteTemps 
	INSERT INTO [dbo].[SiteTemps]
		   ([siteId]
		   ,[siteName]
		   ,[siteHost]
		   ,[siteTitle]
		   ,[displayName]
		   ,[copyright]
		   ,[currentRevision]
		   ,[bodyLayoutId]
		   ,[footerLayoutId]
		   ,[homePageId])
	SELECT [siteId]
	  ,[siteName]
	  ,[siteHost]
	  ,[siteTitle]
	  ,[displayName]
	  ,[copyright]
	  ,[currentRevision] 
	  ,[bodyLayoutId]
	  ,[footerLayoutId]
	  ,[homePageId]
  FROM [dbo].[Sites] (nolock)
  where   siteId=@siteId         
	--SiteMeta -> SiteMetaTemps
	INSERT INTO [dbo].[SiteMetaTemps]
		   ([siteId]
		   ,[key]
		   ,[value])
	  SELECT [siteId]
	  ,[key]
	  ,[value]
	  FROM [dbo].[SiteMeta] (nolock)
	  where   siteId=@siteId     
	--Menu -> MenuTemps
	set identity_insert [dbo].[MenuTemps] on
	INSERT INTO [dbo].[MenuTemps]
		   ([menuId],
		   [siteId]
		   ,[parentId]
		   ,[level]
		   ,[orderNo]
		   ,[name]
		   ,[link]
		   ,[pageId])
	  SELECT [menuId]
	  ,[siteId]
	  ,[parentId]
	  ,[level]
	  ,[orderNo]
	  ,[name]
	  ,[link]
	  ,[pageId]
	 FROM [dbo].[Menu]  (nolock)
	  where   siteId=@siteId  
	set identity_insert [dbo].[MenuTemps] off    
	--Pages -> PageTemps
	INSERT INTO [dbo].[PageTemps]
		   ([pageId]
		   ,[siteId]
		   ,[url]
		   ,[title]
		   ,[masterId]
		   ,[enable]
		   ,[createdDate]
		   ,[updatedDate])
	   SELECT [pageId]
	  ,[siteId]
	  ,[url]
	  ,[title]
	  ,[masterId]
	  ,[enable]
	  ,[createdDate]
	  ,[updatedDate]
	FROM [dbo].[Pages] (nolock)
	 where   siteId=@siteId    
	--PageEmbeddables -> PageEmbeddableTemps
	set identity_insert [dbo].[PageEmbeddableTemps] on
	INSERT INTO [dbo].[PageEmbeddableTemps]
		   ([instanceId]
		   ,[pageId]
		   ,[bucket]
		   ,[embeddableId]
		   ,[title]
		   ,[status]
		   ,[orderNo])
	 SELECT pe.[instanceId]
	  ,pe.[pageId]
	  ,pe.[bucket]
	  ,pe.[embeddableId]
	  ,pe.[title]
	  ,pe.[status]
	  ,pe.[orderNo]
  FROM [dbo].[PageEmbeddables] pe (nolock)      
	   inner join Pages p (nolock) on p.pageid=pe.pageId
  where p.siteId=@siteId       
  set identity_insert [dbo].[PageEmbeddableTemps] off
   --PageEmbeddableMeta -> PageEmbeddableMetaTemps
	INSERT INTO [dbo].[PageEmbeddableMetaTemps]
		   ([instanceId]
		   ,[key]
		   ,[value])
	SELECT pm.[instanceId]
	  ,pm.[key]
	  ,pm.[value]
  FROM [dbo].[PageEmbeddableMeta] pm (nolock)  
	  inner join dbo.PageEmbeddables pe (nolock) on pe.instanceId=pm.instanceId
	   inner join Pages p (nolock) on p.pageid=pe.pageId
   where p.siteId=@siteId    
   commit tran
   end try
   begin catch
	rollback tran
	print ERROR_MESSAGE()
	select cast(0 as bit)
	return
   end catch   
	-- return
	select cast(1 as bit)
END
GO
GRANT EXECUTE ON [dbo].[CopySiteFromMainToTemp] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[CopySiteFromMainToTemp] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CopySiteFromMainToTemp] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[MoveUpMenu]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Update date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MoveUpMenu]
	-- Add the parameters for the stored procedure here
	@menuId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @siteId int
	declare @orderNo int
	declare @parentId int
	
	select @siteId = siteId, @orderNo = orderNo, @parentId = parentId
	from MenuTemps (nolock)
	where menuId = @menuId
	begin try
	begin tran
	if @orderNo > 0
	begin
	
		update MenuTemps with(rowlock,updlock)
		set orderNo = orderNo + 1
		where siteId = @siteId and parentId = @parentId and orderNo = (@orderNo - 1)
		
		update MenuTemps with(rowlock,updlock)
		set orderNo = orderNo - 1
		where menuId = @menuId
	end
	commit tran
	end try
	begin catch
	  rollback tran
	  print ERROR_MESSAGE()      
	end catch
END
GO
GRANT EXECUTE ON [dbo].[MoveUpMenu] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[MoveUpMenu] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveUpMenu] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[MoveDownMenu]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Update date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MoveDownMenu]
	-- Add the parameters for the stored procedure here
	@menuId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @siteId int
	declare @orderNo int
	declare @parentId int
	
	select @siteId = siteId, @orderNo = orderNo, @parentId = parentId
	from MenuTemps (nolock)
	where menuId = @menuId
	begin try
	begin tran
	update MenuTemps with(rowlock,updlock)
	set orderNo = orderNo - 1
	where siteId = @siteId and parentId = @parentId and orderNo = (@orderNo + 1)
	
	if @@rowcount <> 0
	begin
		update MenuTemps with (rowlock,updlock)
		set orderNo = orderNo + 1
		where menuId = @menuId
	end
	   commit tran
	end try
	begin catch
	  rollback tran
	  print ERROR_MESSAGE()      
	end catch	
		
	
END
GO
GRANT EXECUTE ON [dbo].[MoveDownMenu] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[MoveDownMenu] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[MoveDownMenu] TO [vnteam]
GO




/****** Object:  StoredProcedure [dbo].[DeleteMenu]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteMenu]
	-- Add the parameters for the stored procedure here
	@menuId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @siteId int
	declare @level int
	declare @orderNo int
	declare @result bit
	
	select @siteId = siteId,@level =[level],@orderNo = orderNo
	from MenuTemps (nolock)
	where menuId = @menuId
	begin try
	begin tran
	--delete
	delete from MenuTemps
	where menuId = @menuId
	
	set @result = cast(@@rowcount as bit)
	
	--update orderNo
	update MenuTemps with (rowlock,updlock)
	set orderNo = orderNo - 1
	where siteId = @siteId and [level] = @level and orderNo > @orderNo
	  commit tran
	  set @result=cast(1 as bit)
	end try
	begin catch
	  rollback tran
	  print ERROR_MESSAGE()   
	  set @result=cast(0 as bit)   
	end catch	
		
	select @result
END
GO
GRANT EXECUTE ON [dbo].[DeleteMenu] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[DeleteMenu] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteMenu] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[GetMenusPreview]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/06/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMenusPreview]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT		MenuTemps.*, PageTemps.title, PageTemps.url
	FROM		MenuTemps (nolock) 
	LEFT JOIN	PageTemps (nolock) ON MenuTemps.pageId = PageTemps.pageId
	WHERE		MenuTemps.siteId = @siteId
	ORDER BY	MenuTemps.parentId, MenuTemps.[level], MenuTemps.orderNo
END
GO
GRANT EXECUTE ON [dbo].[GetMenusPreview] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetMenusPreview] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetMenusPreview] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMenusPreview] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[UpdatePage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdatePage]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier,
	@title nvarchar(256),
	@url nvarchar(256),
	@masterId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	if @masterId = '00000000-0000-0000-0000-000000000000'
	begin
		set @masterId = null
	end
begin try	
 begin tran
	-- Insert statements for procedure here
	update PageTemps  with(rowlock,updlock)
	set title = @title,
	--url = @url,
	masterId = @masterId
	where pageId = @pageId
	
	
		
	--check url
	declare @oldPageId uniqueidentifier
	select top 1 @oldPageId = pageId
	from PageTemps (nolock)
	where pageId = @pageId and url = @url
	
	if @oldPageId = @pageId or @oldPageId is null
	begin
		update PageTemps  with(rowlock,updlock)
		set title = @title,
		url = @url,
		masterId = @masterId,
		updatedDate = getdate()
		where pageId = @pageId
	end
	else
	--can't update url cause' duplicate
	begin
		update PageTemps  with(rowlock,updlock)
		set title = @title,
		masterId = @masterId,
		updatedDate = getdate()
		where pageId = @pageId
	end
	commit tran
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
		
 end try
 begin catch
	rollback tran
	print ERROR_MESSAGE()
	select convert(bit,0)
 end catch		
	
END
GO
GRANT EXECUTE ON [dbo].[UpdatePage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdatePage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdatePage] TO [vnteam]
GO




/****** Object:  StoredProcedure [dbo].[ToggleEnablePage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ToggleEnablePage] 
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update PageTemps  with(rowlock,updlock)
	set [enable] = ~[enable]
	where pageId = @pageId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[ToggleEnablePage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[ToggleEnablePage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[ToggleEnablePage] TO [vnteam]
GO




/****** Object:  StoredProcedure [dbo].[GetPages]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPages]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select * 
	from PageTemps (nolock)
	where siteId = @siteId
	order by title asc
END
GO
GRANT EXECUTE ON [dbo].[GetPages] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetPages] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPages] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPages] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[InsertPage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/19/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertPage]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@title nvarchar(150),
	@url nvarchar(256),
	@masterId uniqueidentifier,
	@enable bit
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @pageId uniqueidentifier
	set @pageId = newid()
	
	
	-- Insert statements for procedure here
	begin try
		insert into PageTemps(pageId,siteId,url,title,masterId,[enable],createdDate,updatedDate)
		values(@pageId,@siteId,@url,@title,@masterId,@enable,getdate(),getdate())
		
		if @@ERROR <> 0
			--return emty guid
			select cast(cast(0 as binary) as uniqueidentifier)
		else
			select	@pageId
		
	end try
	begin catch
		--duplicate url contraint
		select cast(cast(0 as binary) as uniqueidentifier)
	end catch	
END
GO
GRANT EXECUTE ON [dbo].[InsertPage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertPage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertPage] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[GetPagePreviewByPageId]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPagePreviewByPageId]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select *
	from PageTemps (nolock)
	where pageId = @pageId
END
GO
/****** Object:  StoredProcedure [dbo].[GetPagePreviewByUrl]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPagePreviewByUrl]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@url nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select *
	from PageTemps (nolock)
	where siteId = @siteId and url = @url
END
GO
GRANT EXECUTE ON [dbo].[GetPagePreviewByPageId] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetPagePreviewByPageId] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPagePreviewByPageId] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPagePreviewByPageId] TO [vnteam]
GO



/****** Object:  StoredProcedure [dbo].[CheckWidgetBelongToSite]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CheckWidgetBelongToSite]
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result int
	-- Insert statements for procedure here
	select @result = PageEmbeddableTemps.instanceId
	from PageEmbeddableTemps (nolock)
	inner join PageTemps (nolock) on PageEmbeddableTemps.pageId = PageTemps.pageId
	where instanceId = @instanceId and PageTemps.siteId = @siteId
	
	if @result is null
		select cast(0 as bit)
	else
		select cast(1 as bit)
END
GO
GRANT EXECUTE ON [dbo].[CheckWidgetBelongToSite] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[CheckWidgetBelongToSite] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[CheckWidgetBelongToSite] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CheckWidgetBelongToSite] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[DeleteTermRelationship]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteTermRelationship]
	-- Add the parameters for the stored procedure here
	@objectId int,
	@taxonomyId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	begin try
	begin tran
	-- Insert statements for procedure here
	delete from TermRelationships
	where objectId = @objectId and taxonomyId = @taxonomyId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
		
	--update taxonomy COUNT
	update Taxonomy  with (rowlock,updlock)
	set [count] = [count] - 1
	where taxonomyId = @taxonomyId
	commit tran
	set @result=cast(1 as bit)
	end try
	begin catch
		rollback tran
		print ERROR_MESSAGE()
		set @result=cast(0 as bit)
	end catch
	select @result
END
GO
GRANT EXECUTE ON [dbo].[DeleteTermRelationship] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[DeleteTermRelationship] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteTermRelationship] TO [vnteam]
GO






/****** Object:  StoredProcedure [dbo].[GetTermsOfPost]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetTermsOfPost] 
	-- Add the parameters for the stored procedure here
	@postId int,
	@taxonomy nvarchar(32)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Terms.termId, Terms.name, Taxonomy.taxonomyId
	from Terms (nolock)
	inner join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	inner join TermRelationships(nolock) on Taxonomy.taxonomyId = TermRelationships.taxonomyId
	where	TermRelationships.objectId = @postId
			and Taxonomy.name = @taxonomy
END
GO
GRANT EXECUTE ON [dbo].[GetTermsOfPost] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetTermsOfPost] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetTermsOfPost] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetTermsOfPost] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[InsertTag]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertTag]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@name nvarchar(256),
	@slug nvarchar(256),
	@postId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @termId int
	declare @taxonomyId int
	declare @oldName nvarchar(256)
	declare @result bit
	
	-- Insert term with taxonomy	
	begin try
	begin tran	
	select @oldName = name, @termId = termId from Terms
	where siteId = @siteId and name = @name
	--exactly: CONVERT(varbinary(256), name) = CONVERT(varbinary(256), @name)
	
	if @oldName = @name
		begin
			--duplicate term name
			--get taxonomyId
			select @taxonomyId = taxonomyId
			from Taxonomy (nolock)
			where termId = @termId
			
			set @result = convert(bit,1)
		end
	else
		begin
			
			--still don't have this tag in system
			--add new tag
			insert into Terms(siteId,name,slug)
			values(@siteId,@name,@slug)

			if @@error <> 0
				begin
					set @result = convert(bit,0)
				end
			else
				begin
					set @result = convert(bit,1)
					
					set @termId = cast(scope_identity() as int)
					
					insert into Taxonomy(termId,name,parentId,[count])
					values(@termId,'post_tag',0,0)
					
					set @taxonomyId = cast(scope_identity() as int)
					
				end
		end
	--end insert term with taxonomy
	
	--insert term relationship
	
	declare @objectId int
	
	select  @objectId = objectId 
	from TermRelationships (nolock)
	where objectId = @postId and taxonomyId = @taxonomyId

	if @objectId is null
	begin
		insert into TermRelationships(objectId,taxonomyId,orderNo)
		values(@postId,@taxonomyId,0)
	end
	
	--update Taxonomy.Count
	update Taxonomy with (rowlock,updlock)
	set [count] = [count] + 1
	where taxonomyId = @taxonomyId
	commit tran
	set @result=cast(1 as bit)
	end try
	begin catch
		rollback tran
		print ERROR_MESSAGE()
		set @result=cast(0 as bit)
	end catch
	select @result
END
GO
GRANT EXECUTE ON [dbo].[InsertTag] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertTag] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertTag] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[InsertTermWithTaxonomy]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/16/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertTermWithTaxonomy] 
	-- Add the parameters for the stored procedure here
	@siteId int,
	@name nvarchar(256),
	@slug nvarchar(256),
	@taxonomy nvarchar(32),
	@count int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @termId int
	declare @oldName nvarchar(256)
	-- Insert statements for procedure here
	
	select @oldName = name
	from Terms (nolock)
	where siteId = @siteId and name = @name
	--exactly: CONVERT(varbinary(256), name) = CONVERT(varbinary(256), @name)
	
	if @oldName = @name
		begin
			--duplicate term name
			select -11
		end
	else
		begin
		
			insert into Terms(siteId,name,slug)
			values(@siteId,@name,@slug)
			
			
			
			if @@error <> 0
				begin
					select 0
				end
			else
				begin
					set @termId = cast(scope_identity() as int)
					insert into Taxonomy(termId,name,parentId,[count])
					values(@termId,@taxonomy,0,@count)
					
					select @termId
				end
		end
END
GO
GRANT EXECUTE ON [dbo].[InsertTermWithTaxonomy] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertTermWithTaxonomy] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertTermWithTaxonomy] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[UpdateTermLanguage]    Script Date: 11/12/2010 15:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/04/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateTermLanguage] 
	-- Add the parameters for the stored procedure here
	@termId int,
	@languageCode nvarchar(10),
	@term nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	update TermLanguages
	set term = @term
	where termId = @termId and languageCode = @languageCode
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
	begin
		insert into TermLanguages(termId,languageCode,term)
		values(@termId,@languageCode,@term)
		
		IF @@ERROR <> 0
			SELECT convert(bit,0)
		ELSE
			SELECT convert(bit,1)
	end
END
GO
GRANT EXECUTE ON [dbo].[UpdateTermLanguage] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[UpdateTermLanguage] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateTermLanguage] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetLanguages]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetLanguages]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select * from Languages (nolock)
END
GO
GRANT VIEW DEFINITION ON [dbo].[GetLanguages] TO [VNTeam]
GO
GRANT EXECUTE ON [dbo].[GetLanguages] TO [bodbAdminNet]


/****** Object:  StoredProcedure [dbo].[InsertLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertLanguage]
	-- Add the parameters for the stored procedure here
	@code nvarchar(50),
	@name nvarchar(64),
	@enable bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	insert into Languages(code, name, enable)
	values(@code, @name, @enable)
	if @@error <>0
		select 0
	else
		select cast(scope_identity() as int)
END
GO
GRANT EXECUTE ON [dbo].[UpdateTermLanguage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateTermLanguage] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/06/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select *
	from Languages (nolock)
	where languageId = @languageId
END

GO
GRANT EXECUTE ON [dbo].[GetLanguage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetLanguages] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[ToggleEnableLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ToggleEnableLanguage]
	-- Add the parameters for the stored procedure here
	@languageId int,
	@enable bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update Languages  with(rowlock,updlock)
	set [enable] = ~[enable]
	where languageId = @languageId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[ToggleEnableLanguage] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[ToggleEnableLanguage] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[ToggleEnableLanguage] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[CheckHasSite]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/19/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CheckHasSite]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Insert statements for procedure here
	select @siteId = siteId
	from Sites (nolock)
	where siteId = @siteId
	
	select cast(@@rowcount as bit)
END
GO
GRANT EXECUTE ON [dbo].[CheckHasSite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[CheckHasSite] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[CheckHasSite] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[CheckHasSite] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[InsertSite]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/19/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertSite]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@siteName nvarchar(256),
	@siteTitle nvarchar(256),
	@siteHost nvarchar(256),
	@displayName nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @oldSiteHost nvarchar(256)
	declare @result int
	declare @trueSiteId int
	
	select @oldSiteHost = siteHost
	from Sites
	where siteHost = @siteHost
	
	if @oldSiteHost = @siteHost and @siteId > 0
		begin
			--duplicate site host(subdomain)
			select -11
		end
	else
		begin
			if @siteId <> 0
			--insert site at setup step 01
			begin
				set @trueSiteId = @siteId
			end
			else
			--insert site template
			begin
				set @trueSiteId  =	(select isnull(min(siteId) - 1,-1)
									from Sites (nolock)
									where siteId < 0)
				set @siteHost = convert(nvarchar,@trueSiteId)
			end
			
			--insert site
			begin try

				--default layout:
				--bodyLayoutId   = 3 (Two columns with right panel)
				--footerLayoutId = 5 (One column footer)
				--copyright
				declare @copyright nvarchar(4000)
				set @copyright = 'Copyright &copy; by ' + @displayName
				
				insert into Sites(siteId,siteName,siteHost,siteTitle,displayName,copyright,currentRevision,bodyLayoutId,footerLayoutId,homePageId)
				values(@trueSiteId,@siteName,@siteHost,@siteTitle,@displayName,@copyright,0,3,5,'00000000-0000-0000-0000-000000000000')
				
				if @@rowcount <> 0
					set @result = @trueSiteId
				else
					set @result = 0
				
				--create default home page for user
				--insert into Pages(pageId,siteId,url,title,masterId,[enable],createdDate,updatedDate)
				--values(newid(),@siteId,'home','Home',null,1,getdate(),getdate())
				
				--insert default sitemeta
				--site with
				--insert into SiteMeta(siteId,[key],value)
				--values(@trueSiteId,'sitewidth',1000)
				--left with
				--insert into SiteMeta(siteId,[key],value)
				--values(@trueSiteId,'leftwidth',250)
				--right with
				--insert into SiteMeta(siteId,[key],value)
				--values(@trueSiteId,'rightwidth',250)
				
			end try
			
			begin catch
				select convert(int,0)
			end catch
			
			
			select @result
		end
END
GO
GRANT EXECUTE ON [dbo].[InsertSite]TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[InsertSite]TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertSite] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[CheckDoneSite]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CheckDoneSite] 
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select @siteId = siteId
	from Sites (nolock)
	where siteId = @siteId and homePageId <> '00000000-0000-0000-0000-000000000000'
	
	select cast(@@rowcount as bit)
END

GO
GRANT EXECUTE ON [dbo].[CheckDoneSite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[CheckDoneSite] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[CheckDoneSite] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[CheckDoneSite] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[CheckSiteIsValid]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CheckSiteIsValid]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select @siteId = siteId
	from Sites (nolock)
	where siteId = @siteId and homePageId <> '00000000-0000-0000-0000-000000000000'
	
	select cast(@@rowcount as bit)
END
GO
GRANT EXECUTE ON [dbo].[CheckSiteIsValid] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[CheckSiteIsValid] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[CheckSiteIsValid] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[CheckSiteIsValid] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[UpdateSite]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/06/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateSite]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@siteName nvarchar(256),
	@siteHost nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update Sites  with(rowlock,updlock)
	set siteName = @siteName, siteHost = @siteHost
	where siteId = @siteId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[UpdateSite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[UpdateSite] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateSite] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[CopySiteFromTempToMain]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CopySiteFromTempToMain]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	if(not exists (select 1 from SiteTemps (nolock) where SiteId=@siteId) 
		or not exists (select 1 from Sites (nolock) where SiteId=@siteId)
		)
	begin
		--invalid SiteID
		print 'invalid SiteID'
		select cast(0 as bit)
		return
	end
	--check the main version is backup?
	if (not exists (select 1 
					from Sites s(nolock)
					inner join SiteHistories sh (nolock) on sh.siteId=s.siteId and sh.versionId=s.currentRevision 
					 where s.siteId=@siteId
					)
		)			
	begin	
		/* print 'not backup site yet'
		 select cast(0 as bit)
		 return*/
		 exec dbo.CopySiteFromMainToHistory @SiteId=@SiteId
		 
	end
	--delete all data on main version
	Begin Try
		Begin Transaction
		
		delete Sites where siteId=@siteId
		delete SiteMeta where siteId=@siteId
		delete Menu where siteId=@siteId	
		
		delete pm
		from PageEmbeddableMeta pm	 
			inner join PageEmbeddables pe (nolock) on pe.instanceId=pm.instanceId
			inner join Pages p (nolock) on p.pageId=pe.pageId
		where p.siteId=@siteId
		
		delete pe
		from PageEmbeddables pe
			inner join Pages p (nolock) on p.pageId=pe.pageId
		where p.siteId=@siteId
		
		delete Pages where siteId=@siteId
		
		
		--create new version on table Sites and SiteVersions
		INSERT INTO [SiteVersions]
			   ([versionId]
			   ,[siteId]
			   ,[timestamp])
		 select (select [currentRevision] + 1 from SiteTemps(nolock) where siteId=@siteId)
				,@siteId      
				,current_timestamp
			   
		--TODO:
		--SiteTemps ->  Sites
		INSERT INTO [dbo].[Sites]
			   ([siteId]
			   ,[siteName]
			   ,[siteHost]
			   ,[siteTitle]
			   ,[displayName]
			   ,[copyright]
			   ,[currentRevision]
			   ,[bodyLayoutId]
			   ,[footerLayoutId]
			   ,[homePageId])
		SELECT [siteId]
		  ,[siteName]
		  ,[siteHost]
		  ,[siteTitle]
		  ,[displayName]
		  ,[copyright]
		  ,[currentRevision] + 1
		  ,[bodyLayoutId]
		  ,[footerLayoutId]
		  ,[homePageId]
	  FROM [dbo].[SiteTemps] (nolock)
	  where   siteId=@siteId         
		--SiteMetaTemps -> SiteMeta
		INSERT INTO [dbo].[SiteMeta]
			   ([siteId]
			   ,[key]
			   ,[value])
		  SELECT [siteId]
		  ,[key]
		  ,[value]
		  FROM [dbo].[SiteMetaTemps] (nolock)
		  where   siteId=@siteId     
		--MenuTemps -> Menu
		set identity_insert [dbo].[Menu] on
		INSERT INTO [dbo].[Menu]
			   ([menuId],
			   [siteId]
			   ,[parentId]
			   ,[level]
			   ,[orderNo]
			   ,[name]
			   ,[link]
			   ,[pageId])
		  SELECT [menuId]
		  ,[siteId]
		  ,[parentId]
		  ,[level]
		  ,[orderNo]
		  ,[name]
		  ,[link]
		  ,[pageId]
		 FROM [dbo].[MenuTemps]  (nolock)
		  where   siteId=@siteId  
		set identity_insert [dbo].[Menu] off    
		--PageTemps -> Pages
		INSERT INTO [dbo].[Pages]
			   ([pageId]
			   ,[siteId]
			   ,[url]
			   ,[title]
			   ,[masterId]
			   ,[enable]
			   ,[createdDate]
			   ,[updatedDate])
		   SELECT [pageId]
		  ,[siteId]
		  ,[url]
		  ,[title]
		  ,[masterId]
		  ,[enable]
		  ,[createdDate]
		  ,[updatedDate]
		FROM [dbo].[PageTemps] (nolock)
		 where   siteId=@siteId    
		--PageEmbeddableTemps -> PageEmbeddables
		set identity_insert [dbo].[PageEmbeddables] on
		INSERT INTO [dbo].[PageEmbeddables]
			   ([instanceId]
			   ,[pageId]
			   ,[bucket]
			   ,[embeddableId]
			   ,[title]
			   ,[status]
			   ,[orderNo])
		 SELECT pe.[instanceId]
		  ,pe.[pageId]
		  ,pe.[bucket]
		  ,pe.[embeddableId]
		  ,pe.[title]
		  ,pe.[status]
		  ,pe.[orderNo]
	  FROM [dbo].[PageEmbeddableTemps] pe (nolock)      
		   inner join PageTemps p (nolock) on p.pageid=pe.pageId
	  where p.siteId=@siteId       
	  set identity_insert [dbo].[PageEmbeddables] off
	   --PageEmbeddableMetaTemps -> PageEmbeddableMeta
		INSERT INTO [dbo].[PageEmbeddableMeta]
			   ([instanceId]
			   ,[key]
			   ,[value])
		SELECT pm.[instanceId]
		  ,pm.[key]
		  ,pm.[value]
	  FROM [dbo].[PageEmbeddableMetaTemps] pm (nolock)  
		  inner join dbo.PageEmbeddableTemps pe (nolock) on pe.instanceId=pm.instanceId
		   inner join PageTemps p (nolock) on p.pageid=pe.pageId
	   where p.siteId=@siteId     
	   
	   --update request changes in SiteVersions
	   update SiteTemps
	   set	requestApprove = null,
			requestApproveDate = null
		where siteId = @siteId
		
		-- update new version in SiteTemps
		
		update SiteTemps with(rowlock,updlock)
		set [currentRevision]=[currentRevision] + 1
		where siteId = @siteId
		
		Commit Transaction
	End Try
	Begin Catch	
		Rollback Transaction		
		print ERROR_MESSAGE()
		select cast(0 as bit)
		 return
	end catch
	-- return
	select cast(1 as bit)
END

GO
GRANT EXECUTE ON [dbo].[CopySiteFromTempToMain] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[CopySiteFromTempToMain] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CopySiteFromTempToMain] TO [VNTeam]


/****** Object:  StoredProcedure [dbo].[InsertMenu]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/01/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertMenu]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@parentId int,
	@level int,
	@name nvarchar(256),
	@link nvarchar(256),
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--get maxOrderNo
	declare @maxOrderNo int
	set @maxOrderNo = dbo.GetMaxMenuOrderNo(@siteId, @parentId, @level) + 1
	
	if @pageId = '00000000-0000-0000-0000-000000000000'
	begin
		set @pageId = null
	end
	
	-- Insert statements for procedure here
	INSERT INTO		MenuTemps(siteId,parentId, level,orderNo, name, link, pageId)
	VALUES(@siteId,@parentId, @level,@maxOrderNo, @name, @link, @pageId)
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END

GO
GRANT EXECUTE ON [dbo].[InsertMenu] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[InsertMenu] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertMenu] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[UpdateMenu]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateMenu]
	-- Add the parameters for the stored procedure here
	@menuId int,
	@parentId int,
	@name nvarchar(256),
	@link nvarchar(256),
	@pageId uniqueidentifier
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
	declare @newLink nvarchar(256)
	declare @siteId int
	declare @oldParentId int
	declare @oldLevel int
	declare @result bit
	declare @orderNo int
	
	--get old values
	select	@siteId = siteId, 
			@oldParentId = parentId, 
			@oldLevel = [level],
			@orderNo = orderNo
	from MenuTemps (nolock)
	where menuId = @menuId
	
	--prepare to update menu
	if @pageid is not null and @pageid <> '00000000-0000-0000-0000-000000000000'
		set @newLink = ''
	else 
	begin
		set @newLink = @link
		set @pageId = null
	end
	
	Begin Try
	
		Begin Transaction
		
		--update menu
		update MenuTemps  with(rowlock,updlock)
		set		name = @name,
				pageId = @pageId,
				link = @newLink	
		where menuId = @menuId
		
		if @@rowcount <> 0
			set @result = convert(bit,1)
		else
			set @result = convert(bit,0)
		
		
		--update parentId
		
		--IsChildMenu(siteId, me, menuId)
		-- check if menuId is the child of me
		if dbo.IsChildMenu(@siteId,@menuId,@parentId) = 0
		begin 
			--the new parent isn't my child/sub-child..., 
			--so feel free to UPDATE!!!
			declare @parentLevel int
			select @parentLevel = [level]
			from MenuTemps (nolock)
			where menuId = @parentId
			
			if @parentLevel is null
				set @parentLevel = -1
			
			update MenuTemps  with(rowlock,updlock)
			set		parentId = @parentId,
					[level] = @parentLevel + 1,
					orderNo = -1
			where menuId = @menuId
			
			--reorder old branch
			if @oldLevel <> @parentLevel + 1
			begin
				update MenuTemps  with(rowlock,updlock)
				--move this menu to the buttom of the new branch
				set	orderNo = [dbo].[GetMaxMenuOrderNo] (@siteId, @parentId,@parentLevel + 1) + 1
				where menuId = @menuId
				
				update MenuTemps  with(rowlock,updlock)
				set orderNo = orderNo - 1
				where siteId = @siteId and parentId = @oldParentId and orderNo > @orderNo
			end
			
			--reorder new branch: nothing to do cause' we move to the bottom
			--of the new branch
			
			--update child nodes of current menu
			--childs.level = child.level + 1
			--TODO:
			--1. get all child menu
			--2. update level = level +/- 1
			
			declare @levelAmount int
			if(@oldLevel < @parentLevel + 1)
				set @levelAmount = 1
			else
				set @levelAmount = -1
			
			
			declare @childTable table(menuId int)
			insert into @childTable(menuId)
			select menuId 
			from MenuTemps (nolock) 
			where	siteId = @siteId and
					menuId <> @menuId and
					dbo.IsChildMenu(@siteId,@menuId,menuId) = 1
			
			--update level = level +/- 1
			update MenuTemps  with(rowlock,updlock)
			set [level] = [level] + @levelAmount
			where menuId in (select menuId from @childTable)
			
		end
		Commit Transaction
	End Try
	Begin Catch		
		Rollback Transaction 
		print ERROR_MESSAGE()
		select @result = convert(bit,0)
		return		
	End Catch
	--else
		--the new parent is my child/sub-child...
		--your son can't be your parent, so do NOTHING!!!
	
	--return
	select @result
END

GO
GRANT EXECUTE ON [dbo].[UpdateMenu] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[UpdateMenu] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMenu] TO [VNTeam]



/****** Object:  StoredProcedure [dbo].[MarkMessageAsRead]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/11/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MarkMessageAsRead]
	-- Add the parameters for the stored procedure here
	@messageId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update [Messages]
	set isRead = 1
	where messageId = @messageId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[MarkMessageAsRead] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[MarkMessageAsRead] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[MarkMessageAsRead] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetMessages]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/11/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMessages]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@pageNumber int,
	@pageSize int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select messageId,title,content,createdDate,isRead
	from [Messages]
	where toSiteId = @siteId and isDeleted = 0
	order by createdDate desc
END
GO
GRANT EXECUTE ON [dbo].[GetMessages] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetMessages] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetMessages] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMessages] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[MarkMessageAsDeleted]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/11/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[MarkMessageAsDeleted]
	-- Add the parameters for the stored procedure here
	@messageId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update [Messages]
	set isDeleted = 1
	where messageId = @messageId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[MarkMessageAsDeleted] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[MarkMessageAsDeleted] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[MarkMessageAsDeleted] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetMenus]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/01/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMenus] 
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT		Menu.*, Pages.title, Pages.url
	FROM		Menu (nolock) 
	LEFT JOIN	Pages (nolock) ON Menu.pageId = Pages.pageId
	WHERE		Menu.siteId = @siteId
	ORDER BY	Menu.parentId, Menu.[level], Menu.orderNo
END
GO
GRANT EXECUTE ON [dbo].[GetMenus] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetMenus] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetMenus] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMenus] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetMenu]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMenu]
	-- Add the parameters for the stored procedure here
	@menuId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT		Menu.*, Pages.title, Pages.url
	FROM		Menu (nolock)
	LEFT JOIN Pages (nolock) ON Menu.pageId = Pages.pageId
	WHERE		Menu.menuId = @menuId
END
GO
GRANT EXECUTE ON [dbo].[GetMenu] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetMenu] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetMenu] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMenu] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetPageByPageId]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/07/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPageByPageId] 
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select *
	from Pages (nolock)
	where pageId = @pageId
END
GO
GRANT EXECUTE ON [dbo].[GetPageByPageId] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetPageByPageId] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPageByPageId] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPageByPageId] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetPageByUrl]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPageByUrl] 
	-- Add the parameters for the stored procedure here
	@siteId int,
	@url nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select *
	from Pages (nolock)
	where siteId = @siteId and url = @url
END
GO
GRANT EXECUTE ON [dbo].[GetPageByUrl] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetPageByUrl] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPageByUrl] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPageByUrl] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetWidgetsPreview]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/05/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetWidgetsPreview]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select * from
	(
		select PageEmbeddableTemps.*, Embeddables.name as embeddableName, Embeddables.editable as editable, cast(1 as bit) as deletable
		from PageEmbeddableTemps  (nolock)
		inner join Embeddables (nolock) on PageEmbeddableTemps.embeddableId = Embeddables.embeddableId
		
		union all
		
		select PageEmbeddableTemps.*, EmbeddableSamples.name as embeddableName, EmbeddableSamples.editable as editable, EmbeddableSamples.deletable
		from PageEmbeddableTemps  (nolock)
		inner join EmbeddableSamples (nolock) on PageEmbeddableTemps.embeddableId = EmbeddableSamples.embeddableId
	) alias

	where pageId = @pageId
	order by bucket desc, orderNo asc
END
GO
GRANT EXECUTE ON [dbo].[GetWidgetsPreview] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetWidgetsPreview] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetWidgetsPreview] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetWidgetsPreview] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetEmbeddables]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/12/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetEmbeddables]
	-- Add the parameters for the stored procedure here
	@isSystem bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
select * from
(

SELECT [embeddableId]
	  ,[fromEmbeddableId] as baseEmbeddable
	  ,[name]
	  ,[description]
	  ,[editable]
	  ,[deletable]
	  ,[enable]
  FROM [EmbeddableSamples] (nolock)
  --WHERE [enable] = 1 and [deletable] = 1
  
  union all
  
  SELECT  [embeddableId]
	  ,0 as baseEmbeddable
	  ,[name]
	  ,[description]
	  ,[editable]
	  ,cast(1 as bit) as deletable
	  ,[enable]     
  FROM [Embeddables] (nolock)
  WHERE [enable] = 1 and isSystem = @isSystem
  ) t
  order by name asc
END
GO
GRANT EXECUTE ON [dbo].[GetEmbeddables] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetEmbeddables] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetEmbeddables] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetEmbeddables] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[InsertEmbeddableSample]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertEmbeddableSample]
	-- Add the parameters for the stored procedure here
	@fromEmbeddableId int,
	@name nvarchar(256),
	@description nvarchar(1024),
	@editable bit,
	@deletable bit,
	@enable bit,
	@createdBy int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	insert into EmbeddableSamples(fromEmbeddableId,name,[description],editable,deletable,[enable],createdBy,createdDate)
	values(@fromEmbeddableId,@name,@description,@editable,@deletable,@enable,@createdBy,getdate())
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
GO
GRANT EXECUTE ON [dbo].[InsertEmbeddableSample] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertEmbeddableSample] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertEmbeddableSample] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetBaseEmbeddableId]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/11/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBaseEmbeddableId]
	-- Add the parameters for the stored procedure here
	@embeddableId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select fromEmbeddableId
	from EmbeddableSamples (nolock)
	where embeddableId = @embeddableId
END
GO
GRANT EXECUTE ON [dbo].[GetBaseEmbeddableId] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetBaseEmbeddableId] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetBaseEmbeddableId] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetBaseEmbeddableId] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetAllEmbeddableSamples]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetAllEmbeddableSamples]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select EmbeddableSamples.*, Embeddables.name as baseEmbeddable
	from EmbeddableSamples (nolock)
	inner join Embeddables (nolock)
	on EmbeddableSamples.fromEmbeddableId = Embeddables.embeddableId
END
GO
GRANT EXECUTE ON [dbo].[GetAllEmbeddableSamples] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetAllEmbeddableSamples] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetAllEmbeddableSamples] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetAllEmbeddableSamples] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetAllEmbeddables]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/21/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetAllEmbeddables] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT [embeddableId]
	  ,0 as baseEmbeddable
	  ,[name]
	  ,[description]
	  ,[editable]
	  ,cast(1 as bit) as deletable
	  ,[enable]
	FROM [Embeddables] (nolock)
	order by isSystem desc, name asc
END
GO
GRANT EXECUTE ON [dbo].[GetAllEmbeddables] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetAllEmbeddables] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetAllEmbeddables] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetAllEmbeddables] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetInstanableEmbeddables]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/21/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetInstanableEmbeddables]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here	
	SELECT [embeddableId]
	  ,0 as baseEmbeddable
	  ,[name]
	  ,[description]
	  ,[editable]
	  ,cast(1 as bit) as deletable
	  ,[enable]
  FROM [Embeddables] (nolock)
  WHERE isSystem = 0 and editable = 1
  
END
GO
GRANT EXECUTE ON [dbo].[GetInstanableEmbeddables] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetInstanableEmbeddables] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetInstanableEmbeddables] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstanableEmbeddables] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetWidgets]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetWidgets]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select PageEmbeddables.*, Embeddables.name as embeddableName, Embeddables.editable as editable, cast(1 as bit) as deletable
	from PageEmbeddables  (nolock)
	inner join Embeddables (nolock) on PageEmbeddables.embeddableId = Embeddables.embeddableId
	
	where pageId = @pageId
	order by bucket desc, orderNo asc
END
GO
GRANT EXECUTE ON [dbo].[GetWidgets] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetWidgets] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetWidgets] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetWidgets] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[DeleteWidget]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteWidget]
	-- Add the parameters for the stored procedure here
	@instanceId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	declare @pageId uniqueidentifier
	declare @bucket nvarchar(64)
	declare @orderNo int
	begin try
	begin tran
	-- Get current widget
	select @pageId = pageId, @bucket = bucket, @orderNo = orderNo
	from PageEmbeddableTemps (nolock)
	where  instanceId = @instanceId
	
	-- Insert statements for procedure here
	delete from PageEmbeddableTemps
	where instanceId = @instanceId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
	
	--update order
	if( @result = 1)
	begin
		update PageEmbeddableTemps  with (rowlock,updlock)
		set orderNo = orderNo - 1
		where pageId = @pageId and bucket = @bucket and orderNo > @orderNo
	end
	
	--delete related data
	delete from PageEmbeddableMetaTemps
	where instanceId = @instanceId
	commit tran
	set @result=cast(0 as bit)
	end try
	begin catch
		rollback tran
		print ERROR_MESSAGE()
		set @result=cast(0 as bit)
	end catch
	select @result
END
GO
GRANT EXECUTE ON [dbo].[DeleteWidget] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[DeleteWidget] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteWidget] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetPost]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/09/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPost]
	-- Add the parameters for the stored procedure here
	@postId int,
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	declare @numberCom int
	select @numberCom = count(1) 
	from comments with(nolock)
	where postid = @postId
	
	select *,@numberCom as commentNumber
	from Posts (nolock)
	where postId = @postId and siteId = @siteId and [type] = 0
END

GO
GRANT EXECUTE ON [dbo].[GetPost] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetPost] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPost] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPost] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[UpdatePost]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdatePost]
	-- Add the parameters for the stored procedure here
	@postId int,
	@title nvarchar(256),
	@description varchar(1024),
	@content varchar(MAX),
	@type tinyint,
	@status tinyint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update	Posts  with(rowlock,updlock)
	set		title =@title, 
			[description] = @description, 
			content = @content, 
			[type] = @type, 
			[status] = @status,
			updatedDate = getdate()
			
	where	postId = @postId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[UpdatePost] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdatePost] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdatePost] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[GetPostsBySiteId]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/26/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPostsBySiteId]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@pageNumber int,
	@pageSize int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @commentNumber int
	set @commentNumber = 0
	-- Insert statements for procedure here
	select *,@commentNumber as commentNumber 
	from Posts (nolock)
	where siteId = @siteId and [type] = 0
	order by postId desc
END
GO
GRANT EXECUTE ON [dbo].[GetPostsBySiteId] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[GetPostsBySiteId] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPostsBySiteId] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPostsBySiteId] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[UpdatePostStatus]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdatePostStatus]
	-- Add the parameters for the stored procedure here
	@postId int,
	@status tinyint
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	update Posts  with(rowlock,updlock)
	set [status] = @status
	where postId = @postId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[UpdatePostStatus] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[UpdatePostStatus] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdatePostStatus] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[InsertPost]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/07/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertPost]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@title nvarchar(256),
	@description nvarchar(1024),
	@content nvarchar(MAX),
	@type tinyint,
	@status tinyint,
	@parentId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	insert into Posts(siteId,title,[description],content,[type],[status],createdDate,updatedDate,parentId)
	values(@siteId,@title,@description,@content,@type,@status,getdate(),getdate(),@parentId)
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
GO
GRANT EXECUTE ON [dbo].[InsertPost] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertPost] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertPost] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[InsertTerm]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/08/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertTerm]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@name nvarchar(256),
	@slug nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	insert into Terms(siteId,name,slug)
	values(@siteId,@name,@slug)
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
GO
GRANT EXECUTE ON [dbo].[InsertTerm] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertTerm] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertTerm] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[ELMAH_GetErrorXml]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ELMAH_GetErrorXml]
(
	@Application NVARCHAR(60),
	@ErrorId UNIQUEIDENTIFIER
)
AS

	SET NOCOUNT ON

	SELECT 
		[AllXml]
	FROM 
		[ELMAH_Error] (nolock)
	WHERE
		[ErrorId] = @ErrorId
	AND
		[Application] = @Application
GO
/****** Object:  StoredProcedure [dbo].[ELMAH_LogError]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
GRANT EXECUTE ON [dbo].[ELMAH_GetErrorXml] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[ELMAH_GetErrorXml] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[ELMAH_GetErrorXml] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[ELMAH_GetErrorXml] TO [vnteam]
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ELMAH_LogError]
(
	@ErrorId UNIQUEIDENTIFIER,
	@Application NVARCHAR(60),
	@Host NVARCHAR(30),
	@Type NVARCHAR(100),
	@Source NVARCHAR(60),
	@Message NVARCHAR(500),
	@User NVARCHAR(50),
	@AllXml NTEXT,
	@StatusCode INT,
	@TimeUtc DATETIME
)
AS

	SET NOCOUNT ON

	INSERT
	INTO
		[ELMAH_Error]
		(
			[ErrorId],
			[Application],
			[Host],
			[Type],
			[Source],
			[Message],
			[User],
			[AllXml],
			[StatusCode],
			[TimeUtc]
		)
	VALUES
		(
			@ErrorId,
			@Application,
			@Host,
			@Type,
			@Source,
			@Message,
			@User,
			@AllXml,
			@StatusCode,
			@TimeUtc
		)
GO
GRANT EXECUTE ON [dbo].[ELMAH_LogError] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[ELMAH_LogError] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[ELMAH_LogError] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[ELMAH_LogError] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[ELMAH_GetErrorsXml]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ELMAH_GetErrorsXml]
(
	@Application NVARCHAR(60),
	@PageIndex INT = 0,
	@PageSize INT = 15,
	@TotalCount INT OUTPUT
)
AS 

	SET NOCOUNT ON

	DECLARE @FirstTimeUTC DATETIME
	DECLARE @FirstSequence INT
	DECLARE @StartRow INT
	DECLARE @StartRowIndex INT

	SELECT 
		@TotalCount = COUNT(1) 
	FROM 
		[ELMAH_Error] (nolock)
	WHERE 
		[Application] = @Application

	-- Get the ID of the first error for the requested page

	SET @StartRowIndex = @PageIndex * @PageSize + 1

	IF @StartRowIndex <= @TotalCount
	BEGIN

		SET ROWCOUNT @StartRowIndex

		SELECT  
			@FirstTimeUTC = [TimeUtc],
			@FirstSequence = [Sequence]
		FROM 
			[ELMAH_Error]
		WHERE   
			[Application] = @Application
		ORDER BY 
			[TimeUtc] DESC, 
			[Sequence] DESC

	END
	ELSE
	BEGIN

		SET @PageSize = 0

	END

	-- Now set the row count to the requested page size and get
	-- all records below it for the pertaining application.

	SET ROWCOUNT @PageSize

	SELECT 
		errorId     = [ErrorId], 
		application = [Application],
		host        = [Host], 
		type        = [Type],
		source      = [Source],
		message     = [Message],
		[user]      = [User],
		statusCode  = [StatusCode], 
		time        = CONVERT(VARCHAR(50), [TimeUtc], 126) + 'Z'
	FROM 
		[ELMAH_Error] error (nolock)
	WHERE
		[Application] = @Application
	AND
		[TimeUtc] <= @FirstTimeUTC
	AND 
		[Sequence] <= @FirstSequence
	ORDER BY
		[TimeUtc] DESC, 
		[Sequence] DESC
	FOR
		XML AUTO
GO
GRANT EXECUTE ON [dbo].[ELMAH_GetErrorsXml] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[ELMAH_GetErrorsXml] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[ELMAH_GetErrorsXml] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[ELMAH_GetErrorsXml] TO [vnteam]
GO

/****** Object:  StoredProcedure [dbo].[InsertTermLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/26/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertTermLanguage] 
	-- Add the parameters for the stored procedure here
	@termId int,
	@languageCode nvarchar(10),
	@term nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	insert into TermLanguages(termId,languageCode,term)
	values(@termId,@languageCode,@term)
	
	IF @@ERROR <> 0
		SELECT cast(0 as bit)
	ELSE
		SELECT cast(1 as bit)
	
END
GO
GRANT EXECUTE ON [dbo].[InsertTermLanguage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertTermLanguage] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertTermLanguage] TO [vnteam]
GO


/****** Object:  StoredProcedure [dbo].[UpdateTerm]    Script Date: 11/12/2010 15:39:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/16/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UpdateTerm]
	-- Add the parameters for the stored procedure here
	@termId int,
	@name nvarchar(256),
	@slug nvarchar(256),
	@taxonomy nvarchar(32)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @siteId int
	declare @oldTermId int
	declare @oldName nvarchar(256)
	
	select @siteId = siteId from Terms where termId = @termId
	
	select top 1 @oldTermId = Terms.termId, @oldName = Terms.name
	from Terms (nolock)
	inner join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	where Terms.siteId = @siteId and Terms.name = @name and Taxonomy.name = @taxonomy
	
	if @oldTermId <> @termId
		begin
			--duplicate name with another term
			select convert(bit,0)
		end
	else
		begin
			--update
			update Terms  with(rowlock,updlock)
			set name = @name
			where termId = @termId
			
			if @@rowcount <> 0
				select convert(bit,1)
			else
				select convert(bit,0)
		end
	
	
END
GO
GRANT EXECUTE ON [dbo].[UpdateTerm] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[UpdateTerm] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateTerm] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetMostUsedPostTags]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/16/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMostUsedPostTags]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select top 20 Terms.*
	from Terms (nolock)
	inner join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	where Terms.siteId = @siteId and Taxonomy.name = 'post_tag'
	order by Taxonomy.count desc, Terms.name asc
END
GO
GRANT EXECUTE ON [dbo].[GetMostUsedPostTags] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetMostUsedPostTags] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetMostUsedPostTags] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMostUsedPostTags] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetPostTags]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/16/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPostTags]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Terms.*
	from Terms (nolock)
	inner join Taxonomy (nolock)
	on Terms.termId = Taxonomy.termId
	where Terms.siteId = @siteId and Taxonomy.name = 'post_tag'
END
GO
GRANT EXECUTE ON [dbo].[GetPostTags] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetPostTags] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPostTags] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPostTags] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetTerm]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetTerm]
	-- Add the parameters for the stored procedure here
	@termId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select	Terms.*,
			TermLanguages.languageCode,TermLanguages.term,
			Taxonomy.taxonomyId, Taxonomy.name as taxonomy
	from Terms (nolock)
	left join TermLanguages (nolock) on Terms.termId = TermLanguages.termId
	left join Taxonomy (nolock)	on Terms.termId = Taxonomy.termId
	where Terms.termId = @termId
END
GO
GRANT EXECUTE ON [dbo].[GetTerm] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetTerm] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetTerm] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetTerm] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[DeletePost]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/08/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeletePost]
	-- Add the parameters for the stored procedure here
	@postId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	
	-- Insert statements for procedure here
	Begin Try
		Begin Transaction
		delete from Posts
		where postId = @postId
		
		if @@rowcount <> 0
			set @result = convert(bit,1)
		else
			set @result = convert(bit,0)
		
		--update Taxonomy COUNT
		update Taxonomy  with (rowlock,updlock)
		set [count] = [count] - 1
		where (Taxonomy.name = 'post_cat' or Taxonomy.name = 'post_tag') and
				taxonomyId in (select taxonomyId
							from TermRelationships (nolock)
							where objectId = @postId)
		
		--delete relationship, keep categories + tags
		delete from TermRelationships
		where objectId = @postId and 
				taxonomyId in	(select taxonomyId
								from Taxonomy (nolock)
								where	Taxonomy.name = 'post_cat' or 
										Taxonomy.name = 'post_tag'
								)
		--3. child post
	delete from Posts
	where parentId = @postId
	
		set @result = convert(bit,1)
		Commit Transaction
	End Try
	Begin Catch
	set @result = convert(bit,0)
		Rollback Transaction
	  print ERROR_MESSAGE()
	End Catch
	
	select @result
END

GO
GRANT EXECUTE ON [dbo].[DeletePost] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[DeletePost] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeletePost] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetTermsByTaxonomy]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/26/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetTermsByTaxonomy]
	-- Add the parameters for the stored procedure here
	@taxonomy nvarchar(32)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select	Terms.*,
			TermLanguages.languageCode,TermLanguages.term,
			Taxonomy.taxonomyId, Taxonomy.name as taxonomy
	from Terms (nolock)
	left join TermLanguages (nolock) on Terms.termId = TermLanguages.termId
	left join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	where Taxonomy.name = @taxonomy and TermLanguages.languageCode = 'en-US'
END
GO
GRANT EXECUTE ON [dbo].[GetTermsByTaxonomy] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetTermsByTaxonomy] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetTermsByTaxonomy] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetTermsByTaxonomy] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[DeleteBackground]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/26/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteBackground]
	-- Add the parameters for the stored procedure here
	@backgroundId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	
	Begin Try
		Begin Transaction
		-- Insert statements for procedure here
		delete from Posts
		where postId = @backgroundId
		
		if @@rowcount <> 0
			set @result = convert(bit,1)
		else
			set @result = convert(bit,0)
			
		
		--update category count
		update Taxonomy with (rowlock,updlock)
		set [count] = [count] - 1
		where Taxonomy.name = 'bg_cat' and
				taxonomyId in (select taxonomyId
							from TermRelationships (nolock)
							where objectId = @backgroundId)
		
		--delete relationship
		delete from TermRelationships
		where objectId = @backgroundId and 
				taxonomyId in	(select taxonomyId
								from Taxonomy (nolock)
								where name = 'bg_cat'
								)
		set @result = convert(bit,1)
		Commit Transaction
	End Try
	Begin Catch
	set @result = convert(bit,0)
		Rollback Transaction
		print ERROR_MESSAGE()
	End Catch			
	
	select @result		
END
GO

GO
GRANT EXECUTE ON [dbo].[DeleteBackground] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[DeleteBackground] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteBackground] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetBackgroundsByCategory]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/26/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBackgroundsByCategory]
	-- Add the parameters for the stored procedure here
	@termId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Posts.postId as backgroundId, Posts.title, Posts.content as [fileName]
	from TermRelationships (nolock)
	inner join Posts (nolock)on TermRelationships.objectId = Posts.postId
	inner join Taxonomy (nolock) on TermRelationships.taxonomyId = Taxonomy.taxonomyId
	where Taxonomy.termId = @termId and Posts.[type] = 2
END
GO
GRANT EXECUTE ON [dbo].[GetBackgroundsByCategory] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetBackgroundsByCategory] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetBackgroundsByCategory] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetBackgroundsByCategory] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[InsertTermRelationship]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/08/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertTermRelationship] 
	-- Add the parameters for the stored procedure here
	@objectId int,
	@termId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	declare @taxonomyId int
	
	
	select @taxonomyId = taxonomyId
	from Taxonomy (nolock)
	where termId = @termId
		
	Begin Try
		Begin Transaction		
		--add relationship
		insert into TermRelationships(objectId,taxonomyId,orderNo)
		values(@objectId,@taxonomyId,0)
		
		if @@rowcount <> 0
			set @result = convert(bit,1)
		else
			set @result = convert(bit,0)
			
			
		--update Taxonomy.Count
		update Taxonomy with (rowlock,updlock)
		set [count] = [count] + 1
		where taxonomyId = @taxonomyId
		
		set @result = convert(bit,1)
		Commit Transaction
	End Try
	Begin Catch
		set @result = convert(bit,0)
		Rollback Transaction
		print ERROR_MESSAGE()
	End Catch	
	
	select @result
	
END

GO
GRANT EXECUTE ON [dbo].[InsertTermRelationship] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[InsertTermRelationship] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[InsertTermRelationship] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertTermRelationship] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetSystemTerms]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSystemTerms]
	-- Add the parameters for the stored procedure here
	@languageCode nvarchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select	Terms.*,
			TermLanguages.languageCode,TermLanguages.term,
			Taxonomy.taxonomyId, Taxonomy.name as taxonomy
	from Terms (nolock)
	left join TermLanguages (nolock) on Terms.termId = TermLanguages.termId
	left join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	where TermLanguages.languageCode = @languageCode
END
GO
GRANT EXECUTE ON [dbo].[GetSystemTerms] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSystemTerms] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetTermByLanguage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetTermByLanguage]
	-- Add the parameters for the stored procedure here
	@termId int,
	@languageCode nvarchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select	Terms.*,
			TermLanguages.languageCode,TermLanguages.term,
			Taxonomy.taxonomyId, Taxonomy.name as taxonomy
	from Terms (nolock)
	left join TermLanguages (nolock) on Terms.termId = TermLanguages.termId
	left join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	where Terms.termId = @termId and TermLanguages.languageCode = @languageCode
END
GO
GRANT EXECUTE ON [dbo].[GetTermByLanguage] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetTermByLanguage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetTermByLanguage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetTermByLanguage] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetPostCategories]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPostCategories]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select Terms.*
	from Terms (nolock)
	inner join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	where Terms.siteId = @siteId and Taxonomy.name = 'post_cat'
END
GO
GRANT EXECUTE ON [dbo].[GetPostCategories] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetPostCategories] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPostCategories] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPostCategories] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetPostCategoryWithCount]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPostCategoryWithCount]
	-- Add the parameters for the stored procedure here
	@siteId int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SELECT Terms.*, Taxonomy.[count] as [count]
	from Terms (nolock)
	inner join Taxonomy (nolock) on Terms.termId = Taxonomy.termId
	where siteId = @siteId and Taxonomy.name = 'post_cat'
END
GO
GRANT EXECUTE ON [dbo].[GetPostCategoryWithCount] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetPostCategoryWithCount] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPostCategoryWithCount] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPostCategoryWithCount] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetPostsByCategory]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetPostsByCategory]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@categoryId int,
	@pageNumber int,
	@pageSize int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @commentNumber int
	set @commentNumber = 0
	-- Insert statements for procedure here
	select Posts.*,@commentNumber as commentNumber 
	from Posts (nolock)
	inner join TermRelationships (nolock) on Posts.postId = TermRelationships.objectId
	inner join Taxonomy (nolock) on TermRelationships.taxonomyId = Taxonomy.taxonomyId
	where Posts.siteId = @siteId  and Posts.[type] = 0 and Taxonomy.termId = @categoryId
	order by postId desc
END
GO
GRANT EXECUTE ON [dbo].[GetPostsByCategory]TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetPostsByCategory]TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetPostsByCategory]TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPostsByCategory]TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[InsertTaxonomy]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertTaxonomy]
	-- Add the parameters for the stored procedure here
	@termId int,
	@name nvarchar(32)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	insert into Taxonomy(termId,name,parentId,[count])
	values(@termId,@name,0,0)
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
GO
GRANT EXECUTE ON [dbo].[InsertTaxonomy]TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[InsertTaxonomy] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertTaxonomy] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetBackgroundCategories]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/27/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetBackgroundCategories]
	-- Add the parameters for the stored procedure here
	@languageCode nvarchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select	Terms.*,
			TermLanguages.languageCode,TermLanguages.term,
			Taxonomy.taxonomyId, Taxonomy.name as taxonomy
	from Terms (nolock)
	left join TermLanguages (nolock)
	on Terms.termId = TermLanguages.termId
	left join Taxonomy (nolock)
	on Terms.termId = Taxonomy.termId
	where Taxonomy.name = 'bg_cat' and TermLanguages.languageCode = @languageCode
END
GO
GRANT EXECUTE ON [dbo].[GetBackgroundCategories] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetBackgroundCategories] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetBackgroundCategories] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetBackgroundCategories] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[DeleteTerm]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith Tran
-- Create date: 10/10/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteTerm]
	-- Add the parameters for the stored procedure here
	@termId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	declare @taxonomyId int
	declare @result bit	
	
	Begin Try
		Begin Transaction
		delete Terms
		where termId = @termId
		set @result = cast(@@rowcount as bit)
		
		delete TermLanguages
		where termId = @termId
		
		select @taxonomyId  = isnull(taxonomyId,0) from Taxonomy (nolock) where termId = @termId
		
		delete Taxonomy
		where termId = @termId
		
		delete TermRelationships
		where taxonomyId = @taxonomyId
		set @result = convert(bit, 1)
		Commit Transaction
	End Try
	Begin Catch
		Rollback Transaction
		set @result = convert(bit, 0)
		print ERROR_MESSAGE()
	End Catch
	
	select @result
END
GO
GRANT EXECUTE ON [dbo].[DeleteTerm] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[DeleteTerm] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteTerm] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[CopySiteToSite]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/20/2010
-- Update date: 10/23/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CopySiteToSite]
	-- Add the parameters for the stored procedure here
	@fromSiteId int,
	@toSiteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- copy here
	--1. Sites table (only bodyLayoutId, footerLayoutId, other fields were filled)
	--2. Sites Meta table
	--3. Pages table (after copy this table, update homePageId of Sites table)
	--4. PageEmbeddables table
	--5. PageEmbeddableMeta table
	--6. Menu table
	
	--:::UNFINISHED:::
	--7. Posts + Comment
	--IMPLEMENT
	
	BEGIN TRY
		Begin Transaction
			--1. Sites table
			declare @bodyLayoutId int, @footerLayoutId int
			
			select @bodyLayoutId = bodyLayoutId, @footerLayoutId = footerLayoutId
			from Sites with(nolock) where siteId = @fromSiteId
			
			update Sites with (rowlock,updlock)
			set bodyLayoutId = @bodyLayoutId, footerLayoutId = @footerLayoutId,currentRevision=0
			where siteId = @toSiteId
		   
	
			--2. Sites metatable
			insert into SiteMeta(siteId,[key],value)
			select @toSiteId, [key], value
			from SiteMeta with (nolock)
			where siteId = @fromSiteId
			
			--3. page table
			declare @currentPage uniqueidentifier
			declare @TempPage table (oldPageId uniqueidentifier,newPageID uniqueidentifier) 
			declare @TempMenu table (oldMenuId int,newMenuId int,parentId int) 
			declare @newPageId uniqueidentifier
			
			select @currentPage =( select top(1) PageId from Pages with (nolock) where siteId=@fromSiteId)
			
			
		   declare @PageEmbeddableTemp table(instanceId int, bucket nvarchar(64),embeddableId int)
			
			while @currentPage is not null
			begin
				--track this page
				set @newPageId = newid()
				insert into @TempPage(oldPageId,newPageID)
				values(@currentPage,@newPageId)
				--print @newPageId
				--copy page
				insert into Pages(pageId,siteId,url,title,masterId,[enable],createdDate,updatedDate)
				select @newPageId,@toSiteId,url,title,null,[enable],getdate(),getdate()
				from Pages with (nolock)
				where siteId = @fromSiteId and pageId = @currentPage
				--print @newPageId
				
				--copy page embeddable
				delete @PageEmbeddableTemp
				insert into PageEmbeddables(pageId,bucket,embeddableId,title,[status],orderNo)
				output inserted.instanceId,inserted.bucket,inserted.embeddableId into @PageEmbeddableTemp
				select @newPageId,bucket,embeddableId,title,[status],orderNo
				from PageEmbeddables p with (nolock)
				where pageId = @currentPage
				--select * from @PageEmbeddableTemp
				--copy page embeddable meta
			--	set identity_insert PageEmbeddableMeta on
				Insert into PageEmbeddableMeta(instanceId,[key],value)
				Select t.newInstanceId,m.[key],m.value
				from 
				(
					select m1.instanceId as fromInstanceId,m2.instanceId as newInstanceId
					from PageEmbeddables m1 (nolock)					    
						 inner join @PageEmbeddableTemp m2 on m2.bucket=m1.bucket and m2.embeddableId=m1.embeddableId
					where m1.pageId= @currentPage
				  ) t
				   inner join PageEmbeddableMeta m with (nolock) on m .instanceId=t.fromInstanceId  
			--	set identity_insert PageEmbeddableMeta on
				--set next page
				
				select @currentPage =( select top(1) PageId from Pages with (nolock) where siteId=@fromSiteId and pageId not in (select oldPageId from @TempPage))
				
			end
			--Duplicate the Menu and update parentId 
			delete @TempMenu
			insert into Menu(siteId,parentId,[level],orderNo,name,link,pageId)
			output inserted.parentId,inserted.MenuId,0 into @TempMenu
			select @toSiteId,menuId,[level],orderNo,name,link,t.newPageId
			from Menu m1 (nolock)
			  left join @TempPage t on t.oldPageId=m1.pageId
			 where m1.SiteId= @fromSiteId
			--update parentId 
			update t
			  set t.parentId= m.parentId
			 from  @TempMenu t
			  inner join Menu(nolock) m on m.menuId=t.oldMenuId
			  
			 update m
			 set m.parentId=isnull(t.parentId,0)
			 from  Menu m with (rowlock,updlock)
				  inner join  @TempMenu t on t.newMenuId=m.MenuId
			 where m.siteId=@toSiteId
			 
			 update m
			 set m.parentId=isnull(t.newMenuId,0)
			 from  Menu m with (rowlock,updlock)
				  left join  @TempMenu t on t.oldMenuId=m.parentId
			 where m.siteId=@toSiteId     
	
			
			--update homepageid
			update Sites  with(rowlock,updlock)
			set homepageId=(select t.newPageId
							  from Sites s1 with(nolock)
								   inner join  @TempPage t on t.oldPageId=s1.homepageId
							   where  siteId=@fromSiteId)
			where siteId=@toSiteId 
			--check the table SiteVersions is created?
			
			if(not exists (select 1 from SiteVersions (nolock) where siteId=@toSiteId))  
			begin
				 INSERT INTO [SiteVersions]
				   ([versionId]
				   ,[siteId]
				   ,[timestamp])
				select 0 as versionId
					,@toSiteId      
					,current_timestamp
			end
			--copy site from main to temp
			--exec dbo.CopySiteFromMainToTemp @toSiteId
			Commit Transaction
			select cast(1 as bit)
	 END TRY
	 BEGIN CATCH
			print ERROR_MESSAGE()	
			Rollback Transaction					
			--Select @ErrMsg = ERROR_MESSAGE()
			select cast(0 as bit)
	END CATCH
END
GO

GO
GRANT EXECUTE ON [dbo].[CopySiteToSite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[CopySiteToSite] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CopySiteToSite] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetSitePreviewMeta]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/06/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSitePreviewMeta]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select [key],value
	from SiteMetaTemps (nolock)
	where siteId = @siteId
END
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewMeta] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewMeta] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetSitePreviewMeta] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSitePreviewMeta] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[DeleteSiteMeta]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/30/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DeleteSiteMeta]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@key nvarchar(64)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	delete from SiteMetaTemps
	where siteId = @siteId and [key] = @key
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
GO
GRANT EXECUTE ON [dbo].[DeleteSiteMeta] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[DeleteSiteMeta] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteSiteMeta] TO [VNTeam]

/****** Object:  StoredProcedure [dbo].[GetSiteMeta]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/27/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetSiteMeta]
	-- Add the parameters for the stored procedure here
	@siteId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select [key],value
	from SiteMeta (nolock)
	where siteId = @siteId
END
GO
GRANT EXECUTE ON [dbo].[GetSiteMeta] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetSiteMeta] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetSiteMeta] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSiteMeta] TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[InsertMessage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/11/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertMessage]
	-- Add the parameters for the stored procedure here
	@fromSiteId int,
	@toSiteId int,
	@title nvarchar(256),
	@content nvarchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Insert statements for procedure here
	insert into [Messages](fromSiteId,toSiteId,title,content,isRead,isDeleted,createdDate)
	values(@fromSiteId,@toSiteId,@title,@content,0,0,getdate())
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
GO
GRANT EXECUTE ON [dbo].[InsertMessage]TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[InsertMessage]TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[InsertMessage]TO [VNTeam]
/****** Object:  StoredProcedure [dbo].[GetMessage]    Script Date: 11/12/2010 15:39:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 11/11/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[GetMessage] 
	-- Add the parameters for the stored procedure here
	@messageId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	select messageId,title,content,createdDate,isRead
	from [Messages]
	where messageId = @messageId
END
GO
GRANT EXECUTE ON [dbo].[GetMessage] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[GetMessage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[GetMessage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[GetMessage] TO [VNTeam]