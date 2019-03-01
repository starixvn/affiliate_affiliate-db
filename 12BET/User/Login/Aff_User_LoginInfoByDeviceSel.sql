/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_LoginInfoByDeviceSel]
	@AffId		INT,
    @IpAddress  NVARCHAR(25),
	@DeviceInfo  NVARCHAR(100)
AS

/*
	Creator: 20190125@Walter
	DB: DBAFF12BET.Affiliate_12BET
	Task: User site - Login - Get login information by user device

	Revisions:
		- 20190125@Walter: Initiliaze SP [RedmineID: #104884]

	Parameter's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FailedLoginCount TINYINT

    SELECT @FailedLoginCount = FailedLoginCount
    FROM dbo.AffLoginByUserDevices WITH (NOLOCK) 
    WHERE AffId = @AffId AND IP = @IpAddress AND DeviceInfo = @DeviceInfo

	SELECT ISNULL(@FailedLoginCount, 0)
END
GO