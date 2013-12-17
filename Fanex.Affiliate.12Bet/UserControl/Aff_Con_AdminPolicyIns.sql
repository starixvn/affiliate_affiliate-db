
/****** Object:  Stored Procedure dbo.Aff_Con_AdminPolicyIns    Script Date: 7/11/2009 1:17:56 PM ******/
ALTER PROCEDURE  [dbo].[Aff_Con_AdminPolicyIns]
	@CustID int, 
	@UserID int,
	@GroupID int,
	@IP varchar(15) = ''	
AS
/*
called by sp Aff_Con_AdminIns
DB03.bodb02 --> DB052.Affiliate_12BET
Revisions:
	- VinhTrinh@20100507: insert closed field to table affiliate_user
	- 20100713@Peter : Remove Write Log on IBC DB
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
*/
SET NOCOUNT ON


INSERT INTO AffMemberPolicy(CustID,FuncID,Policy,CreateDate,ModifyDate,Creator) 
	SELECT @Custid as custid,FuncID,
		-- 0 is default value of the member policy  when create new admin
		0 as Policy, getdate() as Createdate, getdate() as ModifyDate,@UserID as Creator 
	FROM AffGroupPolicy with(nolock)
	WHERE GroupId=@GroupID

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Insert Admin policy custid:' + dbo.Aff_ToString(@custid) + ' GroupID:' + dbo.Aff_ToString(@GroupID)


EXEC [dbo].[Aff_WriteLog]
		@Creator=@UserID,	
		@AffID=@CustID,
		@Typename= 'UserControl',	
		@SPName=@SPName ,		
		@IP =@IP,
		@Details=@LogData	
		
		
		
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicyIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminPolicyIns] TO [vnteam]