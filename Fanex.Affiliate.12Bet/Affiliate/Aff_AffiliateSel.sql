USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSel]    Script Date: 05/20/2014 23:58:40 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[Aff_AffiliateSel] 
	@UserId INT = - 1
	,@GroupID INT = - 1
	,@GroupName NVARCHAR(100) = NULL OUTPUT
	,@Status VARCHAR(30)
	,@AffID INT = - 1
	,@UserName NVARCHAR(50) = NULL
	,@Email NVARCHAR(50) = NULL
	,@IsClosed BIT = NULL
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*    
Task : Get All Affiliate for a specific page      
DB: DB052.Affiliate_12BET    
Original:[Aff_CustomerSelAffiliate]      
Revisions:          
 - 20100208@Johnny: show one more column PreferredLanguage  
                    
Param's Explanation:      
. @GroupID : if @GroupID<>-1 : only search by GroupID and this function is linked from Commission Group Page    
. @GroupName : Search by GroupName    
• @Status : pending,Approved,disapproved      
• @UserName : Affiliate name you want to default value=null :search all      
• @Email : Email you want to search - default value=null :search all      
• @PageSize : Number of rows should be returned per each page      
• @PageIndex : Current page       
• @TotalPages OUTPUT : total of pages for this search          
• @NRows OUTPUT,--total of rows      
      
*/
BEGIN
	SET NOCOUNT ON;

	SELECT @UserName = '%' + Coalesce(@UserName, '') + '%'

	SELECT @Email = '%' + Coalesce(@Email, '') + '%'

	DECLARE @GroupIDList TABLE (GroupID INT)

	IF (isnull(@GroupName, '') <> '')
	BEGIN
		IF (lower(@GroupName) = '[none]')
		BEGIN
			INSERT INTO @GroupIDList (GroupID)
			SELECT GroupID
			FROM CommGroup(NOLOCK)
			WHERE GroupID > 1000
		END
		ELSE
		BEGIN
			DECLARE @grName NVARCHAR(100)

			SELECT @grName = '%' + Coalesce(@GroupName, '') + '%'

			INSERT INTO @GroupIDList (GroupID)
			SELECT GroupID
			FROM CommGroup(NOLOCK)
			WHERE GroupName LIKE @grName
		END

		IF (@@ROWCOUNT = 0)
		BEGIN
			RETURN
		END
	END

	--count nrows      
	SELECT @NRows = count(1)
	FROM AffInfo WITH (NOLOCK)
	WHERE (CASE 
			WHEN @AffID = - 1 THEN 1
			WHEN AffId = @AffID THEN 1
			ELSE 0 END
			) = 1
		AND STATUS = @Status
		AND Username LIKE @UserName
		AND Isclosed = (CASE 
			WHEN @IsClosed IS NULL THEN 0
			ELSE 1 END
			)
		AND (Email IS NULL OR Email LIKE @Email)
		AND (CASE 
			WHEN @GroupID > 0
				AND GroupID < 1000
				AND GroupID = @GroupID THEN 1
			WHEN @GroupID = 0
				AND GroupID > 1000 THEN 1
			WHEN @GroupID = - 1
				AND isnull(@GroupName, '') = '' THEN 1
			WHEN EXISTS (
					SELECT 1
					FROM @GroupIDList
					)
				AND GroupID IN (
					SELECT GroupID
					FROM @GroupIDList
					) THEN 1
			ELSE 0 END
			) = 1

	IF (isnull(@NRows, 0) = 0) RETURN

	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	DECLARE @TempMember TABLE (
		AffId INT PRIMARY KEY
		,UserName NVARCHAR(30)
		,FirstName NVARCHAR(50)
		,LastName NVARCHAR(50)
		,PreferredLanguage VARCHAR(11)
		,IsClosed BIT
		,ApprovedDate SMALLDATETIME
		,GroupId INT
		,RegisteredDate SMALLDATETIME
		,CasinoJoinedDate SMALLDATETIME
		)

	INSERT INTO @TempMember (
		AffId
		,UserName
		,FirstName
		,LastName
		,PreferredLanguage
		,IsClosed
		,ApprovedDate
		,GroupId
		,RegisteredDate
		,CasinoJoinedDate
		)
	SELECT m.AffId
		,m.username
		,m.firstname
		,m.lastname
		,m.PreferredLanguage
		,m.IsClosed
		,m.ApprovedDate
		,m.GroupId
		,m.RegisteredDate
		,m.CasinoJoinedDate
	FROM (
		SELECT ROW_NUMBER() OVER (
				ORDER BY ai.AffId
				) AS TheCount
			,ai.AffID
			,ai.UserName
			,ai.FirstName
			,ai.LastName
			,ad.PreferredLanguage
			,ai.IsClosed
			,ai.ApprovedDate
			,ai.GroupId
			,ai.RegisteredDate
			,ai.CasinoJoinedDate
		FROM AffInfo ai WITH (NOLOCK)
			INNER JOIN AffDetail ad WITH (NOLOCK)
			ON ai.AffId = ad.AffId
		WHERE (CASE 
				WHEN @AffID = - 1 THEN 1
				WHEN ai.AffId = @AffID THEN 1
				ELSE 0 END
				) = 1
			AND ai.STATUS = @Status
			AND ai.Isclosed = (CASE 
				WHEN @IsClosed IS NULL THEN 0
				ELSE 1 END
				)
			AND ai.Username LIKE @UserName
			AND (Email IS NULL OR Email LIKE @Email)
			AND (CASE 
				WHEN @GroupID > 0
					AND GroupID < 1000
					AND GroupID = @GroupID THEN 1
				WHEN @GroupID = 0
					AND GroupID > 1000 THEN 1
				WHEN @GroupID = - 1
					AND isnull(@GroupName, '') = '' THEN 1
				WHEN EXISTS (
						SELECT 1
						FROM @GroupIDList
						)
					AND GroupID IN (
						SELECT GroupID
						FROM @GroupIDList
						) THEN 1
				ELSE 0 END
				) = 1
		) m
	WHERE m.TheCount BETWEEN @RowStart AND @RowEnd

	IF (@GroupID > 0)
	BEGIN
		SELECT @GroupName = GroupName
		FROM CommGroup WITH (NOLOCK)
		WHERE @GroupID = GroupID
	END

	IF (@GroupID = 0)
		SELECT @GroupName = '[None]'

	SELECT x.AffId
		,x.username
		,x.firstname
		,x.lastname
		,x.PreferredLanguage
		,x.IsClosed
		,isnull(cg.GroupName, '[None]') AS GroupName
		,x.registereddate
		,isnull(dbo.Aff_CountMember(x.AffID), 0) AS NoOfMember
		,isnull(dbo.Aff_GetAffBalance(x.AffID), 0) AS BalanceBF
		,ApprovedDate
		,isnull(f.Affid, 0) AS Favorite
		,x.GroupId
		,x.CasinoJoinedDate
	FROM @TempMember x
		LEFT JOIN CommGroup cg WITH (NOLOCK)
		ON x.GroupId = cg.GroupId
		LEFT JOIN AdminFavorite f WITH (NOLOCK)
		ON x.AffId = f.AffId
			AND f.AdminId = @UserId
	ORDER BY x.AffId
END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateSel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSel] TO [vnteam]
