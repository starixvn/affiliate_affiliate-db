/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_SecurityQuestions_Sel]
	@Language VARCHAR(20) = 'en-US'
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Login function - Security Questions

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	SELECT QuestionID, Question FROM dbo.Aff_f_Get_SecurityQuestions (@Language)
END
GO
