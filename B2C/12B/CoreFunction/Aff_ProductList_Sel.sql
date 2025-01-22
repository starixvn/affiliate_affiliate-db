/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ProductList_Sel]
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function - Get product list

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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