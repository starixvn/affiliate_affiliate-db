ALTER PROCEDURE [dbo].[Aff_Con_CheckPermission]
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
	DB: DB03.BODB02 --> DB052.Affiliate_ZZun
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
*/
	SET NOCOUNT ON 
	IF @FuncID is null
		Select @FuncID=funcid from AffFunctionInfo with(nolock) where System = @System and FuncName=@Funcname
	
	-- Permission: bitwise(OR) permission of the group that user belong to and permission of this user
	-- IsAllow: 1:Readonly, 2:Host, 3:All
	
	Declare @roleid tinyint,@IsAllow tinyint
	
	IF exists(select 1 from AdminUser (nolock) where custid=@CustID)
	BEGIN 
		
			SELECT @IsAllow=(isnull(mp.policy,0)|isnull(gp.policy,0)) & isnull(fi.FuncRender,0)
			FROM AdminUser ac with(nolock) 
				--inner join custinfo ci with(nolock) on ac.custid=ci.custid
				Left JOIN AffFunctionInfo fi with(nolock) on fi.funcid=@funcid
				LEFT JOIN AffMemberPolicy mp with(nolock) on mp.custid=ac.custid and mp.funcid=@funcid
				LEFT JOIN AffGroupPolicy gp with(nolock) on gp.groupid=ac.groupid and gp.funcid=@funcid
			WHERE ac.Custid=@Custid and ac.closed=0
			SELECT @IsAllow = isnull(@IsAllow,0)
		
	END
	ELSE IF exists(select 1 from AffInfo (nolock) where AffID=@CustID)
	BEGIN
		SELECT @IsAllow=2
	END 
	ELSE
		SELECT @IsAllow=0
		
	IF @IsAllow <2
	BEGIN
		SELECT @ErrCode = 500 --You are not authorized on this function
		RETURN 
	END
	ELSE
		SET @ErrCode=0
	

	
GO
GRANT EXECUTE ON [dbo].[Aff_Con_CheckPermission] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_CheckPermission] TO [vnteam]