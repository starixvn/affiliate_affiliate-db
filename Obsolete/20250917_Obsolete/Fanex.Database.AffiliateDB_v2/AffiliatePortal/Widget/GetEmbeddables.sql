-- =============================================
-- Author:		Smith
-- Create date: 10/12/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[GetEmbeddables]
	-- Add the parameters for the stored procedure here
	@isSystem bit
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select * from
(

SELECT [embeddableId]
      ,[fromEmbeddableId] as baseEmbeddable
      ,[name]
      ,[description]
      ,[editable]
      ,[deletable]
      ,[enable]
  FROM [EmbeddableSamples] (nolock)
  --WHERE [enable] = 1 and [deletable] = 1
  
  union all
  
  SELECT  [embeddableId]
      ,0 as baseEmbeddable
      ,[name]
      ,[description]
      ,[editable]
      ,cast(1 as bit) as deletable
      ,[enable]     
  FROM [Embeddables] (nolock)
  WHERE [enable] = 1 and isSystem = @isSystem
  ) t
  order by name asc
END
GO
