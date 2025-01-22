/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_VerificationInfoSel]
	@AffId		INT,
    @IpAddress  VARCHAR(50),
	@DeviceInfo  NVARCHAR(100)
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Login - Get login information by user device

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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