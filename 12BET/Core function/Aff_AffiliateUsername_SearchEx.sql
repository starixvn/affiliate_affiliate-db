/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateUsername_SearchEx]
	@Username VARCHAR(50)
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core SP - Select top 10 affiliate username by @Username

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TOP (10) Username
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE Username LIKE '%' + ISNULL(LTRIM(LTRIM(@Username)), '') + '%'
		AND status = 'Approved'
END
GO