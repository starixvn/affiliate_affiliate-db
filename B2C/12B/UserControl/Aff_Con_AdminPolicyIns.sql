/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE  [dbo].[Aff_Con_AdminPolicyIns]
	@CustID INT, 
	@UserID INT,
	@GroupID INT,
	@IP VARCHAR(50) = ''	
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Called by sp Aff_Con_AdminIns

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/
BEGIN
	SET NOCOUNT ON

	INSERT INTO AffMemberPolicy (CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
	SELECT @CustID AS custid
		,FuncId
		,0 AS Policy -- 0 is default value of the member policy  when create new admin
		,GETDATE() AS Createdate
		,GETDATE() AS ModifyDate
		,@UserID AS Creator
	FROM AffGroupPolicy WITH (NOLOCK)
	WHERE GroupId = @GroupID

	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)
	SELECT @LogData = 'Insert Admin policy custid:' + dbo.Aff_ToString(@CustID) + ' GroupID:' + dbo.Aff_ToString(@GroupID)
END
GO