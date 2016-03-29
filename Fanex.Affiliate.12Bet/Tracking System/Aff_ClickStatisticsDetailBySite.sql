ALTER PROCEDURE [dbo].[Aff_ClickStatisticsDetailBySite] 
	@AffID INT
	,@Domain NVARCHAR(300) = NULL
	,@SportCode VARCHAR(50) = NULL
	,@LanguageCode VARCHAR(10) = NULL
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@DeviceType TINYINT = 0
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
	- 20140708@Bobby : Apply Device type info
	- 20140801@Bobby : Update checking DeviceType in ClickStatistics1_bk
	- 20141103@Bobby : Update checking DeviceType in ClickStatistics1_bk (change AND to OR)
	- 20160327@Bobby : #54942 - Correct time range
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LastDateSum SMALLDATETIME

	IF (@FromDate > @ToDate) RETURN

	DECLARE @Result AS TABLE (
		UrlReferrer NVARCHAR(300)
		,TotalClick INT
		,UniqueClick INT
		)

	SELECT @LastDateSum = (
			SELECT MAX(DATE)
			FROM ClickStatistics1Sum (NOLOCK)
			)
		,@FromDate = convert(VARCHAR(10), @FromDate, 120)
		,@ToDate = dbo.Aff_GetEndDate(@ToDate)

	SELECT @LastDateSum = isnull(@LastDateSum, dateadd(d, - 1, @FromDate))

	IF (@LastDateSum < @FromDate) --get from main table
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND DeviceType = @DeviceType
			GROUP BY URLReferrer
				,[Date]
			) AS t
		GROUP BY URLReferrer
	END
	ELSE IF (@LastDateSum > @ToDate) --get from bk table
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND ( 
					(@DeviceType = 0 AND (c.DeviceType = @DeviceType OR c.DeviceType IS NULL))
					OR 
					(@DeviceType = 1 AND c.DeviceType = @DeviceType)
				)
			GROUP BY URLReferrer
				,[Date]
			) AS t
		GROUP BY URLReferrer
	END
	ELSE --@fromdate < @LastDateSum < @ToDate
	BEGIN
		INSERT INTO @Result
		SELECT URLReferrer
			,sum(TotalClick) AS TotalClick
			,sum(UniqueClick) AS UniqueClick
		FROM (
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1_bk c WITH (NOLOCK)
			WHERE [Date] BETWEEN @FromDate
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND ( 
					(@DeviceType = 0 AND (c.DeviceType = @DeviceType OR c.DeviceType IS NULL))
					OR 
					(@DeviceType = 1 AND c.DeviceType = @DeviceType)
				)
			GROUP BY URLReferrer
				,[Date]
			
			UNION ALL
			SELECT URLReferrer
				,sum(1) AS TotalClick
				,count(DISTINCT IP) AS UniqueClick
			FROM ClickStatistics1 c WITH (NOLOCK)
			WHERE [Date] BETWEEN @LastDateSum
					AND @ToDate
				AND AffId = @AffID
				AND DomainReferrer = isnull(@Domain, DomainReferrer)
				AND SportCode = isnull(@SportCode, SportCode)
				AND LanguageCode = isnull(@LanguageCode, LanguageCode)
				AND DeviceType = @DeviceType
			GROUP BY URLReferrer
				,[Date]
			) tmp
		GROUP BY URLReferrer
	END

	--count nrows
	SELECT @NRows = count(1)
	FROM @Result

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1
		
	-- count stats Singups & FDM info
	;WITH memberStats
	AS (
		SELECT md.URLReferrer
			,COUNT(1) AS Signups
			,sum(CASE 
					WHEN md.IBCCustID IS NOT NULL THEN 1
					ELSE 0
					END) AS FDM
		FROM dbo.MemberClickDetail md WITH (NOLOCK)
		WHERE md.CreatedDate BETWEEN @FromDate AND @ToDate
			AND md.AffID = @AffID
			AND md.DeviceType = @DeviceType
			AND md.DomainReferrer = isnull(@Domain, DomainReferrer)
			AND md.SportCode = isnull(@SportCode, SportCode)
			AND md.LanguageCode = isnull(@LanguageCode, LanguageCode)
		GROUP BY md.URLReferrer
		)
	SELECT x.UrlReferrer
		,x.TotalClick
		,x.UniqueClick
		,ISNULL(m.Signups, 0) Signups
		,ISNULL(m.FDM, 0) FDM
	FROM (
		SELECT TOP (@RowEnd) ROW_NUMBER() OVER (
				ORDER BY URLReferrer
				) AS TheCount
			,*
		FROM @Result
		) x
		LEFT JOIN memberStats m ON x.UrlReferrer = m.URLReferrer
	WHERE x.TheCount BETWEEN @RowStart
			AND @RowEnd
END
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [bodbAdminNet]
GO

GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [bodbDownlineNet]
GO



