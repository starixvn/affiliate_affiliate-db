/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_VerificationInfoSel]
	@AffId		INT,
    @IpAddress  VARCHAR(50),
	@DeviceInfo  NVARCHAR(100)
AS

/*
	Creator: 20190125@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Login - Get login information by user device

	Revisions:
		- 20190125@Walter: Initiliaze SP [RedmineID: #104884]
		- 20231122@Eddie: Change Datatype of IP [RedmineId : #181797]

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