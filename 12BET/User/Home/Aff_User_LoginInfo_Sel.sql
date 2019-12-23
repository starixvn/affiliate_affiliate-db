/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_LoginInfo_Sel]
	@AffId INT
AS

/*
	Created: 20191210@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Home - Account Overview - Last Login Info

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121971]
*/

BEGIN
	SET NOCOUNT ON

	SELECT LastLoginDate, LastLoginIP
	FROM (
		SELECT LastLoginDate, LastLoginIP, ROW_NUMBER() OVER(ORDER BY LastLoginDate DESC) AS RN
		FROM dbo.AffLoginInfo WITH (NOLOCK)
		WHERE AffId = @AffId
	) i
	WHERE RN = 1
END
GO