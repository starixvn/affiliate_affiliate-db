 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[InsertPage]    Script Date: 10/23/2010 10:11:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/19/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertPage]
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
		insert into Pages(pageId,siteId,url,title,masterId,[enable],createdDate,updatedDate)
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
