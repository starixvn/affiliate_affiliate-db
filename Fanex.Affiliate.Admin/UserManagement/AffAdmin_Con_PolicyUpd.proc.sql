ALTER PROCEDURE [dbo].[AffAdmin_Con_PolicyUpd]
	@MemPolicys NVARCHAR(4000),
	@UserID int, 
	@Language varchar(5)= 'en-US', 
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT
AS
--DB03.bodb02 --> DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
-- Update Acc_GroupPolicy
-- Format of @MemPolicys @CustID,@FuncID,@Policy;@CustID,@FuncID,@Policy; ...;
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC [dbo].[AffAdmin_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output
If @ErrCode <> 0
	RETURN
--end



DECLARE @MemPolicy nvarchar(4000)
DECLARE @CustID INT
DECLARE @FuncID INT
DECLARE @Policy int
DECLARE @CustPolicyCount int 
DECLARE CustPolicysCur CURSOR FOR 
	SELECT val as row_index 
	  FROM dbo.strSplit(@MemPolicys, ';')
	 ORDER BY row_index	 


OPEN CustPolicysCur
FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
WHILE @@FETCH_STATUS = 0
BEGIN

	SET @CustID = dbo.Aff_SplitIndex(@MemPolicy, ',', 1)
	SET @FuncID = dbo.Aff_SplitIndex(@MemPolicy, ',', 2)
	SET	@Policy = dbo.Aff_SplitIndex(@MemPolicy, ',', 3)
	SET @CustPolicyCount = (SELECT COUNT(1) FROM AffMemberPolicy with (nolock) WHERE CustID = @CustID AND funcid = @FuncID)

	IF(@CustPolicyCount = 0)
		BEGIN
			INSERT INTO AffMemberPolicy 
				(CustID, Funcid, Policy, Createdate, Modifydate, Creator)
			Values
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
	
	DECLARE @SPName varchar(50), @LogData nvarchar(200)
	select @SPName = OBJECT_NAME(@@ProcID)

	SELECT @LogData = '[AFFILIATE]' + ' UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy) + ' of Function ' + dbo.Aff_ToString(@Funcid) +  ' for Admin ' + dbo.Aff_ToString(@CustID)


	EXEC [dbo].[Aff_WriteLog]
			@Creator=@UserID,	
			@AffID=@CustID,
			@Typename= 'UserControl',	
			@SPName=@SPName ,		
			@IP =@IP,
			@Details=@LogData	
		

	FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
END 
CLOSE CustPolicysCur
DEALLOCATE CustPolicysCur

