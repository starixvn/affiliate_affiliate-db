ALTER PROCEDURE [dbo].[Aff_DomainControlIns] 
	@AffDomainID INT
	,@12BetDomainID INT
	,@MarketID NVARCHAR(10)
	,@Creator INT
	,@Status BIT = 1
	,@UserID INT
	,@IP NVARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Add a new AffDomainControl
DB: DB052.Affiliate_12BET
	Revisions:
	- 20140707@Bobby: Include DeviceType info
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
	
	IF (@DeviceType IS NULL 
		OR EXISTS (
			SELECT TOP 1 1
			FROM AffDomainControl ac WITH(NOLOCK)
			WHERE ac.AffDomainID 	= @AffDomainID
				AND ac.MarketID 	= @MarketID
				AND ac.DeviceType 	= @DeviceType
				AND ac.IsDeleted 	= 0
				
			)
		)
	BEGIN
		SELECT @ErrCode = 1001
			,@ErrMsg = 'This domain setting has been existed or invalid!'

		RETURN
	END

	DECLARE @CreatedDate DATETIME

	SELECT @CreatedDate = Current_Timestamp

	BEGIN TRANSACTION

	INSERT INTO [AffDomainControl] (
		[AffDomainID]
		,[12BetDomainID]
		,[MarketID]
		,[CreateDate]
		,[ModifyDate]
		,[Creator]
		,[Status]
		,[DeviceType]
		)
	VALUES (
		@AffDomainID
		,@12BetDomainID
		,@MarketID
		,@CreatedDate
		,@CreatedDate
		,@Creator
		,@Status
		,@DeviceType
		)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrMsg = N'Error occurs.Insert data unsuccessfully.'
			,@ErrCode = 1002

		RETURN
	END

	COMMIT TRANSACTION

	--Write log
	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Create AffDomainID:' + dbo.Aff_ToString(@AffDomainID) + ' 12BetDomainID:' + dbo.Aff_ToString(@12BetDomainID) + ' MarketID:' + dbo.Aff_ToString(@MarketID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@Typename = 'AffDomainControl'
		,-- refer to table LogType
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
GO

GRANT EXECUTE ON [dbo].[Aff_DomainControlIns] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlIns] TO [vnteam]
