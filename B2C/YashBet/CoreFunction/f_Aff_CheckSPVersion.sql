/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Aff_CheckSPVersion]
(
	@ProcId INT
)
RETURNS BIT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function - Check SP version

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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