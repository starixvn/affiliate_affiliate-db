/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_Affiliate_Sel] 
	@UserId 			INT,
	@GroupID 			INT				= 0,
	@PreferredLanguage	VARCHAR(10)		= '',
	@UserName 			NVARCHAR(50) 	= '',
	@Status				VARCHAR(30)		= '',
	@Email 				NVARCHAR(50) 	= '',
	@SortType			TINYINT			= 1,
	@SortDirectionType	BIT				= 0,
	@IsExportExcel		BIT				= 0,
	@PageSize 			INT 			= 50,
	@PageIndex 			INT 			= 1,
	@NRows 				INT 			= 0 OUTPUT
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Affiliate - Affiliate Info

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]

	Param's Explanation:
		- @SortType: 1: Username, 2: Registration Date, 3: Approval Date, 4: Balance B/F, 5: Member (Count)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
*/

BEGIN
	SET NOCOUNT ON

	SELECT @NRows = COUNT(1)
	FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
		LEFT JOIN dbo.AdminFavorite af WITH (NOLOCK) ON ai.AffID = af.AffId AND af.AdminId = @UserId
	WHERE
		(ISNULL(@Username, '') = '' OR ai.Username LIKE '%' + @Username + '%')
		AND (ISNULL(@Email, '') = '' OR ai.Email LIKE '%' + @Email + '%')
		AND ai.Status = CASE
							WHEN ISNULL(@Status, '') = '' THEN ai.Status
							WHEN @Status IN ('Favorite', 'Approved', 'Closed') THEN 'Approved'
							ELSE @Status END
		AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
		AND (ISNULL(@Status, '') <> 'Closed' OR ai.IsClosed = 1)
		AND (ISNULL(@PreferredLanguage, '') = '' OR ad.PreferredLanguage = @PreferredLanguage)
		AND (ISNULL(@GroupID, 0) = 0 OR ai.GroupID = @GroupID)
	
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 0
	BEGIN
		SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
				@RowEnd = @RowStart + @PageSize - 1
	END
	ELSE
	BEGIN
		SELECT  @RowStart = 1,
				@RowEnd = @NRows
	END

	DECLARE @MinReportDate SMALLDATETIME
	SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(0)

	SELECT
		AffId,
		Username,
		FirstName,
		LastName,
		Status,
		IsClosed,
		PreferredLanguage,
		Email,
		RegisteredDate,
		ApprovedDate,
		CasinoJoinedDate,
		GroupName,
		NoOfMember,
		BFF,
		IsFavorite
	FROM
	(
	SELECT
		ai.AffId,
		ai.Username,
		ai.FirstName,
		ai.LastName,
		ai.Status,
		ai.IsClosed,
		ad.PreferredLanguage,
		ai.Email,
		ai.RegisteredDate,
		ai.ApprovedDate,
		ai.CasinoJoinedDate,
		cg.GroupName,
		ISNULL(mi.NoOfMember, 0) AS NoOfMember,
		ISNULL(at.BFF, 0) AS BFF,
		CASE WHEN af.AffId IS NOT NULL THEN 1 ELSE 0 END AS IsFavorite,
		ROW_NUMBER() OVER (ORDER BY
					CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN ai.Username END ASC,
					CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN ai.Username END DESC,
					CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ai.RegisteredDate END ASC,
					CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ai.RegisteredDate END DESC,
					CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ai.ApprovedDate END ASC,
					CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ai.ApprovedDate END DESC,
					CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN ISNULL(at.BFF, 0) END ASC,
					CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN ISNULL(at.BFF, 0) END DESC,
					CASE WHEN @SortType = 5 AND @SortDirectionType = 0 THEN ISNULL(mi.NoOfMember, 0) END ASC,
					CASE WHEN @SortType = 5 AND @SortDirectionType = 1 THEN ISNULL(mi.NoOfMember, 0) END DESC)
												AS RowIdx
	FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
		LEFT JOIN dbo.AdminFavorite af WITH (NOLOCK) ON ai.AffID = af.AffId AND af.AdminId = @UserId
		LEFT JOIN (
			SELECT AffId, COUNT(1) AS NoOfMember
			FROM dbo.MemberInfo WITH (NOLOCK)
			WHERE IsRemoved = 0
			GROUP BY AffId
		) mi ON ai.AffId = mi.AffId
		LEFT JOIN (
			SELECT AffId, SUM(Amount) AS BFF
			FROM dbo.AffTrans WITH (NOLOCK)
			WHERE TransDate >= @MinReportDate
			GROUP BY AffId
		) at ON at.AffId = mi.AffId
	WHERE
		(ISNULL(@Username, '') = '' OR ai.Username LIKE '%' + @Username + '%')
		AND (ISNULL(@Email, '') = '' OR ai.Email LIKE '%' + @Email + '%')
		AND ai.Status = CASE
							WHEN ISNULL(@Status, '') = '' THEN ai.Status
							WHEN @Status IN ('Favorite', 'Approved', 'Closed') THEN 'Approved'
							ELSE @Status END
		AND (ISNULL(@Status, '') <> 'Closed' OR ai.IsClosed = 1)
		AND (ISNULL(@PreferredLanguage, '') = '' OR ad.PreferredLanguage = @PreferredLanguage)
		AND (ISNULL(@GroupID, 0) = 0 OR ai.GroupID = @GroupID)
		AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
	) AS result
	WHERE RowIdx BETWEEN @RowStart AND @RowEnd
END
GO