/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MediaType_Sel]
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Media Gallery - Get Type

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT TypeId, Type
	FROM dbo.Aff_f_MediaType_Sel()
	ORDER BY Type
END
GO