/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupPolicyUpd]
	@LicenseeID		INT,
	@GroupPolicys	NVARCHAR(4000),
	@UserID			INT, 
	@Language		VARCHAR(5)= 'en-US', 
	@ErrCode		INT = 0 OUTPUT,
	@IP				VARCHAR(15) = ''
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
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @GroupPolicy nvarchar(4000)
	DECLARE @GroupID INT
	DECLARE @FuncID INT
	DECLARE @Policy int
	DECLARE @GroupPolicyCount int 
	
	DECLARE GroupPolicysCur CURSOR
		FOR SELECT value AS row_index FROM STRING_SPLIT(@GroupPolicys, ';') ORDER BY row_index
	
	CREATE TABLE #GroupPolicy (GroupID INT, FunctionID INT)
	INSERT INTO #GroupPolicy (GroupID, FunctionID)
	SELECT GroupID, FunctionID FROM dbo.AffAdmin_f_GroupPolicy_Select('','')

	OPEN GroupPolicysCur
	
	FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @GroupID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 1)
		SET @FuncID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 2)
		SET	@Policy = dbo.Aff_SplitIndex(@GroupPolicy, ',', 3)
		SET @GroupPolicyCount = (SELECT COUNT(1) FROM #GroupPolicy WHERE GroupID = @GroupID AND functionid = @FuncID)

		IF(@GroupPolicyCount = 0)
		BEGIN
			EXEC dbo.AffAdmin_GroupPolicy_Insert @GroupID = @GroupID, @FunctionIDs = @Funcid, @Policy = @Policy, @Creator = @UserID
		END
		ELSE
		BEGIN
			EXEC dbo.AffAdmin_GroupPolicy_Update @GroupID = @GroupID, @FunctionID = @FuncID, @Policy = @Policy
		END
		
		FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	END

	CLOSE GroupPolicysCur
	DEALLOCATE GroupPolicysCur
	
	DROP TABLE #GroupPolicy
END
GO