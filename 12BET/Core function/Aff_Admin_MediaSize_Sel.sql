/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaSize_Sel]
AS

/*
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Media Gallery - Get Size

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		ROW_NUMBER() OVER(ORDER BY CONVERT(INT, h.val), CONVERT(INT, w.val)) AS SizeId
		,b.Value AS Size
	FROM dbo.BannerTypes_1 b WITH (NOLOCK)
		CROSS APPLY (SELECT * FROM dbo.strSplit(b.Value, 'x') WHERE [rank] = 1) h -- height
		CROSS APPLY (SELECT * FROM dbo.strSplit(b.Value, 'x') WHERE [rank] = 2) w -- weight
	WHERE Type = 'Size'
	ORDER BY SizeId
END
GO