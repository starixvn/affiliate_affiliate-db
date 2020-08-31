/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Login_UserInfoSel]
	@UserName NVARCHAR(50)
AS

/*
	Creator: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task: User site - Login - Get user info by username

	Revisions:
		- 20200220@Percy: Initiliaze SP [RedmineID: #128775]

	Parameter's Explanation:
		- @UserName: username

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffId INT, @GroupId INT
	SELECT  @AffId = AffId, @GroupId = GroupId FROM dbo.AffInfo WITH (NOLOCK) WHERE UserName = @UserName

	IF @@ROWCOUNT = 0
		RETURN

	-- Get max sub affiliate level
	DECLARE @MaxSubLevel SMALLINT
	SELECT  @MaxSubLevel = CONVERT(SMALLINT, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'MaxSubLevel'

	SELECT @MaxSubLevel = ISNULL(@MaxSubLevel, 0)

	-- Get deposit & withdrawal fee setting
	DECLARE @Dep_IsDeductedPercent BIT, @Wit_IsDeductedPercent BIT
	SELECT  @Dep_IsDeductedPercent = CASE WHEN DeductionId = 13 THEN IsDeductedPercent ELSE @Dep_IsDeductedPercent END
			,@Wit_IsDeductedPercent = CASE WHEN DeductionId = 14 THEN IsDeductedPercent ELSE @Wit_IsDeductedPercent END
	FROM dbo.DeductionSetting WITH (NOLOCK)
	WHERE GroupId = @GroupId
		AND DeductionId IN (13, 14)

	SELECT
		ai.AffID
		,ai.UserName
		,ai.Password
		,cg.GroupName
		,ai.AffType
		,ai.IsClosed
		,ai.Status
		,ad.PreferredLanguage
		,CASE WHEN l.SubLevel >= @MaxSubLevel THEN 1 ELSE 0 END AS IsMaxSubLevel
		,ISNULL(@Dep_IsDeductedPercent, 0) AS Dep_IsDeductedPercent
		,ISNULL(@Wit_IsDeductedPercent, 0) AS Wit_IsDeductedPercent
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupID = cg.GroupID
		OUTER APPLY (SELECT COUNT(1) AS SubLevel FROM dbo.Aff_f_StringSplit(ai.AllParentAffId, ',')) l
	WHERE ai.AffId = @AffId
END
GO