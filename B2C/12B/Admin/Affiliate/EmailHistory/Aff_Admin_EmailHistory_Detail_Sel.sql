/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_EmailHistory_Detail_Sel]
	@MID INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Affiliate - Email History - Search Email by ID


	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/

BEGIN
	SET NOCOUNT ON

	SELECT MID, Content, Sender, Email, Subject, CreatedDate
	FROM dbo.EmailHistory WITH (NOLOCK)
	WHERE MID = @MID
		AND ISNULL(IsDeleted, 0) = 0
END
GO