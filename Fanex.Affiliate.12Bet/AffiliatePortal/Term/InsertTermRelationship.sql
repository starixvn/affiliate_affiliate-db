 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[InsertTermRelationship]    Script Date: 10/23/2010 10:16:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/08/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertTermRelationship] 
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
	from Taxonomy
	where termId = @termId
				
	--add relationship
	insert into TermRelationships(objectId,taxonomyId,orderNo)
	values(@objectId,@taxonomyId,0)
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
		
		
	--update Taxonomy.Count
	update Taxonomy
	set [count] = [count] + 1
	where taxonomyId = @taxonomyId
	
    
	select @result
	
END
