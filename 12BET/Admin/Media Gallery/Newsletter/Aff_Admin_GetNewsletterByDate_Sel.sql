/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_GetNewsletterByDate_Sel]
	@Date DATETIME
AS

/*
	Created: 20210204@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Newsletter - get newsletter following date

	Revisions:
		- 20210204@Malcolm: Initialize SP [RedmineID: #145276]

	Param's Explanation:

*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @MaxDateTo DATETIME

	IF EXISTS(SELECT TOP 1 1 FROM dbo.Newsletter WITH(NOLOCK) WHERE @Date BETWEEN EffectiveFromDate AND EffectiveToDate)
	BEGIN
		SELECT n.NewsletterId, n.FileName, n.FileSize, n.Language, m.DisplayName AS LanguageName, n.UploadDate, n.EffectiveFromDate, n.EffectiveToDate
		FROM dbo.Newsletter n WITH(NOLOCK)
			INNER JOIN dbo.Market m WITH(NOLOCK) ON n.Language = m.MarketID
		WHERE @Date BETWEEN EffectiveFromDate AND EffectiveToDate
		ORDER BY UploadDate DESC
	END
	ELSE
	BEGIN
		SELECT @MaxDateTo = MAX(n.EffectiveToDate)
		FROM dbo.Newsletter n WITH(NOLOCK)

		SELECT n.NewsletterId, n.FileName, n.FileSize, n.Language, m.DisplayName AS LanguageName, n.UploadDate, n.EffectiveFromDate, n.EffectiveToDate
		FROM dbo.Newsletter n WITH(NOLOCK)
			INNER JOIN dbo.Market m WITH(NOLOCK) ON n.Language = m.MarketID
		WHERE EffectiveToDate = @MaxDateTo
		ORDER BY UploadDate DESC
	END
END
GO