 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[DeleteTermRelationship]    Script Date: 10/22/2010 10:54:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/20/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DeleteTermRelationship]
	-- Add the parameters for the stored procedure here
	@objectId int,
	@taxonomyId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @result bit
	
    -- Insert statements for procedure here
	delete from TermRelationships
	where objectId = @objectId and taxonomyId = @taxonomyId
	
	if @@rowcount <> 0
		set @result = convert(bit,1)
	else
		set @result = convert(bit,0)
		
	--update taxonomy COUNT
	update Taxonomy
	set [count] = [count] - 1
	where taxonomyId = @taxonomyId
	
	select @result
END
