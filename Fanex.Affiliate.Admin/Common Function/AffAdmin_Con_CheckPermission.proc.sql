ALTER PROCEDURE [dbo].[AffAdmin_Con_CheckPermission]
	@LicenseeID INT,
	@CustID int,   
	@FuncID int=null,  
	@FuncName nvarchar(50)='',  
	@System nvarchar(50) = 'AFFILIATE',
	@Language varchar(2) = 'E',  
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*  
 Created: 20131105@Johnny
 Task: Check permission by CustID and Function
 DB: 
   
 Revisions: 
	- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/  
 SET NOCOUNT ON   
 IF @FuncID is null  
  Select @FuncID=functionid from dbo.AffAdmin_f_FunctionInfo_Select('',@LicenseeID) where FunctionName=@Funcname
   
 -- Permission: bitwise(OR) permission of the group that user belong to and permission of this user  
 -- IsAllow: 1:Readonly, 2:Host, 3:All  
   
 Declare @roleid tinyint,@IsAllow tinyint  
   
 IF exists(select 1 from dbo.AffAdmin_f_AdminUserInfo_Select(@CustID,@LicenseeID))  
 BEGIN   
    
   SELECT @IsAllow=(isnull(mp.policy,0)|isnull(gp.policy,0)) & isnull(fi.FunctionRender,0)  
   FROM dbo.AffAdmin_f_AdminUserInfo_Select(@CustID,@LicenseeID) ac   
		Left JOIN dbo.AffAdmin_f_FunctionInfo_Select(@funcid,@LicenseeID) fi on fi.FunctionID = @funcid
		LEFT JOIN dbo.AffAdmin_f_UserPolicy_Select(@CustID, @LicenseeID, @funcID) mp on mp.userid=ac.userid and mp.functionid=@funcid
		LEFT JOIN dbo.AffAdmin_f_GroupPolicy_Select('',@funcid) gp on gp.groupid=ac.groupid and gp.functionid=@funcid
   WHERE ac.[Status]=0  
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
GRANT EXECUTE ON [dbo].[AffAdmin_Con_CheckPermission] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_Con_CheckPermission] TO [vnteam] AS [dbo]