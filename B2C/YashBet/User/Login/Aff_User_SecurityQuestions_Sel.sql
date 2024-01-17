/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbDownlineNet,bodbDownlineNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_SecurityQuestions_Sel]
	@Language VARCHAR(20) = 'en-US'
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Login function - Security Questions

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT QuestionID, Question FROM dbo.Aff_f_Get_SecurityQuestions (@Language)
END
GO
