/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_CommGroupSelListNormal]
	@AffID INT = -1,
	@GroupID INT = -1 OUTPUT
AS

/*
	Created: 20090719@DungTong
	Task: Get Commission Group List (groupid < 1000) for dropdown list
	DB: DB052.Affiliate_12Bet
	Original:

	Revisions:
		- 20180601@Percy: Flexible new setting [RemineID: #87923]
*/

BEGIN
	SET NOCOUNT ON
	
	IF @AffID <> -1
		SELECT @GroupID = GroupID FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffID

	SELECT GroupId, GroupName
	FROM dbo.CommGroup cg WITH (NOLOCK)
	WHERE GroupID < 1000
		AND IsDeleted = 0
		AND EXISTS (SELECT 1 FROM dbo.GroupSetting gs WITH (NOLOCK) WHERE cg.GroupId = gs.GroupId)
END	 
GO