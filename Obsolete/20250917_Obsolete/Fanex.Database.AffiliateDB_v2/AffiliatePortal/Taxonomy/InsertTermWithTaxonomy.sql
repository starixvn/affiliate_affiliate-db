 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[InsertTermWithTaxonomy]    Script Date: 10/23/2010 10:16:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/16/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertTermWithTaxonomy] 
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
	
	select @oldName = name from Terms
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
