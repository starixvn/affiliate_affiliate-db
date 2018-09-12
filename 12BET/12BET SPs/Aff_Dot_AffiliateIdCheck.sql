/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="Dot_member" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO


-- =============================================
-- Author:		James
-- ALTER  date: 2018-08-10
-- Description:	check whether 12bet affiliate id avaiable by affiliate id or ref code
-- =============================================
ALTER PROCEDURE [dbo].[Aff_Dot_AffiliateIdCheck]
	  @InputAffid   INT = null
	, @RefCode		VARCHAR(30) = NULL
AS

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @affPrefix VARCHAR(50),
		@affUsername VARCHAR(50),
		@affStatus	VARCHAR(30),
		@isClosed BIT,
		@AffiliateId INT,
		@ErrCode INT,
		@ErrMsg VARCHAR(100); 
		
		
	SELECT @affPrefix = '12BETAFF',
		@AffiliateId = 0, 
		@ErrCode = 0, 
		@ErrMsg = '';
	
	SET @RefCode = LTRIM(RTRIM(@RefCode));
	
	SELECT @affUsername = @affPrefix + @RefCode;
	
	IF @InputAffid IS NOT NULL
	BEGIN

		SELECT TOP(1) @AffiliateId = AffID, @affStatus = [Status], @isClosed = [IsClosed]
		FROM [dbo].[AffInfo] AS ai WITH(NOLOCK)
		WHERE AffID = @InputAffid 

	END
	ELSE IF @RefCode IS NOT NULL
	BEGIN

		SELECT TOP(1) @AffiliateId = AffID, @affStatus = [Status], @isClosed = [IsClosed]
		FROM [dbo].[AffInfo] AS ai WITH(NOLOCK)
		WHERE UserName = @affUsername;

	END

	SELECT @ErrCode = CASE WHEN (@InputAffid IS NULL AND @RefCode IS NULL) THEN 4 
						   WHEN (ISNULL(@AffiliateId, 0) <= 0) THEN 1
						   WHEN (@affStatus = 'pending') THEN 2
						   WHEN (@affStatus = 'disapproved'	OR @isClosed = 1) THEN 3
					       ELSE 0 END,
		    @ErrMsg = CASE @ErrCode
							WHEN 1 THEN 'The Input Affiliate Id or Affiliate Code does not exist. Please contact Administrator!'
							WHEN 2 THEN 'The Input Affiliate Id or Affiliate Code is not approved. Please contact Administrator!'
							WHEN 3 THEN 'The Input Affiliate Id or Affiliate Code is closed/disapproved now. Please contact Administrator!'
							WHEN 4 THEN 'InputAffid Or RefCode is required'
							ELSE '' END;
							
	IF(@ErrCode <> 0)
		SET @AffiliateId = 0;

	SELECT @AffiliateId AS AffiliateId, @ErrCode AS ErrorCode, @ErrMsg AS ErrorMessage;

END
GO