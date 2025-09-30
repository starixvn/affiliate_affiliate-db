/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_CheckPermission]
	@LicenseeID INT,
    @CustID int, 
    @FuncID int=null,
    @FuncName nvarchar(50)='',
    @System nvarchar(50) = 'AFFILIATE',
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT    
AS

/*
	Created by: []
    Task: Check permission by CustID and Function 
    DB: DBAFF.Affiliate_XXX
    
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
	SET NOCOUNT ON;

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
		SELECT @sql = 'SELECT IsAllow FROM OPENQUERY(DBCUST,
							''SELECT IsAllow FROM bodb_Licensee.dbo.Aff_f_Con_IsAllowByUserID(' + CONVERT(VARCHAR(20), @CustID) + ',' + CONVERT(VARCHAR(10), @LicenseeID) + ',' + CONVERT(VARCHAR(10), @FuncID) + ')'')'
			
		INSERT INTO @tblPermission (IsAllow)
		EXEC (@sql)

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
		SELECT @ErrCode = 500
		RETURN
	END
	ELSE
		SET @ErrCode=0
END
GO