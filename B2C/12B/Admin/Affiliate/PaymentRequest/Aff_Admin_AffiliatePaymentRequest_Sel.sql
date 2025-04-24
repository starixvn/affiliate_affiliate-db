/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Sel]
	@SearchById	TINYINT = 1
	,@Username	NVARCHAR(30) = NULL
	,@Status	NVARCHAR(10) = NULL
	,@IsGetAll	BIT = 0
	,@FromDate	DATETIME = NULL
	,@ToDate	DATETIME = NULL
	,@PageSize	INT = 50
	,@PageIndex	INT = 1
	,@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Affiliate - Payment Request - View payment request list

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250404@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]

	Param's Explanation:
		- @SearchById
						= 1: Username (@Username)
						= 2: Others (@Status, @IsGetAll, @FromDate, @ToDate)
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Username = ISNULL(@Username, ''), @Status = ISNULL(@Status, ''), @IsGetAll = ISNULL(@IsGetAll, 0)

	IF @Status = 'Processing'
		SELECT @Status = 'Pending'

	IF @SearchById = 1
		SELECT @IsGetAll = 1

	DECLARE @tblResultTransID TABLE (TransID BIGINT PRIMARY KEY)
	;WITH CTE_tblTransID AS(
		SELECT a.TransID, a.Status, a.WinlostDate, a.AffId
		FROM dbo.AffTrans a WITH (NOLOCK)
		WHERE a.TransType = 202 -- payment request
	)
	INSERT INTO @tblResultTransID (TransID)
	SELECT a.TransID
	FROM CTE_tblTransID a
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON a.AffID = ai.AffID
	WHERE
		(@Username = '' OR ai.UserName LIKE '%' + @Username + '%')
		AND (@Status = '' OR a.Status = @Status)
		AND (@IsGetAll = 1 OR (a.WinlostDate >= @FromDate AND a.WinlostDate < DATEADD(DAY, 1, @ToDate)))

	SELECT @NRows = @@ROWCOUNT
	
	IF @NRows = 0
		RETURN

	-- Return result
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1
			,@RowEnd = @RowStart + @PageSize - 1
	
	SELECT TransId
		,DATEADD(HOUR, 12, TransDate) AS TransDate -- GMT-4 to GMT+8 
		,AffId, UserName, Amount, Status
		,DATEADD(HOUR, 12, CompletedDate) AS CompletedDate -- GMT-4 to GMT+8 
		,Creator
	FROM (
		SELECT
			t.TransId
			,a.TransDate
			,ai.AffId
			,ai.UserName
			,a.Amount
			,CASE a.Status
				WHEN 'Pending' THEN 'Processing'
				ELSE a.Status END AS Status
			,a.CompletedDate
			,CASE WHEN a.Creator = 148 THEN 'System' ELSE au.username END AS Creator
			,ROW_NUMBER() OVER(ORDER BY
										CASE a.Status
											WHEN 'Pending' THEN 1
											WHEN 'Approved' THEN 2
											WHEN 'Rejected' THEN 3
											ELSE 4 END
										,TransDate DESC) AS RN
		FROM @tblResultTransID t
			CROSS APPLY (
				SELECT TOP 1 a.AffId, a.Creator, a.Status, a.TransDate, ABS(a.Amount) AS Amount, a.CompletedDate
				FROM dbo.AffTrans a WITH (NOLOCK)
				WHERE t.TransId = a.TransId
			) AS a
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON a.AffId = ai.AffId
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON a.Creator = au.custid
	) AS r
	WHERE RN BETWEEN @RowStart AND @RowEnd
	ORDER BY RN
END
GO