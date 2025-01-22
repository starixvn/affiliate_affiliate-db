/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_CheckMaxSubAffLevel]
	@AffId INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Check Max Sub Affiliate Level

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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