/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_GeneralInfo_Sel]
	@AffId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Payment Request - Select info to send mail

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT ai.AffID, ai.UserName, ai.FirstName, ai.LastName, ai.Email, ad.PreferredLanguage, ad.MailOption, ai.SecretKey
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
	WHERE ai.AffID = @AffId
END
GO