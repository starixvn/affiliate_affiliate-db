ALTER PROCEDURE [dbo].[AffAdmin_EmailHistorySel] 
	@MID INT = NULL
	,@SenderName NVARCHAR(50) = NULL
	,@Email NVARCHAR(50) = NULL
	,@AffiliateUserName VARCHAR(30) = NULL
	,@fromdate SMALLDATETIME = NULL
	,@todate SMALLDATETIME = NULL
	,@PageSize INT = 50
	,@PageIndex INT = 1
	,@TotalPages INT = 0 OUTPUT
	,@NRows INT = 0 OUTPUT
AS
/*  
Created: 20090626@VinhTrinh  
Task : Insert new email for EmailHistory  
DB: DB052.Affiliate_ZZun  
Original:  

Revisions:  
	- 20131114@Johnny: fix bugs
	- 20140516: Return to no record instead NULL

Param's Explanation:  
• @MID : mail id  
        Null: search all  
        id>0 : search for id  
        <0 : search unknown email( affiliateid=-1)  
.@SenderName: search by sender name.  
.@Email: search by email      
.@AffiliateUserName: search by Affiliate User Name     
• @PageSize : Number of rows should be returned per each page  
• @PageIndex : Current page   
• @TotalPages OUTPUT : total of pages for this search  
  
• @NRows OUTPUT,--total of rows  
  
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @RowStart INT
		,@RowEnd INT
		,@AffiliateID INT

	--Search by unregistered affiliate  
	IF (@MID < 0)
	BEGIN
		SELECT @AffiliateID = - 1
			,@MID = NULL
	END

	/*  
if (isnull(@AffiliateUserName,'')<>'')  
 begin    
     select @AffiliateID=AffId   
     from AffInfo with (nolock)  
     where username=@AffiliateUserName  
     if(coalesce(@AffiliateID,-2)=-2)  
        return  
 end  
 */
	--select @AffiliateUserName = '%' + Coalesce(@AffiliateUserName, '') + '%'   
	SELECT @SenderName = '%' + Coalesce(@SenderName, '') + '%'

	SELECT @Email = '%' + Coalesce(@Email, '') + '%'

	SELECT @Nrows = count(1)
	FROM EmailHistory WITH (NOLOCK)
	WHERE MID = Coalesce(@MID, mid)
		AND sender LIKE @SenderName
		AND email LIKE @Email
		AND (CASE 
			WHEN @AffiliateUserName IS NULL THEN 1
			WHEN AffName LIKE '%' + @AffiliateUserName + '%'
				AND AffId > 0 THEN 1
			ELSE 0 END
			) = 1
		AND (CASE 
			WHEN AffID = @AffiliateID
				OR @AffiliateID IS NULL THEN 1
			ELSE 0 END
			) = 1
		AND (CASE 
			WHEN @fromdate IS NULL
				OR @todate IS NULL THEN 1
			WHEN CreatedDate BETWEEN @fromdate AND @todate THEN 1
			ELSE 0 END
			) = 1

	--IF (isnull(@NRows, 0) = 0) RETURN
	SELECT @TotalPages = @NRows / @PageSize + CASE 
			WHEN @NRows % @PageSize > 0 THEN 1
			ELSE 0
			END
		,@PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	SELECT mid
		,content
		,sender
		,AffId AS AffiliateID
		,affname
		,email
		,subject
		,CreatedDate AS CreateDate
		,ip
		,browser
	FROM (
		SELECT mid
			,content
			,sender
			,AffId
			,affname
			,email
			,subject
			,CreatedDate
			,ip
			,browser
			,ROW_NUMBER() OVER (
				ORDER BY CreatedDate DESC
					,AffId ASC
				) AS TheCount
		FROM EmailHistory WITH (NOLOCK)
		WHERE MID = Coalesce(@MID, mid)
			AND sender LIKE @SenderName
			AND email LIKE @Email
			AND (CASE 
				WHEN @AffiliateUserName IS NULL THEN 1
				WHEN AffName LIKE '%' + @AffiliateUserName + '%'
					AND AffId > 0 THEN 1
				ELSE 0 END
				) = 1
			AND (CASE 
				WHEN AffID = @AffiliateID
					OR @AffiliateID IS NULL THEN 1
				ELSE 0 END
				) = 1
			AND (CASE 
				WHEN @fromdate IS NULL
					OR @todate IS NULL THEN 1
				WHEN CreatedDate BETWEEN @fromdate AND @todate THEN 1
				ELSE 0 END
				) = 1
		) x
	WHERE x.TheCount BETWEEN @RowStart AND @RowEnd
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_EmailHistorySel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_EmailHistorySel] TO [vnteam]
