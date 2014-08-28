USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetClickStatisticsNew_Func]    Script Date: 7/14/2014 4:27:51 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[Aff_GetClickStatisticsNew_Func]
(
	@AffId int, 
	@FromDate smalldatetime,
	@ToDate smalldatetime
)
RETURNS @Result TABLE 
(
	DeviceType tinyint,
	TotalClicks int, 
	UniqueClicks int
)
AS
BEGIN
	
	INSERT @Result
	SELECT DeviceType
		,sum(TotalClick) AS TotalClick
		,sum(UniqueClick) AS UniqueClick
	FROM (
		SELECT DeviceType
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM ClickStatistics1Sum WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate
				AND @ToDate
			AND AffId = @AffID
		GROUP BY DeviceType
		
		UNION ALL
		SELECT DeviceType
			,sum(1) AS TotalClick
			,count(DISTINCT IP) AS UniqueClick
		FROM ClickStatistics1 cs WITH (NOLOCK)
		WHERE [Date] BETWEEN @FromDate
				AND @ToDate
			AND AffId = @AffID
		GROUP BY DeviceType, [Date]
		) tmp
	GROUP BY DeviceType

	RETURN 
END