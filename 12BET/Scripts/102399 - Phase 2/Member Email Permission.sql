USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new permission: member mail
*/

DECLARE @FuncId INT, @CreatedDate DATETIME, @Creator INT
SELECT  @CreatedDate = GETDATE(), @Creator = 862400

INSERT INTO dbo.AffFunctionInfo (FuncName,FuncNote,FuncDesc,FuncRender,CreateDate,ModifyDate,DisplayOrder,Creator,Filenames,System)
VALUES (N'[MemberEmail]', '', N'Member''s Email', 3, @CreatedDate, @CreatedDate, 1, @Creator, '', 'AFFILIATE')

SELECT @FuncId = SCOPE_IDENTITY()

UPDATE dbo.AffFunctionInfo WITH (ROWLOCK, UPDLOCK)
SET ParentID = @FuncId
WHERE FuncId = @FuncId

INSERT INTO dbo.AffGroupPolicy (GroupID,FuncID,Policy,CreateDate,ModifyDate,Creator)
SELECT GroupId, @FuncId, 0, @CreatedDate, @CreatedDate, @Creator
FROM dbo.AffGroupInfo WITH (NOLOCK)

INSERT INTO dbo.AffMemberPolicy (CustID,FuncID,Policy,CreateDate,ModifyDate,Creator)
SELECT CustID, @FuncId, 0, @CreatedDate, @CreatedDate, @Creator
FROM dbo.Affiliate_User WITH (NOLOCK)