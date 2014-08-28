ALTER PROCEDURE [dbo].[Aff_DomainControlUpd] 
	@ID INT
	,@AffDomainID INT
	,@12BetDomainID INT
	,@MarketID NVARCHAR(10)
	,@Status BIT = 1
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Update Domain control info
DB: DB052.Affiliate_12BET
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
	DECLARE @DeviceType TINYINT;
	
	SELECT @DeviceType = DeviceType
	FROM [12BetDomain] d WITH(NOLOCK) 
	WHERE d.[DomainID] = @12BetDomainID
	
	IF ( @DeviceType IS NULL 
		OR EXISTS (
			SELECT TOP 1 1
			FROM AffDomainControl ac WITH(NOLOCK)
			WHERE ac.ID <> @ID
				AND ac.AffDomainID 	= @AffDomainID
				AND ac.MarketID 	= @MarketID
				AND ac.DeviceType 	= @DeviceType
				AND ac.IsDeleted 	= 0
			)
		)
	BEGIN
		SELECT @ErrCode = 1001
			,@ErrMsg = 'Your domain setting is duplicate with other setting or invalid. Please check!'

		RETURN
	END

	BEGIN TRANSACTION

	UPDATE [AffDomainControl] WITH (ROWLOCK, UPDLOCK)
	SET [AffDomainID] = @AffDomainID
		,[12BetDomainID] = @12BetDomainID
		,[MarketID] = @MarketID
		,[ModifyDate] = current_timestamp
		,[Status] = @Status
		,[Creator] = @UserID
		,[DeviceType]= @DeviceType
	WHERE ID = @ID

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrMsg = N'Error occurs when update data.'
			,@ErrCode = 1002

		RETURN
	END

	COMMIT TRANSACTION

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Update AffDomainID:' + dbo.Aff_ToString(@AffDomainID) + ' 12BetDomainID:' + dbo.Aff_ToString(@12BetDomainID) + ' MarketID:' + dbo.Aff_ToString(@MarketID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'AffDomainControl'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_DomainControlUpd] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlUpd] TO [vnteam]
