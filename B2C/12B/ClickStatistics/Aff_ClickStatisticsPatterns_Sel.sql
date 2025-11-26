/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ClickStatisticsPatterns_Sel]
	@FromDate		DATE
	,@ToDate		DATE
	,@IsExcluded	BIT = NULL
	,@UserAgent		NVARCHAR(256) = NULL
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT

AS
/*
	Created: 20251022@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Select ClickStatistics data by date range [RedmineId: #241768]

	Revisions:  
		- 20251022@Sophia: Initialize SP to select ClickStatistics data [RedmineID: #241768]
		- 20251125@Sally: Add @IsExcluded and @UserAgent filters [RedmineID: #245109]

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
			AND (@IsExcluded IS NULL OR IsExcluded = @IsExcluded)
			AND (@UserAgent IS NULL OR UserAgent LIKE '%' + @UserAgent + '%')
		ORDER BY ClickId ASC;		
END
GO