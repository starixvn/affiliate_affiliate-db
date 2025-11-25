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
		- 20251113@Sally: Add new Deal with DealVerifyFlags = 1 [RedmineID: #244127]

*/
RETURN (
 	SELECT c.GroupId AS DealId, d.DealName, d.DealVerifyFlags
	FROM (
		VALUES ('NoCommission-CPA', 1)
			,('PO $35, BL Cum $8, Wager 3X, Re-dep 30%', 1)
	) AS d(DealName, DealVerifyFlags)
	INNER JOIN dbo.CommGroup c WITH(NOLOCK) ON c.GroupName = d.DealName AND c.IsDeleted = 0
)

	
