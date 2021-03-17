/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_IPConvertToNumber]
(
	@IP VARCHAR(25)
)
RETURNS BIGINT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Convert IP format to integer number

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID]
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