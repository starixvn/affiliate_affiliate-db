/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaType_Sel]
AS

/*
	Created: 20191010@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin - Media Gallery - Get Type

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TypeId, Type
	FROM dbo.Aff_f_MediaType_Sel()
	ORDER BY Type
END
GO