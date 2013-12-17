 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[InsertTaxonomy]    Script Date: 10/23/2010 10:14:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertTaxonomy]
	-- Add the parameters for the stored procedure here
	@termId int,
	@name nvarchar(32)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into Taxonomy(termId,name,parentId,[count])
	values(@termId,@name,0,0)
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
