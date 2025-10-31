/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_DealVerifyFlags_Sel]()
RETURNS TABLE
AS

/*
	Created: 20251023@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: function - Get Deal verify Config 

	Revisions:
		- 20251023@Sally: Initialize Function [RedmineID: #242398]

*/
RETURN (
 	SELECT c.GroupId AS DealId, d.DealName, d.DealVerifyFlags
	FROM (
		VALUES ('NoCommission-CPA', 1)
	) AS d(DealName, DealVerifyFlags)
	INNER JOIN dbo.CommGroup c WITH(NOLOCK) ON c.GroupName = d.DealName 
)

	
