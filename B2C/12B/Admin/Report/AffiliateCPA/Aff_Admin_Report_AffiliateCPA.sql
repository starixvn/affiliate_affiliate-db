/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Report_AffiliateCPA]
	@Username NVARCHAR(100) = ''
	,@Dealname NVARCHAR(MAX) = '' --list groupids
	,@Viewby TINYINT = 1
	,@FromDate DATETIME = ''
	,@ToDate DATETIME = ''
	,@SortType TINYINT = 1
	,@SortDirectionType	BIT = 0
	,@IsExportExcel BIT = 0
	,@PageIndex INT = 1
	,@PageSize INT = 20
	,@NRows INT = 0 OUTPUT
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Rpt - AffiliateCPA

	Revisions:
		- 20250526@Lewis: Initialize SP [RedmineID: #228530]

	Parameter's Explanation:
		- @Viewby: 1 Active Qualified Date
				   2 Holding Qualified Date
				   3 Approval Date
		- @SortType:
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		
*/
BEGIN
	SET NOCOUNT ON;
	-- TODO: Validate Input
	
	DECLARE @Deals TABLE (GroupId INT)
	INSERT INTO @Deals (GroupId)
	SELECT CAST(f.value AS INT)
	FROM string_split(@DealName,',') f

	-- TODO: #data
	CREATE TABLE #data
	(
		[Month]                NVARCHAR(50),
		[AffId]                INT,
		[AffUsername]          VARCHAR(50),
		[GroupId]              INT,
		[GroupName]            VARCHAR(100),
		[GroupTypeId]          INT,
		[ScheduleId]           INT,
		[PaymentFrequency]     VARCHAR(50),
		[Quota]                SMALLINT,
		[CurrentQuota]         SMALLINT,
		[CPAAmount]            DECIMAL(18,2),
		[EstimatedCPAAmount]   DECIMAL(18,2),
		[ApprovedCPAAmount]    DECIMAL(18,2)
	);
	
	IF @Viewby = 1
	BEGIN
		INSERT INTO #data
		(
			[Month],
			[AffId],
			[AffUsername],
			[GroupId],
			[GroupName],
			[GroupTypeId],
			[ScheduleId],
			[PaymentFrequency],
			[Quota],
			[CurrentQuota],
			[CPAAmount],
			[EstimatedCPAAmount],
			[ApprovedCPAAmount]
		)
		SELECT CONVERT(NVARCHAR(10), MONTH(m.ActiveQualifiedDate)) + '/' + CONVERT(NVARCHAR(10), YEAR(m.ActiveQualifiedDate)),
			m.AffId,
			a.Username,
			m.GroupId,
			c.GroupName,
			c.GroupTypeId,
			c.ScheduleId,
			s.ScheduleName,
			c.Quota,
			COUNT(CASE WHEN m.StatusId = 2 THEN 1 ELSE 0 END),
			SUM(m.CPAAmount),
			SUM(CASE WHEN m.StatusId IN (2,3)  THEN m.CPAAmount ELSE 0 END),
			SUM(CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END)
		FROM dbo.MemberCPA m WITH (NOLOCK)
			INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON m.AffId = a.AffId
			INNER JOIN dbo.CommGroup c WITH (NOLOCK) ON m.GroupId = c.GroupId AND c.IsDeleted = 0
			INNER JOIN dbo.Schedule s WITH (NOLOCK) ON c.ScheduleId = s.ScheduleId
		WHERE (a.Username LIKE '%' + @Username + '%' OR ISNULL(@Username, '') = '')
			AND m.ActiveQualifiedDate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM @Deals d WHERE d.GroupId = c.GroupId)
		GROUP BY CONVERT(NVARCHAR(10), MONTH(m.ActiveQualifiedDate)) + '/' + CONVERT(NVARCHAR(10), YEAR(m.ActiveQualifiedDate)), m.AffId, a.Username, m.GroupId, c.GroupName, c.GroupTypeId, c.ScheduleId, s.ScheduleName, c.Quota
	END

	IF @Viewby = 2
	BEGIN
		INSERT INTO #data
		(
			[Month],
			[AffId],
			[AffUsername],
			[GroupId],
			[GroupName],
			[GroupTypeId],
			[ScheduleId],
			[PaymentFrequency],
			[Quota],
			[CurrentQuota],
			[CPAAmount],
			[EstimatedCPAAmount],
			[ApprovedCPAAmount]
		)
		SELECT CONVERT(NVARCHAR(10), MONTH(m.HoldingQualifiedDate)) + '/' + CONVERT(NVARCHAR(10), YEAR(m.HoldingQualifiedDate)),
			m.AffId,
			a.Username,
			m.GroupId,
			c.GroupName,
			c.GroupTypeId,
			c.ScheduleId,
			s.ScheduleName,
			c.Quota,
			COUNT(CASE WHEN m.StatusId = 2 THEN 1 ELSE 0 END),
			SUM(m.CPAAmount),
			SUM(CASE WHEN m.StatusId IN (2,3) THEN m.CPAAmount ELSE 0 END),
			SUM(CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END)
		FROM dbo.MemberCPA m WITH (NOLOCK)
			INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON m.AffId = a.AffId
			INNER JOIN dbo.CommGroup c WITH (NOLOCK) ON m.GroupId = c.GroupId AND c.IsDeleted = 0
			INNER JOIN dbo.Schedule s WITH (NOLOCK) ON c.ScheduleId = s.ScheduleId
		WHERE (a.Username LIKE '%' + @Username + '%' OR ISNULL(@Username, '') = '')
			AND m.HoldingQualifiedDate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM @Deals d WHERE d.GroupId = c.GroupId)
		GROUP BY CONVERT(NVARCHAR(10), MONTH(m.HoldingQualifiedDate)) + '/' + CONVERT(NVARCHAR(10), YEAR(m.HoldingQualifiedDate)), m.AffId, a.Username, m.GroupId, c.GroupName, c.GroupTypeId, c.ScheduleId, s.ScheduleName, c.Quota;
	END

	IF @Viewby = 3
	BEGIN
		INSERT INTO #data
		(
			[Month],
			[AffId],
			[AffUsername],
			[GroupId],
			[GroupName],
			[GroupTypeId],
			[ScheduleId],
			[PaymentFrequency],
			[Quota],
			[CurrentQuota],
			[CPAAmount],
			[EstimatedCPAAmount],
			[ApprovedCPAAmount]
		)
		SELECT CONVERT(NVARCHAR(10), MONTH(m.CPADate)) + '/' + CONVERT(NVARCHAR(10), YEAR(m.CPADate)),
			m.AffId,
			a.Username,
			m.GroupId,
			c.GroupName,
			c.GroupTypeId,
			c.ScheduleId,
			s.ScheduleName,
			c.Quota,
			COUNT(CASE WHEN m.StatusId = 2 THEN 1 ELSE 0 END),
			SUM(m.CPAAmount),
			SUM(CASE WHEN m.StatusId IN (2,3) THEN m.CPAAmount ELSE 0 END),
			SUM(CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END)
		FROM dbo.MemberCPA m WITH (NOLOCK)
			INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON m.AffId = a.AffId
			INNER JOIN dbo.CommGroup c WITH (NOLOCK) ON m.GroupId = c.GroupId AND c.IsDeleted = 0
			INNER JOIN dbo.Schedule s WITH (NOLOCK) ON c.ScheduleId = s.ScheduleId
		WHERE (a.Username LIKE '%' + @Username + '%' OR ISNULL(@Username, '') = '')
			AND m.CPADate BETWEEN @FromDate AND @ToDate
			AND EXISTS (SELECT 1 FROM @Deals d WHERE d.GroupId = c.GroupId)
		GROUP BY CONVERT(NVARCHAR(10), MONTH(m.CPADate)) + '/' + CONVERT(NVARCHAR(10), YEAR(m.CPADate)), m.AffId, a.Username, m.GroupId, c.GroupName, c.GroupTypeId, c.ScheduleId, s.ScheduleName, c.Quota;
	END

	-- TODO: Result
	-- Use @SortType and @SortDirectionType for dynamic ordering
	IF @IsExportExcel = 1
	BEGIN
		;WITH Ordered AS (
		   SELECT 
			   [Month],
			   [AffId],
			   [AffUsername],
			   [GroupId],
			   [GroupName],
			   [GroupTypeId],
			   [ScheduleId],
			   [PaymentFrequency],
			   CAST([CurrentQuota] AS NVARCHAR(10)) + '/' + CAST([Quota] AS NVARCHAR(10)) AS Quota,
			   [CPAAmount],
			   [EstimatedCPAAmount],
			   [ApprovedCPAAmount],
			   ROW_NUMBER() OVER (
				   ORDER BY
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN [Month] END ASC,
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN [Month] END DESC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN [AffUsername] END ASC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN [AffUsername] END DESC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN [GroupName] END ASC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN [GroupName] END DESC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN GroupTypeId END ASC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN GroupTypeId END DESC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 0 THEN [PaymentFrequency] END ASC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 1 THEN [PaymentFrequency] END DESC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 0 THEN [Quota] END ASC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 0 THEN [CurrentQuota] END ASC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 1 THEN [Quota] END DESC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 1 THEN [CurrentQuota] END DESC,
					   CASE WHEN @SortType = 7 AND @SortDirectionType = 0 THEN [CPAAmount] END ASC,
					   CASE WHEN @SortType = 7 AND @SortDirectionType = 1 THEN [CPAAmount] END DESC,
					   CASE WHEN @SortType = 8 AND @SortDirectionType = 0 THEN [EstimatedCPAAmount] END ASC,
					   CASE WHEN @SortType = 8 AND @SortDirectionType = 1 THEN [EstimatedCPAAmount] END DESC,
					   CASE WHEN @SortType = 9 AND @SortDirectionType = 0 THEN [ApprovedCPAAmount] END ASC,
					   CASE WHEN @SortType = 9 AND @SortDirectionType = 1 THEN [ApprovedCPAAmount] END DESC
			   ) AS Rid
		   FROM #data
	   )
	   SELECT 
		   [Month],
		   [AffId],
		   [AffUsername] AS Affiliate,
		   [GroupId],
		   [GroupName] AS Dealname,
		   o.GroupTypeId,
		   g.GroupTypeName AS Dealtype,
		   [ScheduleId],
		   [PaymentFrequency],
		   [Quota],
		   [CPAAmount],
		   [EstimatedCPAAmount],
		   [ApprovedCPAAmount]
	   FROM Ordered o
	   INNER JOIN dbo.GroupType g WITH (NOLOCK) ON o.GroupTypeId = g.GroupTypeId
	   ORDER BY Rid;
	END
	ELSE
	BEGIN
		;WITH Ordered AS (
		   SELECT 
			   [Month],
			   [AffId],
			   [AffUsername],
			   [GroupId],
			   [GroupName],
			   [GroupTypeId],
			   [ScheduleId],
			   [PaymentFrequency],
			   CAST([CurrentQuota] AS NVARCHAR(10)) + '/' + CAST([Quota] AS NVARCHAR(10)) AS Quota,
			   [CPAAmount],
			   [EstimatedCPAAmount],
			   [ApprovedCPAAmount],
			   ROW_NUMBER() OVER (
				   ORDER BY
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN [Month] END ASC,
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN [Month] END DESC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN [AffUsername] END ASC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN [AffUsername] END DESC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN [GroupName] END ASC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN [GroupName] END DESC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN GroupTypeId END ASC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN GroupTypeId END DESC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 0 THEN [PaymentFrequency] END ASC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 1 THEN [PaymentFrequency] END DESC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 0 THEN [Quota] END ASC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 0 THEN [CurrentQuota] END ASC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 1 THEN [Quota] END DESC,
					   CASE WHEN @SortType = 6 AND @SortDirectionType = 1 THEN [CurrentQuota] END DESC,
					   CASE WHEN @SortType = 7 AND @SortDirectionType = 0 THEN [CPAAmount] END ASC,
					   CASE WHEN @SortType = 7 AND @SortDirectionType = 1 THEN [CPAAmount] END DESC,
					   CASE WHEN @SortType = 8 AND @SortDirectionType = 0 THEN [EstimatedCPAAmount] END ASC,
					   CASE WHEN @SortType = 8 AND @SortDirectionType = 1 THEN [EstimatedCPAAmount] END DESC,
					   CASE WHEN @SortType = 9 AND @SortDirectionType = 0 THEN [ApprovedCPAAmount] END ASC,
					   CASE WHEN @SortType = 9 AND @SortDirectionType = 1 THEN [ApprovedCPAAmount] END DESC
			   ) AS Rid
		   FROM #data
	   )
	   SELECT 
		   [Month],
		   [AffId],
		   [AffUsername] AS Affiliate,
		   [GroupId],
		   [GroupName] AS Dealname,
		   o.GroupTypeId,
		   g.GroupTypeName AS Dealtype,
		   [ScheduleId],
		   [PaymentFrequency],
		   [Quota],
		   [CPAAmount],
		   [EstimatedCPAAmount],
		   [ApprovedCPAAmount]
	   FROM Ordered o
	   INNER JOIN dbo.GroupType g WITH (NOLOCK) ON o.GroupTypeId = g.GroupTypeId
	   WHERE Rid > (@PageSize * (@PageIndex - 1))
		 AND Rid <= (@PageSize * @PageIndex)
	   ORDER BY Rid;
	END

	-- Output total rows if needed
	SELECT @NRows = COUNT(*) FROM #data;
	
	SELECT 
		SUM([CPAAmount]) AS CPAAmount,
		SUM([EstimatedCPAAmount]) AS EstimatedCPAAmount,
		SUM([ApprovedCPAAmount]) AS ApprovedCPAAmount
	FROM #data;

	DROP TABLE #data;
END
GO