/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_CheckPermission]
	@CustId		INT
	,@FuncId	INT = NULL
	,@FuncName	VARCHAR(100) = ''
	,@Language	VARCHAR(10) = 'en-US'
	,@Policy	TINYINT = 0 OUTPUT
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Check user permission on function

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = ''

	IF @FuncId IS NULL
		SELECT @FuncId = FuncId FROM dbo.Functions WITH (NOLOCK) WHERE FuncName = @FuncName

	IF EXISTS (SELECT 1 FROM dbo.Users WITH (NOLOCK) WHERE CustId = @CustId)
		SELECT @Policy = uf.Policy
		FROM dbo.Users u WITH (NOLOCK)
			INNER JOIN dbo.UserFunction uf WITH (NOLOCK) ON u.CustId = uf.CustId
		WHERE u.CustId = @CustId
			AND u.Closed = 0
			AND u.IsDeleted = 0
			AND uf.FuncId = @FuncId
	ELSE IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @CustId)
		SELECT @Policy = 3

	SELECT @Policy = ISNULL(@Policy, 0)

	IF @Policy < 3
		SELECT @ErrCode = 500, @ErrMsg = dbo.Aff_f_GetMessageById(1401, @Language)
END
GO