/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*
	Created: 20240910@Sally
	DB: DBAFFN88-Affiliate_N88
	Task: B2C Affiliate -  Aff Code not generated when approves Aff with existing Revenue Group [RedmineID: #210510]

*/
USE Affiliate_N88
GO

	DECLARE @AffId INT = NULL
		,@UserName NVARCHAR(30) = 'N88AFF2962'
		,@MonthDate SMALLDATETIME

	SELECT @AffId = AffId
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE UserName = @UserName
	
	IF (@AffId IS NOT NULL)
	BEGIN
		SELECT @MonthDate = EOMONTH(GETDATE())

		-- SELECT Status,Password,ApprovedDate,ApprovedBy,AffCode, GroupId,*
		UPDATE a SET a.Status = 'Pending', a.Password = NULL, a.ApprovedDate = NULL, a.ApprovedBy= NULL, a.AffCode = NULL, a.GroupId = NULL
		FROM dbo.AffInfo a WITH (UPDLOCK, ROWLOCK)
		WHERE a.AffId = @AffId

		-- Clear History
		UPDATE af SET af.GroupId = 0
		FROM dbo.AffGroupHistory af WITH (UPDLOCK, ROWLOCK)
		WHERE AffId = @AffId
			AND MonthDate = @MonthDate
	END
