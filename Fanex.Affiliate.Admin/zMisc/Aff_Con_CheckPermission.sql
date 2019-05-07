/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_CheckPermission]
	@LicenseeID INT,
	@CustID		INT, 
	@FuncID		INT = NULL,
	@FuncName	NVARCHAR(50) = '',
	@System		NVARCHAR(50) = 'AFFILIATE',
	@Language	VARCHAR(5) = 'en-US',
	@ErrCode	INT = 0 OUTPUT,
    @ErrMsg		NVARCHAR(200) = '' OUTPUT
AS

/*
	Created:
	Task: Check permission by CustID and Function 
	DB: DBAFF-Affiliate_XXX
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_FunctionInfo_Select
							AffAdmin_f_AdminUserInfo_Select
							AffAdmin_f_UserPolicy_Select
							AffAdmin_f_GroupPolicy_Select
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tblFunction TABLE (FunctionID INT)

	DECLARE @sql NVARCHAR(MAX)

	IF @FuncID IS NULL
	BEGIN
		SELECT @sql = 'SELECT FunctionID FROM OPENQUERY(DBCUST, 
								''SELECT FunctionID FROM bodb_Licensee.dbo.AffAdmin_f_FunctionInfo_Select('''''''',' + CONVERT(VARCHAR(10), @LicenseeID) + ')
									WHERE FunctionName = ''''' + ISNULL(@Funcname, '') + ''''''')'

		INSERT INTO @tblFunction (FunctionID)
		EXEC (@sql)

		SELECT @FuncID = FunctionID FROM @tblFunction
	END
	
	DECLARE @IsAllow TINYINT

	DECLARE @tblUsers TABLE (UserID INT)

	SELECT @sql = 'SELECT UserID FROM OPENQUERY(DBCUST,
								''SELECT UserID FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @CustID) + ',' + CONVERT(VARCHAR(10), @LicenseeID) + ')'')'

	INSERT INTO @tblUsers (UserID)
	EXEC (@sql)

	DECLARE @tblPermission TABLE (IsAllow TINYINT)
	
	IF EXISTS (SELECT 1 FROM @tblUsers)
	BEGIN
		SELECT @sql = 'SELECT (ISNULL(mp_policy, 0) | ISNULL(gp_policy, 0)) & ISNULL(FunctionRender, 0) FROM OPENQUERY(DBCUST,
							''SELECT mp.policy AS mp_policy, gp.policy AS gp_policy, fi.FunctionRender
								FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @CustID) + ',' + CONVERT(VARCHAR(10), @LicenseeID) + ') ac
									LEFT JOIN bodb_Licensee.dbo.AffAdmin_f_FunctionInfo_Select(' + CONVERT(VARCHAR(20), @FuncID) + ',' + CONVERT(VARCHAR(10), @LicenseeID) + ') fi
											ON fi.FunctionID = ' + CONVERT(VARCHAR(20), @FuncID) + '
									LEFT JOIN bodb_Licensee.dbo.AffAdmin_f_UserPolicy_Select(' + CONVERT(VARCHAR(20), @CustID) + ',' + CONVERT(VARCHAR(10), @LicenseeID) + ',' + CONVERT(VARCHAR(10), @FuncID) + ') mp
											ON mp.userid = ac.userid AND mp.functionid = ' + CONVERT(VARCHAR(20), @FuncID) + '
									LEFT JOIN bodb_Licensee.dbo.AffAdmin_f_GroupPolicy_Select('''''''',' + + CONVERT(VARCHAR(20), @FuncID) + ') gp
											ON gp.groupid = ac.groupid AND gp.functionid = ' + CONVERT(VARCHAR(20), @FuncID) + '
								WHERE ac.[Status]=0'')'
			
		SELECT @IsAllow = IsAllow FROM @tblPermission

		SELECT @IsAllow = ISNULL(@IsAllow, 0)
	END
	ELSE IF EXISTS(SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffID = @CustID)
	BEGIN
		SELECT @IsAllow=2
	END 
	ELSE
		SELECT @IsAllow=0
		
	IF @IsAllow < 2
	BEGIN
		SELECT @ErrCode = 500, @ErrMsg = N'You are not authorized on this function'
		RETURN
	END
	ELSE
		SET @ErrCode=0
END
GO