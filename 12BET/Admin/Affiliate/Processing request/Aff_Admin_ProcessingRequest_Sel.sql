/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Aff_Admin_ProcessingRequest_Sel
	@UserName		NVARCHAR(50) = ''
	,@Status		VARCHAR(30) = ''
	,@PageSize		INT = 50
	,@PageIndex		INT = 1
	,@IsExportExcel BIT = 0
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20210817@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Affiliate - Processing Request
	Revisions:
		- 20210817@Malcolm: Initialize SP [RedmineID: #159570]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Draft INT = 0, @Submitted INT = 0, @Approved INT = 0, @Rejected INT = 0, @Rowstart INT, @RowEnd INT

	SELECT
		@NRows = COUNT(1)
		,@Draft = COUNT(CASE WHEN pr.Status = 'Draft' THEN 1 ELSE NULL END) 
		,@Submitted = COUNT(CASE WHEN pr.Status = 'Submitted' THEN 1 ELSE NULL END) 
		,@Approved = COUNT(CASE WHEN pr.Status = 'Approved' THEN 1 ELSE NULL END) 
		,@Rejected = COUNT(CASE WHEN pr.Status = 'Rejected' THEN 1 ELSE NULL END) 
	FROM dbo.ProcessingRequest pr WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = pr.AffId
	WHERE (ISNULL(@Status, '') = '' OR pr.Status = @Status)
		AND (ISNULL(@Username, '') = '' OR ai.UserName LIKE '%' + @UserName + '%')

	IF ISNULL(@IsExportExcel, 0) = 1
		SELECT @Rowstart = 1, @RowEnd = @NRows
	ELSE 
		SELECT @Rowstart = (@PageIndex - 1) * @PageSize + 1, @RowEnd = @Rowstart + @PageSize - 1

	IF ISNULL(@UserName, '') = ''
		SELECT 
			r.RequestId
			,r.AffID
			,r.UserName
			,r.CreatedBy
			,r.CreationDate
			,r.LastModified
			,r.SubmittedDate
			,r.Deadline
			,r.ApprovedBy
			,r.ApprovalDate
			,r.Status
		FROM
		(
			SELECT 
				pr.RequestId
				,ai.AffID
				,ai.UserName
				,cr.UserName AS CreatedBy
				,pr.CreationDate
				,pr.LastModified
				,pr.SubmittedDate
				,pr.Deadline
				,ap.UserName AS ApprovedBy
				,pr.ApprovalDate
				,pr.Status
				,ROW_NUMBER() OVER(ORDER BY RequestId DESC) AS rn
			FROM dbo.ProcessingRequest pr WITH(NOLOCK)
				INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = pr.AffId
				LEFT JOIN dbo.Users cr WITH(NOLOCK) ON cr.CustId = pr.Creator
				LEFT JOIN dbo.Users ap WITH(NOLOCK) ON ap.CustId = pr.Approver
			WHERE (ISNULL(@Status, '') = '' OR pr.Status = @Status)
		) r
		WHERE r.rn BETWEEN @Rowstart AND @RowEnd
		ORDER BY r.rn
	ELSE
		SELECT 
			r.RequestId
			,r.AffID
			,r.UserName
			,r.CreatedBy
			,r.CreationDate
			,r.LastModified
			,r.SubmittedDate
			,r.Deadline
			,r.ApprovedBy
			,r.ApprovalDate
			,r.Status
		FROM
		(
			SELECT 
				pr.RequestId
				,ai.AffID
				,ai.UserName
				,cr.UserName AS CreatedBy
				,pr.CreationDate
				,pr.LastModified
				,pr.SubmittedDate
				,pr.Deadline
				,ap.UserName AS ApprovedBy
				,pr.ApprovalDate
				,pr.Status
				,ROW_NUMBER() OVER(ORDER BY RequestId DESC) AS rn
			FROM dbo.ProcessingRequest pr WITH(NOLOCK)
				INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = pr.AffId
				LEFT JOIN dbo.Users cr WITH(NOLOCK) ON cr.CustId = pr.Creator
				LEFT JOIN dbo.Users ap WITH(NOLOCK) ON ap.CustId = pr.Approver
			WHERE (ISNULL(@Status, '') = '' OR pr.Status = @Status)
				AND ai.UserName LIKE '%' + @UserName + '%'
		) r
		WHERE r.rn BETWEEN @Rowstart AND @RowEnd
		ORDER BY r.rn
		

	SELECT @Draft AS Draft, @Submitted AS Submitted, @Approved AS Approved, @Rejected AS Rejected
END
GO