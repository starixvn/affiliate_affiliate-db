/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_AffGroupInfo_Sel] (
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@AffIds		VARCHAR(MAX) = 'all'
)
RETURNS TABLE
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function - Get AffGroupInfo

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]
        - 20250417@Sally: Add Revenue Group column [RedmineID: #224286]

	Param's Explanation:
		- @AffIds : list of Affiliate's id

*/
RETURN
	WITH CTE_CommGroup AS(
		SELECT agh.MonthDate
			,agh.GroupId
			,agh.AffId
			,agh.ParentAffId
			,agh.AllParentAffId
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		WHERE (@AffIds = 'all' OR ',' + @AffIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), agh.AffId) + ',%')
			 AND agh.MonthDate >= @FromDate
			 AND agh.MonthDate <= @ToDate
	)
	SELECT c.MonthDate
		,c.GroupId
        ,cg.GroupName
		,c.AffId
		,c.ParentAffId
		,c.AllParentAffId
		,gt.GroupTypeName
		,gt.GroupTypeBy
	FROM CTE_CommGroup c
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON c.GroupId = cg.GroupId
		INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON gt.GroupTypeId = cg.GroupTypeId
