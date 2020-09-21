/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_CheckPermission]
	@CustID		INT, 
	@FuncID		INT = NULL,
	@FuncName	NVARCHAR(50) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
AS
/*
	Created:
	Task: Check permission by CustID and Function
	DB: DBAFFN8G-Affiliate_N8G

	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
		- 20101214@Peter: Move this SP to DB DB052.Affiliate_12BET
*/
BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	DECLARE @IsAllow TINYINT
	SET @IsAllow = 0

	IF @FuncID IS NULL
		SELECT @FuncID = FuncID FROM dbo.AffFunctionInfo WITH (NOLOCK) WHERE FuncName = @FuncName

	IF ISNULL(@FuncID, 0) > 0
	BEGIN
		SELECT @IsAllow = (ISNULL(mp.policy,0)|ISNULL(gp.policy,0)) & ISNULL(fi.FuncRender,0)
		FROM dbo.Affiliate_User ac WITH (NOLOCK)
			LEFT JOIN dbo.AffFunctionInfo fi WITH (NOLOCK) ON fi.FuncID = @FuncID
			LEFT JOIN dbo.AffMemberPolicy mp WITH (NOLOCK) ON mp.CustID = ac.CustID AND mp.FuncID = @FuncID
			LEFT JOIN dbo.AffGroupPolicy gp WITH (NOLOCK) ON gp.GroupID = ac.GroupID AND gp.FuncID = @FuncID
		WHERE ac.CustID = @CustID
			AND ac.closed = 0
	END

	IF ISNULL(@IsAllow, 0) < 2
	BEGIN
		SELECT @ErrCode = 500, @ErrMsg = 'You are not authorized on this function'
	END
END
GO