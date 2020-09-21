/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbDownlineNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_VerificationInfoSel]
	@AffId		INT,
    @IpAddress  NVARCHAR(25),
	@DeviceInfo  NVARCHAR(100)
AS

/*
	Creator: 20190125@Walter
	DB: DBAFFN8B-Affiliate_N8B
	Task: User site - Login - Get login information by user device

	Revisions:
		- 20190125@Walter: Initiliaze SP [RedmineID: #104884]

	Parameter's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FailedLoginCount TINYINT
	DECLARE @DeviceCount TINYINT

    SELECT @FailedLoginCount = FailedLoginCount
    FROM dbo.AffUserLoginInfo WITH (NOLOCK) 
    WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo

	SELECT @DeviceCount = COUNT(DeviceInfo)
	FROM dbo.AffUserLoginInfo WITH (NOLOCK)
	WHERE AffId = @AffId AND IP = @IpAddress
	GROUP BY AffId, IP

	SET @DeviceCount = ISNULL(@DeviceCount, 0)

	SELECT @FailedLoginCount AS FailedLoginCount, @DeviceCount AS DeviceCount
END
GO