/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Sel]
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
	Created: 20160614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Payment Request - View payment request list

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]

	Param's Explanation:
		- @SearchById
						= 1: Username (@Username)
						= 2: Others (@Status, @IsGetAll, @FromDate, @ToDate)
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Username = ISNULL(@Username, ''), @Status = ISNULL(@Status, ''), @IsGetAll = ISNULL(@IsGetAll, 0)

	IF @SearchById = 1
		SELECT @IsGetAll = 1

	DECLARE @tblTransID TABLE (TransID BIGINT PRIMARY KEY)
	INSERT INTO @tblTransID (TransID)
	SELECT TransID
	FROM dbo.AffTrans WITH (NOLOCK)
	WHERE TransType = 202 -- payment request

	DECLARE @tblResultTransID TABLE (TransID BIGINT PRIMARY KEY)
	INSERT INTO @tblResultTransID (TransID)
	SELECT t.TransID
	FROM @tblTransID t
		CROSS APPLY (
			SELECT TOP 1 a.AffID, a.Creator, a.Status, a.TransDate
			FROM dbo.AffTrans a WITH (NOLOCK)
			WHERE t.TransID = a.TransID
		) AS a
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON a.AffID = ai.AffID
	WHERE
		(@Username = '' OR ai.UserName LIKE '%' + @Username + '%')
		AND (@Status = '' OR a.Status = @Status)
		AND (@IsGetAll = 1 OR (a.TransDate >= @FromDate AND a.TransDate < DATEADD(DAY, 1, @ToDate)))

	SELECT @NRows = @@ROWCOUNT
	
	IF @NRows = 0
		RETURN

	-- Return result
	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1
			,@RowEnd = @RowStart + @PageSize - 1
	
	SELECT TransID, TransDate, AffID, UserName, Amount, Status, CompletedDate, Creator
	FROM (
		SELECT t.TransID, a.TransDate, ai.AffID, ai.UserName, a.Amount, a.Status, a.CompletedDate
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
				SELECT TOP 1 a.AffID, a.Creator, a.Status, a.TransDate, ABS(a.Amount) AS Amount, a.CompletedDate
				
				FROM dbo.AffTrans a WITH (NOLOCK)
				WHERE t.TransID = a.TransID
			) AS a
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON a.AffID = ai.AffID
			LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON a.Creator = au.custid
	) AS r
	WHERE RN BETWEEN @RowStart AND @RowEnd
	ORDER BY RN
END
GO