/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_AffiliateUsername_SearchEx]
	@Username VARCHAR(50)
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core SP - Select top 10 affiliate username by @Username

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TOP (10) Username
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE Username LIKE '%' + ISNULL(LTRIM(LTRIM(@Username)), '') + '%'
		AND status = 'Approved'
END
GO