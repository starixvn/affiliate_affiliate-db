/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ClickStatisticsPatterns_Sel]
	@FromDate		DATE
	,@ToDate		DATE
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT

AS
/*
	Created: 20251022@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Select ClickStatistics data by date range [RedmineId: #241768]

	Revisions:  
		- 20251022@Sophia: Initialize SP to select ClickStatistics data [RedmineID: #241768]

*/
BEGIN
	SET NOCOUNT ON;

		-- Select ClickStatistics data
		SELECT 
			ClickId,
			UserAgent,
			IP,
			IsExcluded,
			Date
		FROM dbo.ClickStatistics WITH (NOLOCK)
		WHERE Date >= @FromDate AND Date < @ToDate
		ORDER BY ClickId ASC;		
END
GO