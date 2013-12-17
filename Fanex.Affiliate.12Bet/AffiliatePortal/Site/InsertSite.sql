 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[InsertSite]    Script Date: 10/23/2010 10:13:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/19/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertSite]
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
									from Sites
									where siteId < 0)
				set @siteHost = convert(nvarchar,@trueSiteId)
			end
			
			--insert site
			begin try
				--default layout:
				--bodyLayoutId   = 3 (Two columns with right panel)
				--footerLayoutId = 5 (One column footer)
				insert into Sites(siteId,siteName,siteHost,siteTitle,displayName,currentRevision,bodyLayoutId,footerLayoutId,homePageId)
				values(@trueSiteId,@siteName,@siteHost,@siteTitle,@displayName,0,3,5,'00000000-0000-0000-0000-000000000000')
				
				if @@rowcount <> 0
					set @result = @trueSiteId
				else
					set @result = 0
				
				--create default home page for user
				--insert into Pages(pageId,siteId,url,title,masterId,[enable],createdDate,updatedDate)
				--values(newid(),@siteId,'home','Home',null,1,getdate(),getdate())
				
			end try
			
			begin catch
				select convert(int,0)
			end catch
			
			
			select @result
		end
END
