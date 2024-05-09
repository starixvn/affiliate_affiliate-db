/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE  [dbo].[Aff_Con_AdminPolicyIns]
	@CustID INT, 
	@UserID INT,
	@GroupID INT,
	@IP VARCHAR(15) = ''	
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Called by sp Aff_Con_AdminIns

	Revisions:
		- VinhTrinh@20100507: insert closed field to table affiliate_user
		- 20100713@Peter : Remove Write Log on IBC DB
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP for Affiliate_YashBet [RedmineID: #198909]

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