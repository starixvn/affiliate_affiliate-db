/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MemberList_Sel]
	@AffUsername	NVARCHAR(50) = ''
	,@Username		NVARCHAR(30) = ''
	,@IBCUserName	NVARCHAR(50) = ''
	,@PageSize		INT = 50
	,@PageIndex		INT = 1
	,@NRows			INT = 0 OUTPUT
AS

/*
	Creator: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Home - Member
	
	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210819@Percy: Use FirstDepositDate to get deposited player [RedmineID: #160414]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT	@AffUsername	= ISNULL(@AffUsername, '')
			,@Username		= ISNULL(@Username, '')
			,@IBCUserName	= ISNULL(@IBCUserName, '')

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
			,@RowEnd	= @RowStart + @PageSize - 1

	IF @AffUsername = ''
	BEGIN
		IF @Username = '' AND @IBCUserName = ''
		BEGIN
			SELECT @NRows = COUNT(1) FROM dbo.MemberInfo WITH (NOLOCK) WHERE FirstDepositDate IS NOT NULL
		
			SELECT CustId, UserName, IBCUserName, FirstName, LastName, FirstDepositDate AS CreatedDate, 0 AS CurrBalance, AffUserName 
			FROM
			(
				SELECT	mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.FirstDepositDate, ai.UserName AS AffUserName
						,ROW_NUMBER() OVER(ORDER BY mi.FirstDepositDate DESC) AS RowNum
				FROM dbo.MemberInfo mi WITH (NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
				WHERE mi.FirstDepositDate IS NOT NULL
			) AS r
			WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
			ORDER BY r.RowNum
		END
		ELSE
		BEGIN
			SELECT @NRows = COUNT(1)
			FROM dbo.MemberInfo WITH (NOLOCK)
			WHERE FirstDepositDate IS NOT NULL
				AND UserName LIKE '%' + @UserName + '%'
				AND IBCUserName LIKE '%' + @IBCUserName + '%'

			SELECT CustId, UserName, IBCUserName, FirstName, LastName, FirstDepositDate AS CreatedDate, 0 AS CurrBalance, AffUserName 
			FROM
			(
				SELECT	mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.FirstDepositDate, ai.UserName AS AffUserName
						,ROW_NUMBER() OVER(ORDER BY mi.FirstDepositDate DESC) AS RowNum
				FROM dbo.MemberInfo mi WITH (NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
				WHERE mi.FirstDepositDate IS NOT NULL
					AND mi.UserName LIKE '%' + @UserName + '%'
					AND ISNULL(mi.IBCUserName, '') LIKE '%' + @IBCUserName + '%'
			) AS r
			WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
			ORDER BY r.RowNum
		END
	END
	ELSE
	BEGIN
		SELECT @NRows = COUNT(1)
		FROM dbo.MemberInfo mi WITH (NOLOCK)
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
		WHERE mi.FirstDepositDate IS NOT NULL
			AND mi.UserName LIKE '%' + @UserName + '%'
			AND mi.IBCUserName LIKE '%' + @IBCUserName + '%'
			AND ai.UserName LIKE '%' + @AffUsername + '%'

		SELECT CustId, UserName, IBCUserName, FirstName, LastName, FirstDepositDate AS CreatedDate, 0 AS CurrBalance, AffUserName 
		FROM
		(
			SELECT	mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.FirstDepositDate, ai.UserName AS AffUserName
					,ROW_NUMBER() OVER(ORDER BY mi.FirstDepositDate DESC) AS RowNum
			FROM dbo.MemberInfo mi WITH (NOLOCK)
				INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
			WHERE mi.FirstDepositDate IS NOT NULL
				AND mi.UserName LIKE '%' + @UserName + '%'
				AND ISNULL(mi.IBCUserName, '') LIKE '%' + @IBCUserName + '%'
				AND ai.UserName LIKE '%' + @AffUsername + '%'
		) AS r
		WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
		ORDER BY r.RowNum
	END
END
GO