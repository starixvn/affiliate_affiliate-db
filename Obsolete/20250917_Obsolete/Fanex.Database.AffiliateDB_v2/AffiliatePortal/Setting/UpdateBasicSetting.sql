 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[UpdateBasicSetting]    Script Date: 10/23/2010 10:18:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/12/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateBasicSetting]
	-- Add the parameters for the stored procedure here
	@siteId int,
	@siteName nvarchar(256),
	@siteTitle nvarchar(256),
	@siteHost nvarchar(256),
	@displayName nvarchar(256)
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    begin try
		update Sites
		set
			siteName = @siteName,
			siteTitle = @siteTitle,
			siteHost = @siteHost,
			displayName = @displayName
		where
			siteId = @siteId
			
		if @@rowcount <> 0
			select convert(bit,1)
		else
			select convert(bit,0)
	end try
	begin catch
		select convert(bit,0)
	end catch
END
