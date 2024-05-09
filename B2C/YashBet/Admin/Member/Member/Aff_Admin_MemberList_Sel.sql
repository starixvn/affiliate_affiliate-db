/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_MemberList_Sel]
	@AffUsername	NVARCHAR(50) = ''
	,@Username		NVARCHAR(30) = ''
	,@IBCUserName	NVARCHAR(50) = ''
	,@PageSize		INT = 50
	,@PageIndex		INT = 1
	,@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Home - Member
	
	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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
			SELECT @NRows = COUNT(1) FROM dbo.MemberInfo WITH (NOLOCK)
		
			SELECT CustId, UserName, IBCUserName, FirstName, LastName, RegisteredDate, 0 AS CurrBalance, AffUserName, IsRemoved, LastAction, IsInclude
			FROM
			(
				SELECT	mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.RegisteredDate, ai.UserName AS AffUserName, mi.IsRemoved, mr.LastAction, ISNULL(mr.IsInclude, 1) AS IsInclude
						,ROW_NUMBER() OVER(ORDER BY mi.RegisteredDate DESC) AS RowNum
				FROM dbo.MemberInfo mi WITH (NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
					OUTER APPLY (
						SELECT TOP(1) mr.RemovedDate AS LastAction, mr.IsInclude
						FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = mi.CustId 
						ORDER BY mr.RemovedDate DESC
					) AS mr
			) AS r
			WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
			ORDER BY r.RowNum
		END
		ELSE
		BEGIN
			SELECT @NRows = COUNT(1)
			FROM dbo.MemberInfo WITH (NOLOCK)
			WHERE UserName LIKE '%' + @UserName + '%'
				AND ISNULL(IBCUserName, '') LIKE '%' + @IBCUserName + '%'

			SELECT CustId, UserName, IBCUserName, FirstName, LastName, RegisteredDate, 0 AS CurrBalance, AffUserName, IsRemoved, LastAction, IsInclude
			FROM
			(
				SELECT	mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.RegisteredDate, ai.UserName AS AffUserName, mi.IsRemoved, mr.LastAction, ISNULL(mr.IsInclude, 1) AS IsInclude
						,ROW_NUMBER() OVER(ORDER BY mi.RegisteredDate DESC) AS RowNum
				FROM dbo.MemberInfo mi WITH (NOLOCK)
					INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
					OUTER APPLY (
						SELECT TOP(1) mr.RemovedDate AS LastAction, mr.IsInclude
						FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = mi.CustId 
						ORDER BY mr.RemovedDate DESC
					) AS mr
				WHERE mi.UserName LIKE '%' + @UserName + '%'
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
		WHERE mi.UserName LIKE '%' + @UserName + '%'
			AND ISNULL(mi.IBCUserName, '') LIKE '%' + @IBCUserName + '%'
			AND ai.UserName LIKE '%' + @AffUsername + '%'

		SELECT CustId, UserName, IBCUserName, FirstName, LastName, RegisteredDate, 0 AS CurrBalance, AffUserName, IsRemoved, LastAction, IsInclude
		FROM
		(
			SELECT	mi.CustId, mi.UserName, mi.IBCUserName, mi.FirstName, mi.LastName, mi.RegisteredDate, ai.UserName AS AffUserName, mi.IsRemoved, mr.LastAction, ISNULL(mr.IsInclude, 1) AS IsInclude
					,ROW_NUMBER() OVER(ORDER BY mi.RegisteredDate DESC) AS RowNum
			FROM dbo.MemberInfo mi WITH (NOLOCK)
				INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffId = ai.AffId
				OUTER APPLY (
						SELECT TOP(1) mr.RemovedDate AS LastAction, mr.IsInclude
						FROM dbo.MemberRemoval mr WITH(NOLOCK)
						WHERE mr.CustId = mi.CustId 
						ORDER BY mr.RemovedDate DESC
					) AS mr
			WHERE mi.UserName LIKE '%' + @UserName + '%'
				AND ISNULL(mi.IBCUserName, '') LIKE '%' + @IBCUserName + '%'
				AND ai.UserName LIKE '%' + @AffUsername + '%'
		) AS r
		WHERE r.RowNum BETWEEN @RowStart AND @RowEnd
		ORDER BY r.RowNum
	END
END
GO