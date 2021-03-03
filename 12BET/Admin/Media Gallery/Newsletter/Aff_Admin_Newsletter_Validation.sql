/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet, bodbDownlineNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Newsletter_Validation]
	@FileNames NVARCHAR(MAX) =''
AS

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Newsletter

	Revisions:
		- 20210204@Malcolm: Initialize SP [RedmineID: #145276]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT f.val AS [FileName]
	FROM dbo.strSplit(@FileNames, ',') f
	WHERE NOT EXISTS (SELECT TOP 1 1 FROM dbo.Newsletter n WITH(NOLOCK) WHERE n.FileName = f.val)

END
GO