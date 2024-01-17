/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ProductList_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function - Get product list

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @IsTest BIT
	SELECT  @IsTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	SELECT
		ProductId,
		ProductName,
		EndOfSupportDate,
		ISNULL(IsP2P, 0) AS IsP2P
	FROM dbo.Products WITH (NOLOCK)
	WHERE IsTest <= @IsTest
	ORDER BY
		ProductId
END
GO