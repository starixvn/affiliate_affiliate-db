/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_Con_PolicyUpd]
	@LicenseeID INT,
	@MemPolicys NVARCHAR(4000),
	@UserID int, 
	@Language varchar(5)= 'en-US', 
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT
AS

/*
	DB: DBAFF

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]

	Param's Explanation:
		. Format of @MemPolicys: @CustID,@FuncID,@Policy;@CustID,@FuncID,@Policy; ...;
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MemPolicy nvarchar(4000)
	DECLARE @CustID INT
	DECLARE @FuncID INT
	DECLARE @Policy int
	DECLARE @CustPolicyCount int 
	DECLARE CustPolicysCur CURSOR
		FOR SELECT val AS row_index FROM dbo.strSplit(@MemPolicys, ';') ORDER BY row_index	 

	SELECT * INTO #UserPolicy FROM dbo.AffAdmin_f_UserPolicy_Select('', @LicenseeID, '')

	-- Write log  
	DECLARE @SPName VARCHAR(50), @Detail NVARCHAR(4000)

	SELECT	@SPName = OBJECT_NAME(@@PROCID)

	OPEN CustPolicysCur
	FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @CustID = dbo.Aff_SplitIndex(@MemPolicy, ',', 1)
		SET @FuncID = dbo.Aff_SplitIndex(@MemPolicy, ',', 2)
		SET	@Policy = dbo.Aff_SplitIndex(@MemPolicy, ',', 3)
		SET @CustPolicyCount = (SELECT COUNT(1) FROM #UserPolicy with (nolock) WHERE UserID = @CustID AND FunctionID = @FuncID)

		IF(@CustPolicyCount = 0)
		BEGIN
			EXEC DBLIC.bodb_licensee.dbo.AffAdmin_UserPolicy_Insert @UserID = @CustID, @LicenseeID = @LicenseeID, @FunctionID = @FuncID, @Policy = @Policy, @Creator = @UserID
		END
		ELSE
		BEGIN
			EXEC DBLIC.bodb_licensee.dbo.AffAdmin_UserPolicy_Update @UserID = @CustID, @LicenseeID = @LicenseeID, @FunctionID = @FuncID, @Policy = @Policy
		END
	
		
		SELECT @Detail = '[AFFILIATE]' + ' UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy)
						+ ' of Function ' + dbo.Aff_ToString(@Funcid)
						+ ' for Admin ' + dbo.Aff_ToString(@CustID)

		EXEC [dbo].[Aff_WriteLog]
			@Creator = @UserID,	
			@AffID = @CustID,
			@Typename = 'UserControl',	
			@SPName = @SPName ,		
			@IP = @IP,
			@Details = @Detail	

		FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
	END
	CLOSE CustPolicysCur
	DEALLOCATE CustPolicysCur

	DROP TABLE #UserPolicy
END
GO