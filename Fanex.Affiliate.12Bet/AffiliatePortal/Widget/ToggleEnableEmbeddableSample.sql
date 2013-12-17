 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[ToggleEnableEmbeddableSample]    Script Date: 10/23/2010 10:17:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[ToggleEnableEmbeddableSample]
	-- Add the parameters for the stored procedure here
	@embeddableId int 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	update EmbeddableSamples
	set [enable] = ~[enable]
	where embeddableId = @embeddableId
	
	if @@rowcount <> 0
		select convert(bit,1)
	else
		select convert(bit,0)
END
