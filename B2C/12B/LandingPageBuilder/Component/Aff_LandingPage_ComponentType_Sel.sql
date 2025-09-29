/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_ComponentType_Sel]
AS
/*
	Created: 20250929@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Select Landing Page Component Types
	Revisions:
		- 20250929@Sophia: Initial version [RedmineID: #239988]
*/
BEGIN
	SET NOCOUNT ON;

	SELECT 
		ct.ComponentTypeId,
		ct.ComponentTypeName
	FROM dbo.LandingPage_ComponentType ct WITH (NOLOCK)
	ORDER BY ct.ComponentTypeId ASC;
END;