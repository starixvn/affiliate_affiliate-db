/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_ClickStatistics_MaxClickId_Sel]
AS
/*
	Created: 20250725@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Cache data

	Revisions:  
		- 20250725@Lewis: Initialize SP [RedmineID: #233088]
*/
BEGIN
    SET NOCOUNT ON;
    SELECT MAX(ClickId) AS MaxClickId FROM dbo.ClickStatistics WITH (NOLOCK);
END