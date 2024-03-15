/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_IPConvertToNumber]
(
	@IP VARCHAR(25)
)
RETURNS BIGINT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Convert IP format to integer number

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET @IP = LTRIM(RTRIM(@IP))

	IF @IP LIKE '%_%.%_%.%_%.%_%'
	BEGIN
		DECLARE @IPA BIGINT, @IPB BIGINT, @IPC BIGINT, @IPD BIGINT

		SELECT @IPA = LEFT(@IP, PATINDEX('%.%', @IP) - 1)
		SELECT @IP = RIGHT(@IP, LEN(@IP) - LEN(@IPA) - 1)

		SELECT @IPB = LEFT(@IP, PATINDEX('%.%', @IP) - 1)
		SELECT @IP = RIGHT(@IP, LEN(@IP) - LEN(@IPB) - 1)

		SELECT @IPC = LEFT(@IP, PATINDEX('%.%', @IP) - 1)
		SELECT @IP = RIGHT(@IP, LEN(@IP) - LEN(@IPC) - 1)

		SELECT @IPD = @IP

		RETURN @IPA*256*256*256 + @IPB*256*256 + @IPC*256 + @IPD
	END

	RETURN 0
END
GO