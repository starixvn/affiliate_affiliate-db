 set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

-- =============================================
-- Author:		Smith
-- Create date: 2011/02/23
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[Aff_ResourcesSel]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select * from RefResources (nolock)
END

GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesSel] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesSel] TO [vnteam]