/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20250411@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Enhance Get BBF by TimeZone [RedmineID: #222401]
	-------------------------
	USE Affiliate_N88
	GO

	USE Affiliate_N8B
	GO

	USE Affiliate_N8G
	GO
*/

IF EXISTS(
    SELECT TOP 1 1 FROM dbo.AffTrans WITH (NOLOCK) WHERE WinlostDate <> CAST(CONVERT(VARCHAR(10), DATEADD(HOUR, 12, TransDate), 120) AS SMALLDATETIME)
)
BEGIN
	UPDATE dbo.AffTrans WITH (UPDLOCK, ROWLOCK)
	SET WinlostDate = CAST(CONVERT(VARCHAR(10), DATEADD(HOUR, 12, TransDate), 120) AS SMALLDATETIME)
	WHERE WinlostDate <> CAST(CONVERT(VARCHAR(10), DATEADD(HOUR, 12, TransDate), 120) AS SMALLDATETIME)
END
GO
