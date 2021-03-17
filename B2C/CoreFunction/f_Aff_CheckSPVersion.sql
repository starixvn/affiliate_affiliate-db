/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Aff_CheckSPVersion]
(
	@ProcId INT
)
RETURNS BIT
AS

/*
	Created by: 20170601@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core function - Check SP version

	Revisions:
		- 20170601@Percy: Initialize SP [RedmineID: #77521]
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
		SELECT @isTest = 0
	END

	RETURN @isTest
END
GO