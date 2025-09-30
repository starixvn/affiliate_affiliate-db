 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[DeleteTerm]    Script Date: 10/22/2010 10:52:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith Tran
-- Create date: 10/10/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[DeleteTerm]
	-- Add the parameters for the stored procedure here
	@termId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	declare @taxonomyId int
	declare @result bit	
	
	delete Terms
	where termId = @termId
	set @result = cast(@@rowcount as bit)
	
	delete TermLanguages
	where termId = @termId
	
	select @taxonomyId  = isnull(taxonomyId,0) from Taxonomy where termId = @termId
	
	delete Taxonomy
	where termId = @termId
	
	delete TermRelationships
	where taxonomyId = @taxonomyId
	
	select @result
END
