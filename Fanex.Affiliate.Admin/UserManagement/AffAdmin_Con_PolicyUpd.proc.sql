/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_Con_PolicyUpd]
	@LicenseeID INT,
	@MemPolicys NVARCHAR(4000),
	@UserID		INT, 
	@Language	VARCHAR(5)= 'en-US', 
	@IP			VARCHAR(15) = '',
	@ErrCode	INT = 0 OUTPUT
AS

/*
	DB: DBCUST.bodb_Licensee

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170627@Percy: Remove check permission [RedmineID: #73925]
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
		- 20220516@Malcolm: Replace strSplit to STRING_SPLIT [RedmineID: #171831] 
		- 20220615@Malcolm: Hot modify SPs to avoid dump [RedmineID: #174035] 

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
		FOR SELECT value AS row_index FROM STRING_SPLIT(@MemPolicys, ';') ORDER BY row_index	 

	CREATE TABLE #UserPolicy (UserId INT, FunctionID INT)
	INSERT INTO #UserPolicy (UserId, FunctionID)
	SELECT UserID, FunctionID FROM dbo.AffAdmin_f_UserPolicy_Select('', @LicenseeID, '')

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
			EXEC dbo.AffAdmin_UserPolicy_Insert @UserID = @CustID, @LicenseeID = @LicenseeID, @FunctionID = @FuncID, @Policy = @Policy, @Creator = @UserID
		END
		ELSE
		BEGIN
			EXEC dbo.AffAdmin_UserPolicy_Update @UserID = @CustID, @LicenseeID = @LicenseeID, @FunctionID = @FuncID, @Policy = @Policy
		END

		FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
	END
	CLOSE CustPolicysCur
	DEALLOCATE CustPolicysCur

	DROP TABLE #UserPolicy

END
GO