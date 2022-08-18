/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_FeedbackPopup_Check]
	@AffId INT,
	@IsShowPopup  BIT = 0 OUTPUT	
AS
	/*
	Created: 20220803@Eddie
	DB: DBAFF12BET.Affiliate_12Bet
	Task : User site - Contact Us - Feedback pop_up

	Revisions:
		- 20220803@Eddie: Initialize SP [RedmineID: #175628]


	Param's Explanation:
		- @AffId  : Id of affiliate in the system.
		- @IsShowPopup :
					0  =  Form Feedback is not showed
					1  =  Form Feedback is showed
	*/
BEGIN

	SET NOCOUNT ON
	
	DECLARE @CheckDate INT = 0, @CheckTime INT = 0, @RateId INT = -100, @IsSubmitted BIT = 0
	DECLARE @CurrentTime DATETIME = current_timestamp
	SET @IsShowPopup = 1
	
	
	SELECT TOP(1) 
		@CheckDate = DATEDIFF(DAY, SentDate, @CurrentTime)
		,@CheckTime = DATEDIFF(MINUTE, SentDate, @CurrentTime)
		,@IsSubmitted = CASE WHEN RateId IN ( -1 ) THEN 0 ELSE 1 END
		,@RateId = RateId
	FROM dbo.AffFeedback WITH (NOLOCK)
	WHERE AffId = @AffId
	ORDER BY FID DESC
		
	IF (@CheckDate < 30 AND @IsSubmitted = 1)
	BEGIN
		SELECT @IsShowPopup = 0
	END
	ELSE IF (@CheckDate = 30 AND @IsSubmitted = 1)
	BEGIN
		SELECT @IsShowPopup = 1
	END
	ELSE
	BEGIN
		IF @RateId = -1
		BEGIN
			IF @CheckDate >= 7 -- the popup is shown up again on next 7 days
			BEGIN
				SELECT @IsShowPopup = 1
			END
			ELSE SELECT @IsShowPopup = 0
		END
	END
END        
GO
