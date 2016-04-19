USE Affiliate_12bet
GO
ALTER PROCEDURE [dbo].[Aff_API_AffiliateUser_SelStatus]
	@RefCode		VARCHAR(30)
	, @AffiliateId 	INT = 0 OUTPUT
	, @ErrCode 		INT = 0 OUTPUT
	, @ErrMsg 		VARCHAR(100) = '' OUTPUT
AS
/*
	Task : #55630 - Member signup under inputed affiliate
	Author : Bobby.Nguyen@20160418
	DB: Affiliate_12bet
	Revisions: 		
		
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @affPrefix		VARCHAR(50) 
		,@affUsername		VARCHAR(50) 
		,@affStatus			VARCHAR(30)
		,@isClosed			BIT
	
	SELECT @ErrCode 		= 0
		, @ErrMsg 			= ''
		, @AffiliateId		= 0
		, @affPrefix 		= '12BETAFF'
		, @RefCode			= LTRIM(RTRIM(@RefCode))
		
	SELCT @affUsername  	= @affPrefix + @RefCode
	
	SELECT TOP(1) 
		@AffiliateId 		= AffID
		, @affStatus		= [Status]
		, @isClosed 		= [IsClosed]
		
	FROM [dbo].[AffInfo] ai WITH (NOLOCK)
	WHERE UserName 			= @affUsername
	
	SELECT @ErrCode 		= CASE 
								WHEN (ISNULL(@AffiliateId, 0) <= 0) 	THEN 1
								WHEN (@affStatus IN ('pending')) 		THEN 2
								WHEN (@affStatus IN ('disapproved')	OR @isClosed = 1) THEN 3
								ELSE 0 
							END
		, @ErrMsg 			= CASE 
								WHEN (ISNULL(@AffiliateId, 0) <= 0) 	THEN 'The Affiliate Code does not exist. Please contact Administrator!'
								WHEN (@affStatus IN ('pending')) 		THEN 'The Affiliate Code is not approved. Please contact Administrator!'
								WHEN (@affStatus IN ('disapproved')	OR @isClosed = 1) THEN 'The Affiliate Code is closed/disapproved now. Please contact Administrator!'
								ELSE '' 
							END
							
	IF(@ErrCode <> 0)
		SET @AffiliateId = 0
		
	RETURN;
END

GRANT EXECUTE ON [dbo].[Aff_API_AffiliateUser_SelStatus] TO [Dot_Member] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_API_AffiliateUser_SelStatus] TO [vnteam] AS [dbo]
GO
