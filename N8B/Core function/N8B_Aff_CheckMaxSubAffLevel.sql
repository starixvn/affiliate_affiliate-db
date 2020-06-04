/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_CheckMaxSubAffLevel]
	@AffId INT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Check Max Sub Affiliate Level

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MaxSubLevel INT
	SELECT  @MaxSubLevel = ISNULL(CONVERT(INT, SValue), 0) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'MaxSubLevel'

	SELECT ai.AffId, CASE WHEN ISNULL(SubAffLevel + 1, 0) > @MaxSubLevel THEN 1 ELSE 0 END AS IsMaxSubLevel
	FROM dbo.AffInfo ai WITH (NOLOCK)
		OUTER APPLY (SELECT COUNT(1) AS SubAffLevel FROM dbo.Aff_f_StringSplit(ai.AllParentAffId, ',')) s
	WHERE AffId = @AffId
		AND IsClosed = 0
END
GO