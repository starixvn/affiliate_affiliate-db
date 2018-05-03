/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_DomainControlDel]
	@Id INT
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20121115@Johnny.Trinh
	Task: Add a new AffDomainControl
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:  
		- 20140708@Bobby : Apply IsDeleted info
*/

BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------
	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid = @UserID
		,@funcname = '[Domain]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 RETURN

	-----------------------------------------------
	DECLARE @AffDomainID INT
		,@12BetDomainID INT
		,@MarketID NVARCHAR(10)

	SELECT @AffDomainID = AffDomainID
		,@12BetDomainID = [12BetDomainID]
		,@MarketID = MarketId
	FROM [AffDomainControl]
	WHERE Id = @Id

	UPDATE d
	SET IsDeleted = 1
	FROM [AffDomainControl] d WITH (ROWLOCK, UPDLOCK)
	WHERE Id = @Id

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Delete AffDomainID:' + dbo.Aff_ToString(@AffDomainID) + ' 12BetDomainID:' + dbo.Aff_ToString(@12BetDomainID) + ' MarketID:' + dbo.Aff_ToString(@MarketID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'AffDomainControl' -- refer to table LogType
		,@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO