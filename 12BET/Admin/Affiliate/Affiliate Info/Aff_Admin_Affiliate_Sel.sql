/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Affiliate_Sel] 
	@UserId 			INT,
	@GroupID 			INT				= 0,
	@PreferredLanguages	VARCHAR(MAX),
	@AffId				INT				= 0,
	@UserName 			NVARCHAR(50) 	= '',
	@Status				VARCHAR(30)		= '',
	@ProcessingStatus	VARCHAR(30)		= '',
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
		- 20181212@Percy:
			1. Return more information: currency, player currency, phone and player username [RedmineID: #106837]
			2. Add @AffId to support search by Affiliate ID [RedmineID: #106265]
		- 20200731@Percy: Change way to input Language [RedmineID: #121975]
		- 20210126@Malcolm: Get Balance Brought Forward for affiliates who haven't members [RedmineID: #147902]
		- 20210817@Malcolm: Get processing request [RedmineID: #159570]
		- 20220214@Malcolm: Exclude Status Rejected and Cancelled when getting BFF  [RedmineID: #1]

	Param's Explanation:
		- @SortType: 1: Username, 2: Registration Date, 3: Approval Date, 4: Balance B/F, 5: Member (Count)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
*/

BEGIN
	SET NOCOUNT ON

	SELECT @PreferredLanguages = ISNULL(@PreferredLanguages, '')

	SELECT @NRows = COUNT(1)
	FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
		LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
		LEFT JOIN dbo.AdminFavorite af WITH (NOLOCK) ON ai.AffID = af.AffId AND af.AdminId = @UserId
	WHERE
		(ISNULL(@AffId, 0) = 0 OR ai.AffId = @AffId)
		AND (ISNULL(@Username, '') = '' OR ai.Username LIKE '%' + @Username + '%')
		AND (ISNULL(@Email, '') = '' OR ai.Email LIKE '%' + @Email + '%')
		AND ai.Status = CASE
							WHEN ISNULL(@Status, '') = '' THEN ai.Status
							WHEN @Status IN ('Favorite', 'Approved', 'Closed') THEN 'Approved'
							ELSE @Status END
		AND ai.IsClosed = CASE
							WHEN ISNULL(@Status, '') = '' THEN ai.IsClosed
							WHEN @Status = 'Approved' THEN 0
							WHEN @Status = 'Closed' THEN 1
							ELSE ai.IsClosed END
		AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
		AND ',' + @PreferredLanguages + ',' LIKE '%,' + ad.PreferredLanguage + ',%'
		AND (ISNULL(@GroupID, 0) = 0 OR ai.GroupID = @GroupID)
		AND (EXISTS(SELECT 1 FROM dbo.ProcessingRequest pr WITH(NOLOCK) WHERE pr.AffId = ai.AffID AND pr.Status = @ProcessingStatus)
			 OR ISNULL(@ProcessingStatus, '') = '')
	
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

	DECLARE @MinSmalldatetime SMALLDATETIME, @MaxSmalldatetime SMALLDATETIME, @MinMoney MONEY, @MaxMoney MONEY, @MaxInt INT
	SELECT  @MinSmalldatetime = '1900-01-01', @MaxSmalldatetime = '2079-06-06', @MinMoney = -1000000000, @MaxMoney = 1000000000, @MaxInt = 1000000000

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
		IsFavorite,
		Currency,
		PlayerCurrency,
		Phone,
		Player_Username,
		ProcessingStatus
	FROM
	(
		SELECT
			ai.AffId,
			ai.Username,
			ai.FirstName,
			ai.LastName,
			CASE WHEN ai.Status = 'Approved' AND ai.IsClosed = 1 THEN 'Closed' ELSE ai.Status END AS Status,
			ai.IsClosed,
			ad.PreferredLanguage,
			ai.Email,
			ai.RegisteredDate,
			ai.ApprovedDate,
			ai.CasinoJoinedDate,
			cg.GroupName,
			CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN NULL ELSE ISNULL(mi.NoOfMember, 0) END AS NoOfMember,
			CASE WHEN ai.Status IN ('Pending', 'Disapproved') THEN NULL ELSE ISNULL(at.BFF, 0) END AS BFF,
			CASE WHEN af.AffId IS NOT NULL THEN 1 ELSE 0 END AS IsFavorite,
			e1.Currency,
			e2.Currency AS PlayerCurrency,
			ad.Phone,
			ad.Player_Username,
			CONVERT(VARCHAR(10), ISNULL(pr.Draft, 0)) + '/' + CONVERT(VARCHAR(10), ISNULL(pr.Submitted, 0)) + '/' +  CONVERT(VARCHAR(10), ISNULL(pr.Approved,0)) + '/' +  CONVERT(VARCHAR(10), ISNULL(pr.Rejected, 0)) AS ProcessingStatus,
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
			LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			LEFT JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupId = cg.GroupId
			LEFT JOIN dbo.AdminFavorite af WITH (NOLOCK) ON ai.AffID = af.AffId AND af.AdminId = @UserId
			LEFT JOIN dbo.Exchange_Current e1 WITH (NOLOCK) ON ai.Currency = e1.ExchangeID
			LEFT JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON ad.Player_IBCCustID = c.custid
			LEFT JOIN dbo.Exchange_Current e2 WITH (NOLOCK) ON c.Currency = e2.ExchangeID
			LEFT JOIN (
				SELECT AffId, COUNT(1) AS NoOfMember
				FROM dbo.MemberInfo WITH (NOLOCK)
				WHERE IsRemoved = 0
				GROUP BY AffId
			) mi ON ai.AffId = mi.AffId
			LEFT JOIN (
				SELECT AffId, SUM(Amount) AS BFF
				FROM dbo.AffTrans WITH (NOLOCK)
				WHERE Status IN ('Approved', 'Pending', 'Completed')
				GROUP BY AffId
			) at ON at.AffId = ai.AffId
			LEFT JOIN (
			    SELECT AffId
					   ,COUNT(CASE WHEN Status = 'Draft' THEN 1 ELSE NULL END) AS Draft
					   ,COUNT(CASE WHEN Status = 'Submitted' THEN 1 ELSE NULL END) AS Submitted
					   ,COUNT(CASE WHEN Status = 'Approved' THEN 1 ELSE NULL END) AS Approved
					   ,COUNT(CASE WHEN Status = 'Rejected' THEN 1 ELSE NULL END) AS Rejected
				FROM dbo.ProcessingRequest WITH(NOLOCK)
				GROUP BY AffId
			) pr ON pr.AffId = ai.AffID
		WHERE
			(ISNULL(@AffId, 0) = 0 OR ai.AffId = @AffId)
			AND (ISNULL(@Username, '') = '' OR ai.Username LIKE '%' + @Username + '%')
			AND (ISNULL(@Email, '') = '' OR ai.Email LIKE '%' + @Email + '%')
			AND ai.Status = CASE
								WHEN ISNULL(@Status, '') = '' THEN ai.Status
								WHEN @Status IN ('Favorite', 'Approved', 'Closed') THEN 'Approved'
								ELSE @Status END
			AND ai.IsClosed = CASE
								WHEN ISNULL(@Status, '') = '' THEN ai.IsClosed
								WHEN @Status = 'Approved' THEN 0
								WHEN @Status = 'Closed' THEN 1
								ELSE ai.IsClosed END
			AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
			AND ',' + @PreferredLanguages + ',' LIKE '%,' + ad.PreferredLanguage + ',%'
			AND (ISNULL(@GroupID, 0) = 0 OR ai.GroupID = @GroupID)
			AND (ISNULL(@Status, '') <> 'Favorite' OR af.AdminId IS NOT NULL)
			AND (EXISTS(SELECT 1 FROM dbo.ProcessingRequest pr WITH(NOLOCK) WHERE pr.AffId = ai.AffID AND pr.Status = @ProcessingStatus)
			 OR ISNULL(@ProcessingStatus, '') = '')
	) AS result
	WHERE RowIdx BETWEEN @RowStart AND @RowEnd
END
GO