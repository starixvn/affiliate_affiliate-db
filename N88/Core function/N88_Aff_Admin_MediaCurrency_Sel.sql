/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaCurrency_Sel]
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Media Gallery - Get Currency

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	SELECT CurrencyId, Currency
	FROM dbo.Aff_f_MediaCurrency_Sel()
	ORDER BY Currency
END
GO