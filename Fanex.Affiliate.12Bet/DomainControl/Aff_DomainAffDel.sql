ALTER PROCEDURE [dbo].[Aff_DomainAffDel] 
	@DomainID INT OUTPUT
	,@DomainName NVARCHAR(50)
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Del a AffDomain
DB: DB052.Affiliate_12BET

Revisions:  
	- 20140708@Bobby : Apply IsDeleted info
*/
BEGIN
	SET NOCOUNT ON

	--Check permission-----------------------------
	EXEC [dbo].[Aff_Con_CheckPermission] @custid = @UserID
		,@funcname = '[Domain]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode <> 0 RETURN

	-----------------------------------------------
	IF EXISTS (
			SELECT TOP 1 1
			FROM AffDomainControl WITH(NOLOCK)
			WHERE [AffDomainID] = @DomainID
				AND IsDeleted = 0
			)
	BEGIN
		SELECT @ErrCode = 1001
			,@ErrMsg = 'This Affiliate domain has been used!'

		RETURN
	END

	UPDATE d
	SET IsDeleted = 1
	FROM dbo.[AffDomain] d WITH (ROWLOCK, UPDLOCK)
	WHERE DomainID = @DomainID

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Delete DomainID:' + dbo.Aff_ToString(@DomainID) + ' DomainName:' + dbo.Aff_ToString(@DomainName)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'AffDomain'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_DomainAffDel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffDel] TO [vnteam]
GO


