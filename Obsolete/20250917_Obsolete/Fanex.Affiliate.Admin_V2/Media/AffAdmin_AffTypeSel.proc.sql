CREATE PROCEDURE [dbo].[AffAdmin_AffTypeSel]
AS

SELECT TypeID ,Name
FROM dbo.AffType

GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffTypeSel] TO [vnteam]