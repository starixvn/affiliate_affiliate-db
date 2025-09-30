ALTER PROCEDURE [dbo].[Aff_API_GetAffInfoByID]
	@AffID INT
	, @ErrorCode INT = 0 OUTPUT
	, @ErrorMsg varchar(100) = '' OUTPUT
AS
/*
	Task : Implement API to provide affiliate information
	Author : Bobby.Nguyen@20140224
	DB: Affiliate_Athena000
	Revisions: 		

*/
BEGIN
	SET NOCOUNT ON;
	
	SELECT @ErrorCode = 0
		, @ErrorMsg = '';

	IF(@AffID IS NULL OR @AffID <= 0)
	BEGIN
		SELECT @ErrorCode = 101
			, @ErrorMsg = 'Invalid affiliate ID.'
		RETURN;
	END

	DECLARE @UserName	VARCHAR(50)
		, @FullName		VARCHAR(100)
		, @Email		VARCHAR(100)
		, @Status		VARCHAR(30)
		, @IsClosed	BIT;

	SELECT TOP(1) 
		@UserName	= UserName
		, @FullName = (FirstName + ' ' + LastName)
		, @Email	= Email
		, @Status	= [Status]
		, @IsClosed = [IsClosed]
	FROM [dbo].[AffInfo] ai WITH(NOLOCK)
	WHERE AffID = @AffID

	IF(@UserName IS NOT NULL
		AND @Status='approved' 
		AND @IsClosed = 0)
	BEGIN
		SELECT @AffID AS AffID 
			, @UserName AS UserName
			, @FullName AS FullName
			, @Email AS Email
	END
	ELSE IF(@UserName IS NOT NULL
		AND (@Status <> 'approved' 
		OR @IsClosed <> 0))
	BEGIN
		SELECT @ErrorCode = 103
			, @ErrorMsg = 'Sorry! This affiliate is ' +  @Status + ' now.'
	END
	ELSE
	BEGIN
		SELECT @ErrorCode = 102
			, @ErrorMsg = 'Affiliate does not exist.'
	END
	RETURN;	
END

GRANT EXECUTE ON [dbo].[Aff_API_GetAffInfoByID] TO [bodbDownlineNet] AS [dbo]