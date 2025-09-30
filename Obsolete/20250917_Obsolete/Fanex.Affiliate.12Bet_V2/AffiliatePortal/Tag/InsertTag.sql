 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[InsertTag]    Script Date: 10/23/2010 10:14:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertTag]
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
	
	select @oldName = name, @termId = termId from Terms
	where siteId = @siteId and name = @name
	--exactly: CONVERT(varbinary(256), name) = CONVERT(varbinary(256), @name)
	
	if @oldName = @name
		begin
			--duplicate term name
			--get taxonomyId
			select @taxonomyId = taxonomyId
			from Taxonomy
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
	from TermRelationships
	where objectId = @postId and taxonomyId = @taxonomyId
	
	if @objectId is null
	begin
		insert into TermRelationships(objectId,taxonomyId,orderNo)
		values(@postId,@taxonomyId,0)
	end
	
	--update Taxonomy.Count
	update Taxonomy
	set [count] = [count] + 1
	where taxonomyId = @taxonomyId
					
	select @result
END
