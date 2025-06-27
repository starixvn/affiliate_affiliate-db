/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_API_AffMediaChannel_Sel]
AS
/*
	Created: 20250625@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Get AffMediaChannel Info

	Revisions:
		- 20250625@Sally: Initialize SP [RedmineID: #230555]


*/
BEGIN
	SET NOCOUNT ON;

	-- Return AffMediaChannel data 
	SELECT DISTINCT
		amc.ChannelCode,
		amc.ChannelName
	FROM dbo.AffMediaChannel amc WITH (NOLOCK)
	WHERE amc.IsDeleted = 0
END
GO