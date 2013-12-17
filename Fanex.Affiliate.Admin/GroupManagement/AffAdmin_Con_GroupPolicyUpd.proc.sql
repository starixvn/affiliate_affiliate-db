ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupPolicyUpd]
	@GroupPolicys NVARCHAR(4000),
	@UserID int, 
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@IP varchar(15) = ''
AS
/*DB03.BODB02 --> DB052.Affiliate_ZZun*/
-- Update Acc_GroupPolicy
-- Format of @GroupPolicys: @GroupID,@FuncID,@Policy;@GroupID,@FuncID,@Policy; ...;
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
	
--Check permission for account site: @phuc20080213
EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output
If @ErrCode <> 0
	RETURN
--end
	
	
	DECLARE @GroupPolicy nvarchar(4000)
	DECLARE @GroupID INT
	DECLARE @FuncID INT
	DECLARE @Policy int
	DECLARE @GroupPolicyCount int 
	DECLARE GroupPolicysCur CURSOR FOR 
		SELECT val as row_index 
		  FROM dbo.strSplit(@GroupPolicys, ';')
		 ORDER BY row_index
	
	OPEN GroupPolicysCur
	FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @GroupID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 1)
		SET @FuncID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 2)
		SET	@Policy = dbo.Aff_SplitIndex(@GroupPolicy, ',', 3)
		SET @GroupPolicyCount = (SELECT COUNT(1) FROM AffGroupPolicy with (nolock) WHERE GroupID = @GroupID AND funcid = @FuncID)

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
		
		DECLARE @SPName varchar(50), @LogData nvarchar(200)
		select @SPName = OBJECT_NAME(@@ProcID)

		SELECT @LogData = '[AFFILIATE] UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy) + ' of Function ' + dbo.Aff_ToString(@Funcid) +  ' for Group ' + dbo.Aff_ToString(@GroupID)
		


		EXEC [dbo].[Aff_WriteLog]
				@Creator=@UserID,	
				@AffID=0,
				@Typename= 'UserControl',	
				@SPName=@SPName ,		
				@IP =@IP,
				@Details=@LogData	

		FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
	END 
	CLOSE GroupPolicysCur
	DEALLOCATE GroupPolicysCur
	
	




