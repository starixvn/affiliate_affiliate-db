/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffiliateUsername_SearchEx]
	@Username VARCHAR(50)
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core SP - Select top 10 affiliate username by @Username

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TOP (10) Username
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE Username LIKE '%' + ISNULL(LTRIM(LTRIM(@Username)), '') + '%'
		AND status = 'Approved'
END
GO