/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Login_UserInfoSel]
	@UserName NVARCHAR(50)
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Login - Get user info by username

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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
		,ai.AffCode
		,ai.Password
		,cg.GroupName
		,ai.AffType
		,CASE
			WHEN ai.Status = 'Approved' AND ai.IsClosed = 1 THEN 'Closed'
			WHEN ai.Status = 'Approved' AND ai.IsRejected = 1 THEN 'Suspended'
			ELSE ai.Status END AS Status
		,ad.PreferredLanguage
		,CONVERT(BIT, CASE WHEN l.SubLevel >= @MaxSubLevel THEN 1 ELSE 0 END) AS IsMaxSubLevel
		,CONVERT(BIT, ISNULL(ad.DisabledTransfer, 1)) AS DisabledTransfer
		,ISNULL(@Dep_IsDeductedPercent, 0) AS Dep_IsDeductedPercent
		,ISNULL(@Wit_IsDeductedPercent, 0) AS Wit_IsDeductedPercent
	FROM dbo.AffInfo ai WITH (NOLOCK)
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
		INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON ai.GroupID = cg.GroupID
		OUTER APPLY (SELECT COUNT(1) AS SubLevel FROM dbo.Aff_f_StringSplit(ai.AllParentAffId, ',')) l
	WHERE ai.AffId = @AffId
	OPTION (MAXRECURSION 0)
END
GO