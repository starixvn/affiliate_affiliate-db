/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Deal_Sel]
	@StatusIDs VARCHAR(50) = '1' -- Default to active status
AS
/*
	Created: 20250825@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Select Landing Page Deals

	Revisions:  
		- 20250825@Sophia: Initialize SP [RedmineID: #236797]
*/
BEGIN
	SET NOCOUNT ON;
	
	-- Create table variable for StatusIDs
	DECLARE @StatusIDTable TABLE (StatusId INT);
	
	-- Split and insert status IDs
	INSERT INTO @StatusIDTable (StatusId)
	SELECT CAST(value AS INT)
	FROM STRING_SPLIT(@StatusIDs, ',');
	
	-- Get list of deals from LandingPage_Deal joined with CommGroup for DealName
	SELECT 
		ld.DealId,
		cg.GroupName AS DealName
	FROM dbo.LandingPage_Deal ld WITH (NOLOCK)
	INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ld.DealId = cg.GroupId
	WHERE ld.StatusId IN (SELECT StatusId FROM @StatusIDTable)
		AND (EXISTS (SELECT 1 FROM @StatusIDTable WHERE StatusId = 2) -- If status 2 exists
			OR cg.IsDeleted = 0) -- Only check IsDeleted if status 2 not present
	ORDER BY ld.DealId DESC;
END
