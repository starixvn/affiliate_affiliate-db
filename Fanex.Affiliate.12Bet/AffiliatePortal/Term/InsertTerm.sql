 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[InsertTerm]    Script Date: 10/23/2010 10:15:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/08/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[InsertTerm]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@name nvarchar(256),
	@slug nvarchar(256)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into Terms(siteId,name,slug)
	values(@siteId,@name,@slug)
	
	IF @@ERROR <> 0
		SELECT 0
	ELSE
		SELECT	cast(SCOPE_IDENTITY() as int)
END
