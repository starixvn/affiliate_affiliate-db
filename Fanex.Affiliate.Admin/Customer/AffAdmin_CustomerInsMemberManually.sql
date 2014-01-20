ALTER PROCEDURE [dbo].[AffAdmin_CustomerInsMemberManually]	
	@AffUserName	VARCHAR(30),
	@Username		VARCHAR(30),	
	@DepositCustID	VARCHAR(50) = NULL,
	@FirstName		NVARCHAR(50)= NULL,
	@LastName		NVARCHAR(50)= NULL,
	@Currency		VARCHAR(6)	= NULL,	
	@Email			NVARCHAR(50)= NULL,	
	@IBCCustID		INT			= NULL,	
	@IBCUserName	VARCHAR(30)	= NULL,
	@AgentID		INT			= NULL,	
	@CreatedDate	DATETIME	= NULL,
	@RegisterDate	DATETIME	= NULL,
	@AffAffectedDate	DATETIME	= NULL,
	@Btag			VARCHAR(100),
	@ClickID		BIGINT		= 0,	
	@Phone			VARCHAR(25)	= NULL,
	@Address		NVARCHAR(255)=NULL,
	@IP				VARCHAR(22),	
	@Language		VARCHAR(5)= 'en-US',
	@AffID			INT OUTPUT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(100) = '' OUTPUT
AS
/*  
	Created: 20090724@Peter
	Task : Add new member existing in the system to Affiliate System
	DB: Affiliate_Licensee

	Revision:
	    -Peter@20131029 : - Add column Phone & Address
		                   - Recalculate TotalMembers in AffInfo https://redmine.nexcel.vn/issues/5280
		-Bobby@20131218: - Update check affInfo & member existing at https://redmine.nexcel.vn/issues/10583/

*/ 
BEGIN
	SET NOCOUNT ON;

	DECLARE @affMemberID INT
		, @affIsClosed BIT
		, @memberRemoved BIT
		, @currencyID INT
		, @memberCurrency INT
		, @isUpdated BIT;

	/*** affiliate's validation ***/
	SELECT TOP(1) @AffID=AffID
		, @affIsClosed = IsClosed
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE username=@AffUserName

	if(@AffID IS NULL OR @affIsClosed = 1)
	BEGIN
		SELECT @ErrCode = 44
			, @ErrMsg = 'Invalid affiliate user';
		RETURN;
	END

	SELECT TOP(1) @affMemberID = mi.AffID
		, @memberRemoved = ISNULL(mi.IsRemoved, 0)
		, @memberCurrency = ISNULL(mi.Currency, 0)
	FROM dbo.MemberInfo mi WITH (NOLOCK) 
	WHERE mi.UserName = @Username;

	IF (@affMemberID > 0 AND @memberRemoved = 0)
	BEGIN
		 SELECT @ErrCode=45
			, @ErrMsg = 'User has been existed in the system.';
		 RETURN;
	END
	
	--set currency
	IF (@affMemberID > 0 AND @memberRemoved = 1)
	BEGIN 
		SET @Currency = @memberCurrency;
	END

	/*** get currency info ***/
	SELECT @currencyID = ExchangeID 
	FROM [dbo].[CurrencyConverter] WITH(NOLOCK)
	WHERE [PartnerCurrency] = @Currency

	/*** update member is removed ***/
	IF (@affMemberID > 0 AND @memberRemoved = 1) 
	BEGIN
		--update Btag
		SELECT TOP(1) 
			@Btag = ISNULL(SValue, '0') + '_' + CAST(@AffID AS VARCHAR(10)) + '_0' 
		FROM dbo.[SystemSettings] WITH(NOLOCK)
			WHERE SName='LicenseeID'

		UPDATE [dbo].[MemberInfo]
		SET [AffID]			= @AffID      
		  ,[IsRemoved]		= 0
		  ,Btag				= @Btag
		  ,ClickID			= @ClickID    
		  ,AffAffectedDate	= @AffAffectedDate
		WHERE UserName = @Username
	
		DELETE FROM dbo.MemberRemoval 
		WHERE UserName = @Username
			AND AffID = @AffID

		SET @isUpdated = 1;

	END
	ELSE IF (@AffMemberID IS NULL)--add new member
	BEGIN
		INSERT INTO dbo.MemberInfo (	
			AffID,
			UserName,		
			IsRemoved,
			DepositCustID,
			FirstName,
			LastName,
			Currency,	
			Email,
			RegisteredDate,
			CreatedDate,
			IBCCustID,	
			IBCUserName,
			Recommend,
			Btag,
			ClickID,
			Phone,
			[Address],
			AffAffectedDate
		)
		VALUES( 
			@AffID,
			@UserName,
			0, 
			@DepositCustID,
			@FirstName,
			@LastName,
			@currencyID,
			@Email,
			@RegisterDate,
			@CreatedDate,		
			@IBCCustID,	
			@IBCUserName,
			@AgentID,
			@Btag,
			@ClickID,
			@Phone,
			@Address,
			GETDATE()
		);
		SET @isUpdated = 1;
	END
	--check update stats info and write log
	IF(@isUpdated = 1)
	BEGIN
		-- Update TotalMembers Value for AffInfo
		UPDATE dbo.AffInfo WITH (ROWLOCK,UPDLOCK)
		SET TotalMembers = ISNULL(TotalMembers, 0) + 1
		WHERE AffID=@AffID

		DECLARE @LogData nVARCHAR(4000), @SPName VARCHAR(100) 
		SELECT @SPName = OBJECT_NAME(@@ProcID)

		SELECT @LogData = 'Insert new member. UserName=' + dbo.Aff_ToString(@UserName)                 
						  + '.PlayerCustID=' + dbo.Aff_ToString(@DepositCustID)
						  + '.FirstName=' + dbo.Aff_ToString(@FirstName)
						  + '.LastName=' + dbo.Aff_ToString(@LastName)
						  + '.Currency=' + dbo.Aff_ToString(@Currency)                  
						  + '.Email=' + dbo.Aff_ToString(@Email)
						  + '.RegisteredDate=' + dbo.Aff_ToString(@RegisterDate)
						  + '.CreatedDate=' + dbo.Aff_ToString(@CreatedDate)
						  + '.IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
						  + '.IBCUserName=' + dbo.Aff_ToString(@IBCUserName)
						  + '.Recommend=' + dbo.Aff_ToString(@AgentID)
						  + '.Btag=' + dbo.Aff_ToString(@Btag)
						  + '.ClickID=' + dbo.Aff_ToString(@ClickID)
						  + '.Phone=' + dbo.Aff_ToString(@Phone)
						  + '.Address=' + dbo.Aff_ToString(@Address)

		EXEC [dbo].[Aff_WriteLog]
			@Creator=@AffID,	
			@AffID=@AffID,
			@Typename= 'Member',	
			@SPName=@SPName,
			@IP =@IP,
			@Details=@LogData
	END
END
go
GRANT EXECUTE ON [dbo].[Aff_CustomerInsMemberManually] TO [bodbadminNet]