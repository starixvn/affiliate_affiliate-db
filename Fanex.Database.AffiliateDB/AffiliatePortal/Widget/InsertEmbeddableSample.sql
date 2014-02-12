-- =============================================
-- Author:		Smith
-- Create date: 10/22/2010
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[InsertEmbeddableSample]
	-- Add the parameters for the stored procedure here
	@fromEmbeddableId int,
	@name nvarchar(256),
	@description nvarchar(1024),
	@editable bit,
	@deletable bit,
	@enable bit,
	@createdBy int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into EmbeddableSamples(fromEmbeddableId,name,[description],editable,deletable,[enable],createdBy,createdDate)
	values(@fromEmbeddableId,@name,@description,@editable,@deletable,@enable,@createdBy,getdate())
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
GO
