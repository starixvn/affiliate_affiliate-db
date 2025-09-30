 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[UpdateTerm]    Script Date: 10/23/2010 10:21:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/16/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateTerm]
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
    from Terms
    join Taxonomy on Terms.termId = Taxonomy.termId
    where Terms.siteId = @siteId and Terms.name = @name and Taxonomy.name = @taxonomy
    
    if @oldTermId <> @termId
		begin
			--duplicate name with another term
			select convert(bit,0)
		end
    else
		begin
			--update
			update Terms
			set name = @name
			where termId = @termId
			
			if @@rowcount <> 0
				select convert(bit,1)
			else
				select convert(bit,0)
		end
    
	
END
