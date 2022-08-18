/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_FeedbackIns]
	@AffId		INT,
	@RateId		INT = -1,
	@Message	NVARCHAR(4000) = '',
	@IP			VARCHAR(20) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
	/*
	Created: 20220802@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task : User site - Contact Us - Insert Feedback

	Revisions:
		- 20220802@Eddie: Initialize SP [RedmineID: #175628]

	Param's Explanation:
		- @AffId  : Id of affiliate in the system.
		- @RateId : 
					-1 = the popup is turned off
					0  = 'None'
					1  = 'Dissatisfaction'
					2  = 'Unsatisfied'
					3  = 'Neutral'
					4  = 'Satisfied'
					5  = 'Very Pleased'
		- @Message: content of this feedback.
		- @IP     : ip of computer sent.
		- @ErrCode: 
					= 0: Transaction recorded successfully.
					> 0: Insert unsuccessful.
		- @ErrMsg : Error description.
	*/
BEGIN
	SET NOCOUNT ON

	SELECT @RateId = ISNULL(@RateId, 0), @Message = ISNULL(@Message, '')

	----get Rate
	-- DECLARE @Rate_spec TABLE(Rateid INT, Rate VARCHAR(300))
	-- INSERT INTO @Rate_spec(Rateid, Rate)
	-- EXEC [dbo].[Aff_RateSel];
	
	IF @RateId = 0 AND @Message = ''
	BEGIN
		SELECT @ErrCode = 1001, @ErrMsg = N'Error! Insert Feedback unsuccessfully!'
		RETURN
	END

	BEGIN TRY
		INSERT INTO [dbo].[AffFeedback]( [AffId], [SentDate], [RateId], [Message] )
		VALUES( @AffId, GETDATE(), @RateId, @Message )
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = 1001, @ErrMsg = N'Error! Insert Feedback unsuccessfully!'
		RETURN
	END CATCH

	DECLARE @LogData NVARCHAR(MAX), @SPName VARCHAR(50)
	SELECT @LogData	= CONVERT(NVARCHAR(MAX),
					  (
							SELECT
								@RateId      AS '@Rate',
								@Message     AS '@Message' 
							FOR XML PATH ('row'), ROOT('root')
				      ))
				  
	SELECT @SPName = OBJECT_NAME(@@ProcID) 
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog    
			 @SPName   = @SPName
			 ,@UserId  = @AffId
			 ,@AffId   = @AffId
			 ,@OldData = NULL
			 ,@NewData = @LogData
			 ,@IP 	   = @IP
END        
GO
