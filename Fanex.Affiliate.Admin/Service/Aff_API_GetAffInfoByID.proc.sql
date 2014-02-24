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
	IF(@AffID IS NULL OR @AffID <= 0)
	BEGIN
		SELECT @ErrorCode = 101
			, @ErrorMsg = 'Invalid affiliate ID.'
		RETURN;
	END

	SELECT TOP(1) AffID
		, UserName
		, (FirstName + ' ' + LastName) AS FullName
		, Email
	FROM [dbo].[AffInfo] ai WITH(NOLOCK)
	WHERE AffID = @AffID
END
GO

GRANT EXECUTE ON [dbo].[Aff_API_GetAffInfoByID] TO [bodbAdminNet] AS [dbo]