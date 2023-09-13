/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
Alter PROCEDURE [dbo].[Aff_Con_AdminPolicyUpd]
	@MemPolicys NVARCHAR(4000),
	@UserID int, 
	@Language VARCHAR(2)= 'E', 
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*

DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G	
Revisions:
	-- DB03.bodb02 --> DB052.Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- Update Acc_GroupPolicy
	-- Format of @MemPolicys @CustID,@FuncID,@Policy;@CustID,@FuncID,@Policy; ...;
	-- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
	- 20230912@Sally: Fix recursion 100 has been exhausted [RedmineID: #193867]

*/
	SET NOCOUNT ON

	--Check permission for account site: @phuc20080213
	EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	If @ErrCode <> 0
		RETURN
	--end

	DECLARE @MemPolicy NVARCHAR(4000)
	DECLARE @CustID INT
	DECLARE @FuncID INT
	DECLARE @Policy INT
	DECLARE @CustPolicyCount INT 
	DECLARE CustPolicysCur CURSOR FOR 
		SELECT val AS row_index 
		FROM dbo.Aff_f_StringSplit(@MemPolicys,';')
		ORDER BY row_index	
		OPTION(MAXRECURSION 0)

	OPEN CustPolicysCur
	FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @CustID = dbo.Aff_SplitIndex(@MemPolicy, ',', 1)
		SET @FuncID = dbo.Aff_SplitIndex(@MemPolicy, ',', 2)
		SET	@Policy = dbo.Aff_SplitIndex(@MemPolicy, ',', 3)
		SET @CustPolicyCount = (SELECT COUNT(1) FROM AffMemberPolicy WITH (NOLOCK) WHERE CustID = @CustID AND funcid = @FuncID)

		IF(@CustPolicyCount = 0)
			BEGIN
				INSERT INTO AffMemberPolicy 
					(CustID, Funcid, Policy, Createdate, Modifydate, Creator)
				VALUES
					(@CustID, @Funcid, @Policy, CURRENT_TIMESTAMP,CURRENT_TIMESTAMP, @UserID)
			END
		ELSE
			BEGIN
				UPDATE AffMemberPolicy
				   SET policy = @Policy,
					 modifydate = CURRENT_TIMESTAMP
				 WHERE CustID = @CustID
				   AND funcid = @FuncID
			END
	
		DECLARE @SPName VARCHAR(50), @LogData NVARCHAR(200)
		SELECT @SPName = OBJECT_NAME(@@ProcID)

		SELECT @LogData = '[AFFILIATE]' + ' UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy) + ' of Function ' + dbo.Aff_ToString(@Funcid) +  ' for Admin ' + dbo.Aff_ToString(@CustID)

		FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
	END 
	CLOSE CustPolicysCur
	DEALLOCATE CustPolicysCur
GO