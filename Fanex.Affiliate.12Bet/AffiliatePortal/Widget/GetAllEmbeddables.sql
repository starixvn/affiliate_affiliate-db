-- =============================================
-- Author:		Smith
-- Create date: 10/21/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetAllEmbeddables] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [embeddableId]
      ,0 as baseEmbeddable
      ,[name]
      ,[description]
      ,[editable]
      ,cast(1 as bit) as deletable
      ,[enable]
	FROM [Embeddables] (nolock)
	order by isSystem desc, name asc
END
GO
