USE [Affiliate_Athena000]
GO

ALTER FUNCTION [dbo].[f_Aff_CheckSPVersion]
(
	@ProcId INT
)
RETURNS BIT
AS

/*
	Created by: Percy
	Date: 2017-06-01
	DB: DBAFF.Affiliate_Athena000
	Task: Check testing SP

	Revisions:
*/

BEGIN
	DECLARE @isTest BIT, @SPName NVARCHAR(200)
	
	SELECT  @SPName = OBJECT_NAME(@ProcId)
	IF (
		@SPName LIKE '%_xtest'
		OR @SPName LIKE '%_xpre'
		OR @SPName LIKE '%_UAT1'
		OR @SPName LIKE '%_UAT2'
		OR @SPName LIKE '%_UAT3'
		OR @SPName LIKE '%_UAT4'
	)
	BEGIN
		SELECT @isTest = 1
	END
	ELSE
	BEGIN
		SELECT @isTest = 1
	END

	RETURN @isTest
END
GO
GRANT EXECUTE ON [dbo].[f_Aff_CheckSPVersion] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[f_Aff_CheckSPVersion] TO [vnteam]
GO