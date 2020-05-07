/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_EmailHistory_Detail_Sel]
	@MID INT
AS

/*
	Created: 20190614@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: Admin - Affiliate - Email History - Search Email by ID

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
*/

BEGIN
	SET NOCOUNT ON

	SELECT MID, Content, Sender, Email, Subject, CreatedDate
	FROM dbo.EmailHistory WITH (NOLOCK)
	WHERE MID = @MID
		AND ISNULL(IsDeleted, 0) = 0
END
GO