/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Affiliate_Sel] 
	@UserId 			INT,
	@GroupID 			INT				= 0,
	@PreferredLanguage	VARCHAR(10)		= '',
	@ParentAffName		NVARCHAR(50)	= '',
	@AffCode			VARCHAR(20)		= '',
	@UserName 			NVARCHAR(50) 	= '',
	@Status				VARCHAR(30)		= '',
	@Email 				NVARCHAR(50) 	= '',
	@Player_UserName	VARCHAR(30)		= '',
	@SortType			TINYINT			= 1,
	@SortDirectionType	BIT				= 0,
	@IsExportExcel		BIT				= 0,
	@PageSize 			INT 			= 50,
	@PageIndex 			INT 			= 1,
	@NRows 				INT 			= 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin Site - Affiliate - Affiliate Info

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20201026@Percy: Change search by AffId to AffCode [RedmineID: #143852]
		- 20200107@Percy: Add suspended status [RedmineID: #148373]
		- 20210622@Percy: Support search Affiliate player [RedmineID: #157299]

	Param's Explanation:
		- @SortType: 1: Username, 2: Registration Date, 3: Approval Date, 4: Balance B/F, 5: Member (Count)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
*/

BEGIN
	SET NOCOUNT ON

	SELECT @NRows = COUNT(1)
	FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffInfo p WITH (NOLOCK) ON p.AffId = ai.ParentAffId
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
		LEFT JOIN dbo.AdminFavorite af WITH (NOLOCK) ON ai.AffID = af.AffId AND af.AdminId = @UserId
	WHERE
		(ISNULL(@ParentAffName, '') = '' OR p.Username LIKE '%' + @ParentAffName + '%')
		AND (ISNULL(@AffCode, '') = '' OR ai.AffCode = @AffCode)
		AND (ISNULL(@Username, '') = '' OR ai.Username LIKE '%' + @Username + '%')
		AND (ISNULL(@Email, '') = '' OR ai.Email LIKE '%' + REPLACE(@Email, '_', '[_]') + '%')
		AND (ISNULL(@Player_UserName, '') = '' OR ad.Player_Username LIKE '%' + REPLACE(@Player_UserName, '_', '[_]') + '%')
		AND ai.Status = CASE
							WHEN ISNULL(@Status, '') = '' THEN ai.Status
							WHEN @Status IN ('Favorite', 'Approved', 'Closed', 'Suspended') THEN 'Approved'
							ELSE @Status END
		AND ai.IsClosed = CASE
							WHEN ISNULL(@Status, '') = '' THEN ai.IsClosed
							WHEN @Status = 'Approved' THEN 0
							WHEN @Status = 'Closed' THEN 1
							ELSE ai.IsClosed END
		AND ai.IsRejected = CASE
							WHEN ISNULL(@Status, '') = '' THEN ai.IsRejected
							WHEN @Status = 'Approved' THEN 0
							WHEN @Status = 'Suspended' THEN 1
							ELSE ai.IsRejected END
		AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
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

	DECLARE @MinSmalldatetime SMALLDATETIME, @MaxSmalldatetime SMALLDATETIME, @MinMoney MONEY, @MaxMoney MONEY, @MaxInt INT
	SELECT  @MinSmalldatetime = '1900-01-01', @MaxSmalldatetime = '2079-06-06', @MinMoney = -1000000000, @MaxMoney = 1000000000, @MaxInt = 1000000000

	SELECT
		ParentAffId,
		ParentAffName,
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
		ApprovedBy,
		GroupName,
		IsPrivate,
		NoOfMember,
		NoOfSubAff,
		BFF,
		IsFavorite,
		Currency,
		PlayerCurrency,
		Phone,
		Player_Username
	FROM
	(
		SELECT
			ai.ParentAffId,
			p.UserName AS ParentAffName,
			ai.AffId,
			ai.Username,
			ai.FirstName,
			ai.LastName,
			CASE
				WHEN ai.Status = 'Approved' AND ai.IsClosed = 1 THEN 'Closed'
				WHEN ai.Status = 'Approved' AND ai.IsRejected = 1 THEN 'Suspended'
				ELSE ai.Status END AS Status,
			ai.IsClosed,
			ad.PreferredLanguage,
			ai.Email,
			ai.RegisteredDate,
			ai.ApprovedDate,
			ISNULL(u.UserName, '') AS ApprovedBy,
			cg.GroupName,
			cg.IsPrivate,
			CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN NULL ELSE ISNULL(mi.NoOfMember, 0) END AS NoOfMember,
			CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN NULL ELSE ISNULL(c.NoOfSubAff, 0) END AS NoOfSubAff,
			CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN NULL ELSE ISNULL(at.BFF, 0) END AS BFF,
			CASE WHEN af.AffId IS NOT NULL THEN 1 ELSE 0 END AS IsFavorite,
			CASE WHEN ISNULL(ai.CurrencyCode, '') = '' THEN ai.CurrencyName ELSE ai.CurrencyCode END AS Currency,
			CASE WHEN ISNULL(ad.Player_CurrencyCode, '') = '' THEN ad.Player_CurrencyName ELSE ad.Player_CurrencyCode END AS PlayerCurrency,
			ad.Phone,
			ad.Player_Username,
			ROW_NUMBER() OVER (ORDER BY
						CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN ai.Username END ASC,
						CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN ai.Username END DESC,
						CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN ai.RegisteredDate END ASC,
						CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN ai.RegisteredDate END DESC,
						CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN ISNULL(ai.ApprovedDate, @MaxSmalldatetime) END ASC,
						CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN ISNULL(ai.ApprovedDate, @MinSmalldatetime) END DESC,
						CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN @MaxMoney ELSE ISNULL(at.BFF, 0) END END ASC,
						CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN @MinMoney ELSE ISNULL(at.BFF, 0) END END DESC,
						CASE WHEN @SortType = 5 AND @SortDirectionType = 0 THEN CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN @MaxInt ELSE ISNULL(mi.NoOfMember, 0) END END ASC,
						CASE WHEN @SortType = 5 AND @SortDirectionType = 1 THEN CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN -1 ELSE ISNULL(mi.NoOfMember, 0) END END DESC)
													AS RowIdx
		FROM dbo.AffInfo ai WITH (NOLOCK)
			LEFT JOIN dbo.AffInfo p WITH (NOLOCK) ON p.AffId = ai.ParentAffId
			LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ad.AffId = ai.AffId
			LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.GroupId = ai.GroupId
			LEFT JOIN dbo.Affiliate_User u WITH (NOLOCK) ON ai.ApprovedBy = u.CustId
			LEFT JOIN dbo.AdminFavorite af WITH (NOLOCK) ON af.AffID = ai.AffId AND af.AdminId = @UserId
			OUTER APPLY (
				SELECT COUNT(1) AS NoOfSubAff
				FROM dbo.AffInfo c WITH (NOLOCK)
				WHERE c.ParentAffId = ai.AffId
					AND c.Status = 'Approved'
					AND c.IsClosed = 0
			) c
			OUTER APPLY (
				SELECT COUNT(1) AS NoOfMember
				FROM dbo.MemberInfo mi WITH (NOLOCK)
				WHERE mi.AffId = ai.AffId
					AND mi.IsRemoved = 0
					AND mi.CreatedDate IS NOT NULL
			) mi
			OUTER APPLY (
				SELECT SUM(at.Amount) AS BFF
				FROM dbo.AffTrans at WITH (NOLOCK)
				WHERE at.AffId = ai.AffId
					AND at.status IN ('Approved', 'Pending', 'Completed')
			) at
		WHERE
			(ISNULL(@ParentAffName, '') = '' OR p.Username LIKE '%' + @ParentAffName + '%')
			AND (ISNULL(@AffCode, '') = '' OR ai.AffCode = @AffCode)
			AND (ISNULL(@Username, '') = '' OR ai.Username LIKE '%' + @Username + '%')
			AND (ISNULL(@Email, '') = '' OR ai.Email LIKE '%' + REPLACE(@Email, '_', '[_]') + '%')
			AND (ISNULL(@Player_UserName, '') = '' OR ad.Player_Username LIKE '%' + REPLACE(@Player_UserName, '_', '[_]') + '%')
			AND ai.Status = CASE
								WHEN ISNULL(@Status, '') = '' THEN ai.Status
								WHEN @Status IN ('Favorite', 'Approved', 'Closed', 'Suspended') THEN 'Approved'
								ELSE @Status END
			AND ai.IsClosed = CASE
								WHEN ISNULL(@Status, '') = '' THEN ai.IsClosed
								WHEN @Status = 'Approved' THEN 0
								WHEN @Status = 'Closed' THEN 1
								ELSE ai.IsClosed END
			AND ai.IsRejected = CASE
								WHEN ISNULL(@Status, '') = '' THEN ai.IsRejected
								WHEN @Status = 'Approved' THEN 0
								WHEN @Status = 'Suspended' THEN 1
								ELSE ai.IsRejected END
			AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
			AND (ISNULL(@PreferredLanguage, '') = '' OR ad.PreferredLanguage = @PreferredLanguage)
			AND (ISNULL(@GroupID, 0) = 0 OR ai.GroupID = @GroupID)
			AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
	) AS result
	WHERE RowIdx BETWEEN @RowStart AND @RowEnd
END
GO