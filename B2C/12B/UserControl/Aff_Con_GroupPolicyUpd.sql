/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_GroupPolicyUpd]
	@GroupPolicys NVARCHAR(4000),
	@UserID INT, 
	@Language VARCHAR(2)= 'E', 
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(50) = ''
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:
	
	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		
	Parameter's Explanation:
		- Format of @GroupPolicys: @GroupID,@FuncID,@Policy;@GroupID,@FuncID,@Policy; ...;
	
*/

BEGIN
	EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN
	
	DECLARE @GroupPolicy NVARCHAR(4000)
	DECLARE @GroupID INT
	DECLARE @FuncID INT
	DECLARE @Policy INT
	DECLARE @GroupPolicyCount INT 
	DECLARE GroupPolicysCur CURSOR FOR 
		SELECT val AS row_index 
		FROM dbo.Aff_f_StringSplit(@GroupPolicys, ';')
		ORDER BY row_index
		OPTION (MAXRECURSION 0)
	
	OPEN GroupPolicysCur
	FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @GroupID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 1)
		SET @FuncID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 2)
		SET	@Policy = dbo.Aff_SplitIndex(@GroupPolicy, ',', 3)
		SET @GroupPolicyCount = (SELECT COUNT(1) FROM AffGroupPolicy WITH (NOLOCK) WHERE GroupID = @GroupID AND funcid = @FuncID)

		IF(@GroupPolicyCount = 0)
			BEGIN
				INSERT INTO AffGroupPolicy 
					(GroupID, Funcid, Policy, Createdate, Modifydate, Creator)
				Values
					(@GroupID, @Funcid, @Policy, CURRENT_TIMESTAMP,CURRENT_TIMESTAMP, @UserID)
			END
		ELSE
			BEGIN
				UPDATE AffGroupPolicy
				   SET policy = @Policy,
					 modifydate = CURRENT_TIMESTAMP
				 WHERE GroupID = @GroupID
				   AND funcid = @FuncID
			END
		
		DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)
		SELECT @SPName = OBJECT_NAME(@@ProcID)

		SELECT @LogData = '[AFFILIATE] UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy) + ' of Function ' + dbo.Aff_ToString(@Funcid) +  ' for Group ' + dbo.Aff_ToString(@GroupID)
		
		FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	END 
	CLOSE GroupPolicysCur
	DEALLOCATE GroupPolicysCur
END
GO