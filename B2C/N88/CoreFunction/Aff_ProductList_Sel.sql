/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ProductList_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core function - Get product list

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Add isTest [RedmineID: #102322]
		- 20210714@Percy: Add P2P [RedmineID: #157958]
		- 20240206@Sally: Merge VS 1,2,3 into VS only [RedmineID: #199895]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsTest BIT
	SELECT  @IsTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	SELECT 
		p.ProductId,
		p.ProductName,
		p.EndOfSupportDate,
		ISNULL(p.IsP2P, 0) AS IsP2P
	FROM dbo.Products p WITH (NOLOCK)
		LEFT JOIN dbo.Aff_f_GroupProduct() gp ON p.ProductID = gp.ProductId 
										AND gp.ProductId <> gp.GroupProductId 
	WHERE IsTest <= @IsTest 
		AND gp.ProductId IS NULL
	ORDER BY ProductId
END
GO
