/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_LoginInfo_Sel]
	@AffId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Home - Account Overview - Last Login Info

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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