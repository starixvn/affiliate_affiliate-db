/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Report_AffiliateCPA]
	@AffId				INT
	,@StatusId			SMALLINT = -1
	,@Viewby			TINYINT = 1
	,@FromDate			DATETIME = ''
	,@ToDate			DATETIME = ''
	,@SortType			TINYINT = 1
	,@SortDirectionType	BIT = 0
	,@IsExportExcel		BIT = 0
	,@PageIndex			INT = 1
	,@PageSize			INT = 20
	,@NRows				INT = 0 OUTPUT
AS
/*
	Created: 20250822@Danny
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Rpt - AffiliateCPA

	Revisions:
		- 20250822@Danny: Initialize SP [RedmineID: #236669]

	Parameter's Explanation:
		- @StatusId: 0  Pending
					 1  Ineligibled
					 2  Eligibled
					 3  Approved
				     4  Rejected
					 5  Exceed
		
		- @Viewby: 1 Active Qualified Date
				   2 Holding Qualified Date
				   3 Approval Date
		
		
*/
BEGIN
	SET NOCOUNT ON;
	-- TODO: Validate Input

	-- TODO: #data
	CREATE TABLE #data
	(
		[Month]                NVARCHAR(50),
		[GroupTypeId]          INT,
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
			[GroupTypeId],
			[Quota],
			[CurrentQuota],
			[CPAAmount],
			[EstimatedCPAAmount],
			[ApprovedCPAAmount]
		)
		SELECT FORMAT(m.HoldingQualifiedDate, 'MM/yyyy'),
			c.GroupTypeId,
			c.Quota,
			COUNT(CASE WHEN m.StatusId = 2 THEN 1 ELSE 0 END),
			SUM(m.CPAAmount),
			SUM(CASE WHEN m.StatusId IN (2,3) THEN m.CPAAmount ELSE 0 END),
			SUM(CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END)
		FROM dbo.MemberCPA m WITH (NOLOCK)
			INNER JOIN dbo.CommGroup c WITH (NOLOCK) ON m.GroupId = c.GroupId
			INNER JOIN dbo.Schedule s WITH (NOLOCK) ON c.ScheduleId = s.ScheduleId
		WHERE m.AffId = @AffId
			AND m.ActiveQualifiedDate BETWEEN @FromDate AND @ToDate
			AND (@StatusId = -1 OR m.StatusId = @StatusId)
		GROUP BY FORMAT(m.HoldingQualifiedDate, 'MM/yyyy'),c.GroupTypeId, c.Quota
	END

	IF @Viewby = 2
	BEGIN
		INSERT INTO #data
		(
			[Month],
			[GroupTypeId],
			[Quota],
			[CurrentQuota],
			[CPAAmount],
			[EstimatedCPAAmount],
			[ApprovedCPAAmount]
		)
		SELECT 
			FORMAT(m.HoldingQualifiedDate, 'MM/yyyy'),
			c.GroupTypeId,
			c.Quota,
			COUNT(CASE WHEN m.StatusId = 2 THEN 1 ELSE 0 END),
			SUM(m.CPAAmount),
			SUM(CASE WHEN m.StatusId IN (2,3) THEN m.CPAAmount ELSE 0 END),
			SUM(CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END)
		FROM dbo.MemberCPA m WITH (NOLOCK)
			INNER JOIN dbo.CommGroup c WITH (NOLOCK) ON m.GroupId = c.GroupId
			INNER JOIN dbo.Schedule s WITH (NOLOCK) ON c.ScheduleId = s.ScheduleId
		WHERE m.AffId = @AffId
			AND m.HoldingQualifiedDate BETWEEN @FromDate AND @ToDate
			AND (@StatusId = -1 OR m.StatusId = @StatusId)
		GROUP BY FORMAT(m.HoldingQualifiedDate, 'MM/yyyy'), c.GroupTypeId, c.Quota;
	END

	IF @Viewby = 3
	BEGIN
		INSERT INTO #data
		(
			[Month],
			[GroupTypeId],
			[Quota],
			[CurrentQuota],
			[CPAAmount],
			[EstimatedCPAAmount],
			[ApprovedCPAAmount]
		)
		SELECT FORMAT(m.HoldingQualifiedDate, 'MM/yyyy'),
			c.GroupTypeId,
			c.Quota,
			COUNT(CASE WHEN m.StatusId = 2 THEN 1 ELSE 0 END),
			SUM(m.CPAAmount),
			SUM(CASE WHEN m.StatusId IN (2,3) THEN m.CPAAmount ELSE 0 END),
			SUM(CASE WHEN m.StatusId = 3 THEN m.CPAAmount ELSE 0 END)
		FROM dbo.MemberCPA m WITH (NOLOCK)
			INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON m.AffId = a.AffId
			INNER JOIN dbo.CommGroup c WITH (NOLOCK) ON m.GroupId = c.GroupId
			INNER JOIN dbo.Schedule s WITH (NOLOCK) ON c.ScheduleId = s.ScheduleId
		WHERE a.AffId = @AffId
			AND m.CPADate BETWEEN @FromDate AND @ToDate
			AND (@StatusId = -1 OR m.StatusId = @StatusId)
		GROUP BY FORMAT(m.HoldingQualifiedDate, 'MM/yyyy'), c.Quota, c.GroupTypeId;
	END

	-- TODO: Result
	-- Use @SortType and @SortDirectionType for dynamic ordering
	IF @IsExportExcel = 1
	BEGIN
		;WITH Ordered AS (
		   SELECT 
			   [Month],
			   [GroupTypeId],
			   CAST([CurrentQuota] AS NVARCHAR(10)) + '/' + CAST([Quota] AS NVARCHAR(10)) AS Quota,
			   [CPAAmount],
			   [EstimatedCPAAmount],
			   [ApprovedCPAAmount],
			   ROW_NUMBER() OVER (
				   ORDER BY
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN [Month] END ASC,
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN [Month] END DESC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN [Quota] END ASC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN [CurrentQuota] END ASC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN [Quota] END DESC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN [CurrentQuota] END DESC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN [CPAAmount] END ASC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN [CPAAmount] END DESC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN [EstimatedCPAAmount] END ASC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN [EstimatedCPAAmount] END DESC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 0 THEN [ApprovedCPAAmount] END ASC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 1 THEN [ApprovedCPAAmount] END DESC
			   ) AS Rid
		   FROM #data
	   )
	   SELECT 
		   [Month],
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
			   [GroupTypeId],
			   CAST([CurrentQuota] AS NVARCHAR(10)) + '/' + CAST([Quota] AS NVARCHAR(10)) AS Quota,
			   [CPAAmount],
			   [EstimatedCPAAmount],
			   [ApprovedCPAAmount],
			   ROW_NUMBER() OVER (
				   ORDER BY
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN [Month] END ASC,
					   CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN [Month] END DESC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN [Quota] END ASC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN [CurrentQuota] END ASC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN [Quota] END DESC,
					   CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN [CurrentQuota] END DESC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN [CPAAmount] END ASC,
					   CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN [CPAAmount] END DESC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN [EstimatedCPAAmount] END ASC,
					   CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN [EstimatedCPAAmount] END DESC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 0 THEN [ApprovedCPAAmount] END ASC,
					   CASE WHEN @SortType = 5 AND @SortDirectionType = 1 THEN [ApprovedCPAAmount] END DESC
			   ) AS Rid
		   FROM #data
	   )
	   SELECT 
		   [Month],
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
	SELECT @NRows = COUNT(1) FROM #data;
	
	SELECT 
		SUM([CPAAmount]) AS CPAAmount,
		SUM([EstimatedCPAAmount]) AS EstimatedCPAAmount,
		SUM([ApprovedCPAAmount]) AS ApprovedCPAAmount
	FROM #data;

	DROP TABLE #data;
END