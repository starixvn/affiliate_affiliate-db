/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_CommSetting_Sel]
	@AffID INT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: User site - Get current commission setting

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @GroupId INT
	SELECT  @GroupId = GroupId
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE AffID = @AffId

	SELECT TierID, MinAmount, MaxAmount, MinQM, MaxQM, Commission
	FROM dbo.GroupSetting WITH (NOLOCK)
	WHERE GroupID = @GroupId
END
GO