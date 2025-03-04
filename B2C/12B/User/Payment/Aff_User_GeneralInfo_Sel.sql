/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_GeneralInfo_Sel]
	@AffId INT = 0,
	@AffCode VARCHAR(20) = ''
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Payment Request - Select info to send mail

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
        - 20250227@Sally: Enhance AFFMediaLink  [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	IF ISNULL(@AffCode, '') <> ''
		SELECT @AffId = AffId FROM dbo.AffiliateCode WITH (NOLOCK) WHERE AffCode = @AffCode

	SELECT ai.AffID, ai.UserName, ai.FirstName, ai.LastName, ai.Email, ad.PreferredLanguage, ad.MailOption, ai.SecretKey, ai.AffCode
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
	WHERE ai.AffID = @AffId
    
END
GO