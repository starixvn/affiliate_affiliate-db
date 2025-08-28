/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_SpecificDomainControl_Sel]
	@AffUserName NVARCHAR(60) = ''
	,@AffDomain NVARCHAR(200) = ''
	,@RedirectDomain NVARCHAR(200) = ''
	,@PageSize INT = 0
	,@PageIndex INT = 0
	,@NRows INT = 0 OUTPUT
AS

/*  
	Created: 20250402@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Domain - Specific Domain Control - Select

	Revisions:
		- 20250402@Lewis: Initialize SP [RedmineID: #221035]
		- 20250815@Eddie: Support for Mobile Only [RedmineID: #233219]
*/

BEGIN
	SET NOCOUNT ON
	
	-- Validate Param
	DECLARE @AffId INT = 0 --getall
	IF @AffUserName <> ''
	BEGIN
		SET @AffId = ISNULL((SELECT AffId FROM AffInfo WITH (NOLOCK) WHERE UserName = @AffUserName),-1)
	END
	
	DECLARE @RowStart INT, @RowEnd INT

	CREATE TABLE #tmp_Result(
		RId 					 INT
		,SpecificDomainControlID INT
		,AffUsername 			 NVARCHAR(60)
		,AffDomain 				 NVARCHAR(200)
		,AffDomainIsSSL 		 BIT
		,RedirectDomain 		 NVARCHAR(200)
		,RedirectDomainIsSSL 	 BIT
		,Creator 				 VARCHAR(30)
		,CreatedDate 			 DATETIME
		,Status 				 BIT
		,Editor 				 VARCHAR(30)
		,UpdatedDate 			 DATETIME
		,IsMobile 				 BIT
	)

	INSERT INTO #tmp_Result(
		RId 
		,SpecificDomainControlID 
		,AffUsername 
		,AffDomain 
		,AffDomainIsSSL 
		,RedirectDomain
		,RedirectDomainIsSSL 
		,Creator 
		,CreatedDate 
		,Status 
		,Editor 
		,UpdatedDate 
		,IsMobile 
	)
	SELECT ROW_NUMBER() OVER (ORDER BY s.CreatedDate DESC) AS RId
		,s.Id AS SpecificDomainControlID
		,a.UserName AS AffUsername
		,s.AffDomainName AS AffDomain
		,s.AffDomainIsSSL AS AffDomainIsSSL
		,s.LicenseeDomainName AS RedirectDomain
		,s.LicenseeDomainIsSSL AS RedirectDomainIsSSL
		,auc.UserName AS Creator
		,s.CreatedDate AS CreatedDate
		,s.Status
		,aue.UserName AS Editor
		,s.UpdatedDate AS UpdatedDate
		,s.IsMobile
	FROM dbo.SpecificDomainControl s WITH (NOLOCK)
		INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON s.AffID = a.AffId
		LEFT JOIN dbo.Affiliate_User auc WITH (NOLOCK) ON s.CreatedBy = auc.CustId
		LEFT JOIN dbo.Affiliate_User aue WITH (NOLOCK) ON s.UpdatedBy = aue.CustId
	WHERE (s.AffId = @AffId OR @AffId = 0)
	  AND (s.AffDomainName LIKE '%' + @AffDomain + '%' OR @AffDomain = '')
	  AND (s.LicenseeDomainName LIKE '%' + @RedirectDomain + '%' OR @RedirectDomain = '')

	-- TODO: Result
	IF (@PageSize = 0 AND @PageIndex = 0)
	BEGIN
		SELECT 
			RId 
			,SpecificDomainControlID 
			,AffUsername 
			,AffDomain 
			,AffDomainIsSSL 
			,RedirectDomain
			,RedirectDomainIsSSL 
			,Creator 
			,CAST(CreatedDate AS DATE) AS CreatedDate
			,Status 
			,Editor 
			,CAST(UpdatedDate  AS DATE) AS UpdatedDate
			,IsMobile
		FROM #tmp_Result
		ORDER BY RId ASC
	END
	ELSE
	BEGIN
		
		SELECT	@PageIndex = @PageIndex - 1,
				@RowStart = @PageSize * @PageIndex + 1,
				@RowEnd = @RowStart + @PageSize - 1;
		
		SELECT @NRows = COUNT(1) FROM #tmp_Result

		SELECT
			RId 
			,SpecificDomainControlID 
			,AffUsername 
			,AffDomain 
			,AffDomainIsSSL 
			,RedirectDomain
			,RedirectDomainIsSSL 
			,Creator 
			,CAST(CreatedDate AS DATE) AS CreatedDate 
			,Status 
			,Editor 
			,CAST(UpdatedDate  AS DATE) AS UpdatedDate
			,IsMobile
		FROM #tmp_Result A
		WHERE A.RId BETWEEN @RowStart AND @RowEnd
		ORDER BY A.RId ASC
	END
END
GO