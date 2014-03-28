ALTER PROCEDURE [dbo].[Aff_GetMembers] 
	@Date SMALLDATETIME = NULL
AS
/*
	Created: 2013@Joseph	
	Task : Get list of member for task import member daily
	DB:  DB052.Affiliate_ZZun for Testing
	Revisions:
		- 20130731@Don : Fixed bug [Data isn't saved in DB when winlostdate < transdate in table bodb02.bettrans] (redmine.nexcel.vn/issues/4195)
		- 20140328@Bobby : Unique username [https://redmine.nexcel.vn/issues/14111]
		
*/
BEGIN
	SET @Date = ISNULL(@Date, GETDATE());

	WITH MemberList
	AS (
		SELECT m.username
		FROM dbo.MemberInfo m(NOLOCK)
		WHERE m.IsRemoved = 0
			AND datediff(d, m.RegisteredDate, cast(@Date AS VARCHAR(50))) >= - 1
			AND m.CreatedDate IS NOT NULL
			AND datediff(d, m.AffAffectedDate, @Date) >= 0
		
		UNION
		SELECT rm.UserName
		FROM dbo.MemberRemoval rm WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo m WITH (NOLOCK)
			ON rm.username = m.username
		WHERE m.IsRemoved = 1
			AND datediff(d, m.RegisteredDate, cast(@Date AS VARCHAR(50))) >= - 1
			AND m.CreatedDate IS NOT NULL
			AND datediff(d, m.AffAffectedDate, @Date) >= 0
			AND datediff(m, cast(@Date AS VARCHAR(50)), isnull(rm.RemovedDate, GetDate())) > 0
		GROUP BY rm.UserName
		)
	SELECT UserName
	FROM MemberList
	GROUP BY UserName
END
