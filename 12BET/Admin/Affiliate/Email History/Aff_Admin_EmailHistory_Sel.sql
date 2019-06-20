/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_EmailHistory_Sel]
	@SearchById		TINYINT = 0
	,@SearchText	NVARCHAR(MAX) = NULL
	,@IsGetAll		BIT = 1
	,@FromDate		SMALLDATETIME = NULL
	,@ToDate		SMALLDATETIME = NULL
	,@PageSize		INT = 50
	,@PageIndex		INT = 1
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20190614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Email History - Select all or by Mail ID

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]

	Param's Explanation:
		- @SearchById:
			 0 = All
			 1 = Sender (search like)
			 2 = Email Address (search like)
			 3 = Affiliate (search exactly)
			 4 = Unknown Affiliate
		- @IsGetAll
			 0 = base on @FromDate and @ToDate
			 1 = get all
*/

BEGIN
	SET NOCOUNT ON

	SELECT @SearchById = ISNULL(@SearchById, 0), @SearchText = ISNULL(@SearchText, '')

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	IF @SearchById IN (1,2,3) AND @SearchText = ''
		SELECT @SearchById = 0

	DECLARE @tblMailID	TABLE (MID INT NOT NULL PRIMARY KEY)

	-- Search by Affiliate
	IF @SearchById = 3
	BEGIN
		IF @IsGetAll = 1
		BEGIN
			INSERT INTO @tblMailID (MID)
			SELECT MID
			FROM (
				SELECT MID, ROW_NUMBER() OVER(ORDER BY CreatedDate DESC) AS RN
				FROM dbo.EmailHistory WITH (NOLOCK)
				WHERE AffName = @SearchText
					AND ISNULL(IsDeleted, 0) = 0
			) AS r
			WHERE RN BETWEEN @RowStart AND @RowEnd
		END
		ELSE
		BEGIN
			INSERT INTO @tblMailID (MID)
			SELECT MID
			FROM (
				SELECT MID, ROW_NUMBER() OVER(ORDER BY CreatedDate DESC) AS RN
				FROM dbo.EmailHistory WITH (NOLOCK)
				WHERE AffName = @SearchText
					AND CreatedDate BETWEEN @FromDate AND @ToDate
					AND ISNULL(IsDeleted, 0) = 0
			) AS r
			WHERE RN BETWEEN @RowStart AND @RowEnd
		END
	END
	ELSE
	BEGIN
		SELECT @SearchText = '%' + @SearchText + '%'
		
		IF @IsGetAll = 1
		BEGIN
			INSERT INTO @tblMailID (MID)
			SELECT MID
			FROM (
				SELECT MID, ROW_NUMBER() OVER(ORDER BY CreatedDate DESC) AS RN
				FROM dbo.EmailHistory WITH (NOLOCK)
				WHERE
					(
						@SearchById = 0
						OR (@SearchById = 1 AND Sender LIKE @SearchText)
						OR (@SearchById = 2 AND Email LIKE @SearchText)
						OR (@SearchById = 4 AND AffId = -1) -- unknown affiliate
					)
					AND ISNULL(IsDeleted, 0) = 0
			) AS r
			WHERE RN BETWEEN @RowStart AND @RowEnd
		END
		ELSE
		BEGIN
			INSERT INTO @tblMailID (MID)
			SELECT MID
			FROM (
				SELECT MID, ROW_NUMBER() OVER(ORDER BY CreatedDate DESC) AS RN
				FROM dbo.EmailHistory WITH (NOLOCK)
				WHERE CreatedDate BETWEEN @FromDate AND @ToDate
					AND (
						@SearchById = 0
						OR (@SearchById = 1 AND Sender LIKE @SearchText)
						OR (@SearchById = 2 AND Email LIKE @SearchText)
						OR (@SearchById = 4 AND AffId = -1) -- unknown affiliate
					)
					AND ISNULL(IsDeleted, 0) = 0
			) AS r
			WHERE RN BETWEEN @RowStart AND @RowEnd
		END
	END

	SELECT @NRows = COUNT(1) FROM @tblMailID

	IF @NRows = 0
		RETURN

	-- Return data
	SELECT e.MID, e.Sender, e.AffName, e.Email, e.Subject, e.CreatedDate
	FROM @tblMailID tmp
		CROSS APPLY (
			SELECT MID, Sender, AffName, Email, Subject, CreatedDate
			FROM dbo.EmailHistory e WITH (NOLOCK)
			WHERE tmp.MID = e.MID
		) AS e
	ORDER BY CreatedDate DESC
END
GO