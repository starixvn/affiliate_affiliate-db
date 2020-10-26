/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_LoginInfo_Sel]
	@AffId INT
AS

/*
	Created: 20191210@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: User site - Home - Account Overview - Last Login Info

	Revisions:
		- 20191210@Percy: Initialize SP [RedmineID: #121971]
		- 20201026@Percy: Add AffCode [RedmineID: #143852]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffCode VARCHAR(20)
	SELECT  @AffCode = AffCode FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

	SELECT LastLoginDate, LastLoginIP, AffCode
	FROM (VALUES(@AffCode)) c (AffCode)
		OUTER APPLY
		(
			SELECT LastLoginDate, LastLoginIP
			FROM (
				SELECT LastLoginDate, IP AS LastLoginIP, ROW_NUMBER() OVER(ORDER BY LastLoginDate DESC) AS RN
				FROM dbo.AffUserLoginInfo WITH (NOLOCK)
				WHERE AffId = @AffId
			) i
			WHERE RN = 1
		) t
END
GO