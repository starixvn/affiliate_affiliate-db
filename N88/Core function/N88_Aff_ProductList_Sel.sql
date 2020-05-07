/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ProductList_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Core function - Get product list

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Add isTest [RedmineID: #102322]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsTest BIT
	SELECT  @IsTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	SELECT
		ProductId,
		ProductName,
		EndOfSupportDate
	FROM dbo.Products WITH (NOLOCK)
	WHERE IsTest <= @IsTest
	ORDER BY
		ProductId
END
GO