/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_EmailHistory_Detail_Sel]
	@MID INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin - Affiliate - Email History - Search Email by ID


	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT MID, Content, Sender, Email, Subject, CreatedDate
	FROM dbo.EmailHistory WITH (NOLOCK)
	WHERE MID = @MID
		AND ISNULL(IsDeleted, 0) = 0
END
GO