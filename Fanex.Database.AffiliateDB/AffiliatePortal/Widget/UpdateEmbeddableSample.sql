 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[UpdateEmbeddableSample]    Script Date: 10/23/2010 10:18:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateEmbeddableSample]
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
	update EmbeddableSamples
	set name = @name,
		[description] = @description
	where embeddableId = @embeddableId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
