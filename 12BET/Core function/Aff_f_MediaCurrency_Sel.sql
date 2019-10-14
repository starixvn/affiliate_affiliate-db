/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_MediaCurrency_Sel]
(
)
RETURNS TABLE
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core function store Currency on Media Gallery

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

RETURN
	SELECT CurrencyId, Currency
	FROM (
		VALUES
			(1, 'RMB')
			,(2, 'US$')
			,(3, 'EURO')
			,(4, 'GBP')
			,(5, 'THB')
			,(6, 'IN')
			,(7, 'MYR')
			,(8, 'VND')
			,(9, 'INR')
			,(10, 'MKK')
			,(11, 'KHR')
	) AS MediaCurrency (CurrencyId, Currency)
GO