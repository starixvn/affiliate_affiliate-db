/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_TargetProduct_Sel]
AS

/*
	Created: 20231108@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Affiliate 12BET - Core function - Target Product

	Revisions:
		- 20231108@Eddie: Initialize SP [RedmineID: #181590]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ProductID AS TargetProductId, ProductName AS TargetProductName
	FROM dbo.TargetProduct WITH (NOLOCK)
	ORDER BY ProductID ASC
END
GO