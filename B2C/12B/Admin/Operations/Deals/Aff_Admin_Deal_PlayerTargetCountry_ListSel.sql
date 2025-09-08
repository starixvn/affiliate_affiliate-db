/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Deal_PlayerTargetCountry_ListSel]
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Operation - Deal - Dropdown Commission Group

	Revisions:
		- 20250526@Lewis: Initialize SP [RedmineID: #228530]
*/

BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT
		e.ExchangeId
		, e.Code AS ExchangeCode
		, tc.CountryCode AS TargetCountryCode
		, tc.CountryName AS TargetCountryName
	FROM dbo.Exchange e WITH (NOLOCK)
		INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON e.CountryCode = tc.CountryCode
END	 
GO