/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_Aff_CheckSPVersion]
(
	@ProcId INT
)
RETURNS BIT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function - Check SP version

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

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