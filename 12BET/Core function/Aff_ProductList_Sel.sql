/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ProductList_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core function - Get product list

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Add isTest [RedmineID: #102322]
		- 20211207@Percy: Apply core function Group Product [RedmineID: #165777]
		- 20240325@Eddie: Merge VS2 into Virtual Sports and change metadata "bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" [RedmineID: #201095]
		- 20240611@Eddie: Add new Product VS3&4 and change metadata "wsv_aff,wsv_affv" [RedmineId : #206363]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsTest BIT
	SELECT  @IsTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	SELECT p.ProductId, p.ProductName, p.EndOfSupportDate
	FROM dbo.Products p WITH (NOLOCK)
	WHERE p.IsTest <= @IsTest
		AND NOT EXISTS (SELECT 1 FROM dbo.Aff_f_GroupProduct() g WHERE p.ProductId = g.ProductId AND g.ProductId <> g.GroupProductId)
	ORDER BY p.ProductId
END
GO