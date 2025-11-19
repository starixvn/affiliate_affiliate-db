/*<info serverAlias="DBAFF12B-Affiliate_12B" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_LandingPagePreview_Archive]
AS

/*
	Created: 20250922@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Job - Archive Landing Page Preview Data

	Revisions:
		- 20250922@Sophia: Initialize SP [RedmineID: #236797]

*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @Yesterday DATETIME;
	SELECT @Yesterday = DATEADD(DAY, -1, CAST(DATEADD(HOUR, 8, GETUTCDATE()) AS DATE));

	-- Delete from LandingPage_BuilderDetail_Preview and LandingPage_Builder_Preview 
	DELETE d
	FROM dbo.LandingPage_BuilderDetail_Preview d WITH (ROWLOCK, UPDLOCK)
	INNER JOIN dbo.LandingPage_Builder_Preview b WITH (NOLOCK) ON d.PageID = b.PageID
	WHERE b.CreatedDate <= @Yesterday;

	DELETE b
	FROM dbo.LandingPage_Builder_Preview b WITH (ROWLOCK, UPDLOCK)
	WHERE b.CreatedDate <= @Yesterday;
END;
GO