USE [Affiliate_12BET]
GO

/****** Object:  StoredProcedure [dbo].[Aff_CheckPermissionOnAff]    Script Date: 12/14/2010 13:37:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Aff_CheckPermissionOnAff] 
	@CustId INT
	,@Username VARCHAR(50) = ''
	,@AffId INT = 0
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: 20090730@Peter
	Task : Select affiliate info for left panel
	DB: DB052.Affiliate_12BET

	Revisions:
		20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_12BET
	                    Remove the theory of pending commission and CurrCommEarning   
	                    Get PreferredPayment to check approve 
		20140225@Bobby: Update checking AffType for media affiliate
	                    
	Param's Explanation:
	• @Username : Affiliate username
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @AffType TINYINT

	IF (@AffId > 0)
	BEGIN
		SELECT @AffType = AffType
		FROM AffInfo WITH (NOLOCK)
		WHERE AffId = @AffId
	END
	ELSE
	BEGIN
		SELECT @AffType = AffType
		FROM AffInfo WITH (NOLOCK)
		WHERE Username = @Username
	END

	SELECT @AffId
		,@Username
		,@AffType

	IF (@AffType IS NULL)
	BEGIN
		SELECT @ErrMsg = 'You are not authorized on this function'
			,@ErrCode = 500

		RETURN
	END

	EXEC [dbo].[Aff_Con_CheckPermission] @custid = @CustId
			,@funcname = '[Affiliate]'
			,@System = 'AFFILIATE'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT
END
