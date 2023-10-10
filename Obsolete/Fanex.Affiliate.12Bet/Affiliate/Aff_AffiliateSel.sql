ALTER PROCEDURE [dbo].[Aff_AffiliateSel] 
	@UserId 		INT 			= - 1
	,@GroupID 		INT 			= - 1
	,@Status 		VARCHAR(30)
	,@AffID 		INT 			= - 1
	,@UserName 		NVARCHAR(50) 	= NULL
	,@Email 		NVARCHAR(50) 	= NULL
	,@IsClosed 		BIT 			= NULL
	,@Language 		VARCHAR(10)		= NULL
	,@PageSize 		INT 			= 50
	,@PageIndex 	INT 			= 1
	,@IsAll 		BIT 			= 0
	,@NRows 		INT 			= 0 OUTPUT
AS
/*    
Task : Get All Affiliate for a specific page      
DB: DB052.Affiliate_12BET    
Original:[Aff_CustomerSelAffiliate]      
Revisions:          
	- 20100208@Johnny: show one more column PreferredLanguage  
	- 20141113@Bobby: Implement report's modification
		+ Remove @GroupName & @TotalPages
		+ Add filtering by @Language and @IsAll
                    
Param's Explanation:      
	. @GroupID : if @GroupID<>-1 : only search by GroupID and this function is linked from Commission Group Page    
	. @GroupName : Search by GroupName    
	• @Status : pending,Approved,disapproved      
	• @UserName : Affiliate name you want to default value=null :search all      
	• @Email : Email you want to search - default value=null :search all      
	• @PageSize : Number of rows should be returned per each page      
	• @PageIndex : Current page       
	• @NRows OUTPUT,--total of rows      
	• @Language: Prefered Language
	• @IsAll: Value is (0|1).Indicating to select all row or not
      
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @AffList	TABLE (AffId INT, RowIDX INT IDENTITY(1,1))

	SELECT @UserName	= '%' + COALESCE(@UserName, '') + '%'
		, @Email		= '%' + COALESCE(@Email, '') + '%'
		, @GroupID		= ISNULL(@GroupID, -1)
 
	INSERT INTO @AffList(AffId)
	SELECT ai.AffId
	FROM dbo.AffInfo ai WITH (NOLOCK)
		LEFT JOIN dbo.AffDetail ad WITH (NOLOCK)
		ON ai.AffID = ad.AffID
	WHERE (CASE 
			WHEN @AffID = - 1 THEN 1
			WHEN ai.AffId = @AffID THEN 1
			ELSE 0 END
			) = 1
		AND ai.Username LIKE @UserName
		AND ai.STATUS = @Status
		AND ai.Isclosed = (CASE 
			WHEN @IsClosed IS NULL OR @IsClosed = 0 THEN 0
			ELSE 1 END
			)
		AND (@Email IS NULL OR ai.Email LIKE @Email)
		AND (@GroupID = -1 OR ai.GroupID = @GroupID)
		AND (@Language IS NULL OR ad.PreferredLanguage = @Language)
	ORDER BY ai.AffID

	SET @NRows = @@ROWCOUNT

	IF (@NRows = 0) RETURN

	-- Check IsAll row
	SELECT @PageSize = CASE 
						WHEN @IsAll = 1 THEN @NRows 
						ELSE @PageSize 
					END
		,@PageIndex = CASE 
						WHEN @IsAll = 1 THEN 1 
						ELSE @PageIndex 
					END

	--fetch rows
	SELECT m.AffId
		,ai.username
		,ai.firstname
		,ai.lastname
		,ai.Email
		,ad.PreferredLanguage
		,ai.IsClosed
		,ai.GroupId
		,ISNULL(cg.GroupName, '[None]') AS GroupName
		,ai.registereddate
		,ISNULL(dbo.Aff_CountMember(m.AffID), 0) AS NoOfMember
		,ISNULL(dbo.Aff_GetAffBalance(m.AffID), 0) AS BalanceBF
		,ai.ApprovedDate
		,ISNULL(f.Affid, 0) AS Favorite
		,ai.CasinoJoinedDate
	FROM @AffList m
		LEFT JOIN dbo.AffInfo ai WITH(NOLOCK)
		ON m.AffId = ai.AffId
		LEFT JOIN dbo.AffDetail ad WITH(NOLOCK)
		ON m.AffId = ad.AffId
		LEFT JOIN dbo.CommGroup cg WITH (NOLOCK)
		ON ai.GroupId = cg.GroupId
		LEFT JOIN dbo.AdminFavorite f WITH (NOLOCK)
		ON m.AffId = f.AffId
			AND f.AdminId = @UserId

	WHERE m.RowIDX BETWEEN (((@PageIndex - 1) * @PageSize) + 1) AND (@PageSize * @PageIndex)
	
	RETURN;

END
GO

GRANT EXECUTE ON [dbo].[Aff_AffiliateSel] TO [bodbAdminNet]
GO

