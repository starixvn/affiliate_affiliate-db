/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ProductList_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function - Get product list

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
		- 20240222@Sally: Merge VS 1,2,3 into VS only [RedmineID: #199895]

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