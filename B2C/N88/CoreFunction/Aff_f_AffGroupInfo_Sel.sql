/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_AffGroupInfo_Sel] (
	@FromDate	DATETIME,
	@ToDate		DATETIME,
	@AffIds		VARCHAR(MAX) = 'all'
)
RETURNS TABLE
AS

/*
	Created: 20240503@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core function - Get AffGroupInfo

	Revisions:
		- 20240503@Sally: Initialize SP  [RedmineID: #203756]

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
		,c.AffId
		,c.ParentAffId
		,c.AllParentAffId
		,gt.GroupTypeName
		,gt.GroupTypeBy
	FROM CTE_CommGroup c
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON c.GroupId = cg.GroupId
		INNER JOIN dbo.GroupType gt WITH (NOLOCK) ON gt.GroupTypeId = cg.GroupTypeId
