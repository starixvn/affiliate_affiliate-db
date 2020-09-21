/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_GeneralInfo_Sel]
	@AffId INT
AS

/*
	Creator: 20180601@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: User site - Payment Request - Select info to send mail

	Revisions:
		- 20180601@Percy: Initiliaze SP [RedmineID: #87923]
		- 20190218@Walter: Return more column SecretKey [RedmineID: #104884]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ai.AffID, ai.UserName, ai.FirstName, ai.LastName, ai.Email, ad.PreferredLanguage, ad.MailOption, ai.SecretKey
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
	WHERE ai.AffID = @AffId
END
GO