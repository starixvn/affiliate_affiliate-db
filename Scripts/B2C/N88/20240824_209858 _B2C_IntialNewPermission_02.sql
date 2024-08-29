/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G,DBAFFYASHBET-Affiliate_YashBet"></info>*/
/*
	Created: 20240829@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G,DBAFFYASHBET-Affiliate_YashBet
	Task: B2C Affiliate - Add new permission for approve new affiliate [RedmineID: #209858]
		- Intial data for new permission
*/

	DECLARE @GroupIds TABLE (GroupId INT)
	DECLARE @UserIds  TABLE (UserId  INT)
	DECLARE @FunctIds TABLE (FunctId INT)

		INSERT INTO @GroupIds (GroupId)
			SELECT DISTINCT agh.GroupId
			FROM dbo.AffGroupPolicy agh WITH (NOLOCK)

		INSERT INTO @UserIds (UserId)
			SELECT DISTINCT amp.CustId
			FROM dbo.AffMemberPolicy amp  WITH (NOLOCK)

		INSERT INTO @FunctIds (FunctId)
			SELECT afi.FuncId
			FROM dbo.AffFunctionInfo afi WITH (NOLOCK)
			WHERE afi.FuncName IN (N'[EditAffiliateStatus]', N'[EditAffiliateDetails]')

	
	INSERT INTO dbo.AffGroupPolicy (GroupId, FuncId, Policy, CreateDate, ModifyDate, Creator)
		SELECT t.GroupId
			,t.FunctId
			,0 AS [Policy]
			,SYSDATETIME() AS CreateDate
			,SYSDATETIME() AS ModifyDate
			,1000000000 AS Creator
		FROM (
			SELECT g.GroupId, f.FunctId
			FROM @GroupIds g
				CROSS JOIN @FunctIds f 
		)t
		LEFT JOIN dbo.AffGroupPolicy ap WITH (NOLOCK) ON ap.GroupId = t.GroupId AND ap.FuncId = t.FunctId
		WHERE ap.GroupId IS NULL

	INSERT INTO dbo.AffMemberPolicy (CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
		SELECT t.UserId
			,t.FunctId
			,0 AS [Policy]
			,SYSDATETIME() AS CreateDate
			,SYSDATETIME() AS ModifyDate
			,1000000000 AS Creator
		FROM (
			SELECT g.UserId, f.FunctId
			FROM @UserIds g
				CROSS JOIN @FunctIds f 
		)t
			LEFT JOIN dbo.AffMemberPolicy ap WITH (NOLOCK) ON ap.CustId = t.UserId AND ap.FuncId = t.FunctId
		WHERE ap.CustId IS NULL