Alter PROCEDURE [dbo].[Aff_Con_CheckPermissionRead]
	@CustID int, 
	@FuncID int=null,
	@FuncName nvarchar(50)='',
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20100904@Johnny
	Task : Check permission for access Customer Page in aff amdin
	DB: DB003.bodb02 --> DB052.Affiliate_12BET

	Revisions:
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	Param's Explanation:
	• @CustID : Aff Admin CustID 
	• @FuncID : Function ID
	• @FuncName : Function Name
		
	-- Permission: bitwise(OR) permission of the group that user belong to and permission of this user
	-- IsAllow: 1:Readonly, 2:Host, 3:All
	-- Just check permission for admin, ignore when roleid < 5
*/
	IF @FuncID is null
		Select @FuncID=funcid from AffFunctionInfo with(nolock) where System = 'Affiliate' and FuncName=@Funcname
	
	 
	Declare @roleid tinyint,@IsAllow tinyint
	Select @roleid = roleid From customer with(nolock) where custid=@custid
	IF @RoleID Between 5 and 10
	BEGIN 
		SELECT @IsAllow=(isnull(mp.policy,0)|isnull(gp.policy,0)) & isnull(fi.FuncRender,0)
		FROM Affiliate_user ac with(nolock) 
			Left JOIN AffFunctionInfo fi with(nolock) on fi.funcid=@funcid
			LEFT JOIN AffMemberPolicy mp with(nolock) on mp.custid=ac.custid and mp.funcid=@funcid
			LEFT JOIN AffGroupPolicy gp with(nolock) on gp.groupid=ac.groupid and gp.funcid=@funcid
		WHERE ac.Custid=@Custid and ac.closed=0
		SELECT @IsAllow = isnull(@IsAllow,0)
	END
	ELSE IF @Roleid > 1
	BEGIN
		SELECT @IsAllow=2
	END 
	ELSE
		SELECT @IsAllow=0
		
	IF @IsAllow < 1
	BEGIN
		SELECT @ErrMsg =  case @Language
							when 'E' then N'You are not authorized on this function'
							when 'CS' then N'You are not authorized on this function'
							when 'J' then N'You are not authorized on this function'
							else N'You are not authorized on this function'
							--else N'You are not authorized to create/edit this information'
						end, @ErrCode = 500
		RETURN 
	END
	ELSE
		SET @ErrCode=0
	

GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_CheckPermissionRead] TO [vnteam]	
GO
GRANT EXECUTE ON [dbo].[Aff_Con_CheckPermissionRead] TO [bodbAdminNet]
	
