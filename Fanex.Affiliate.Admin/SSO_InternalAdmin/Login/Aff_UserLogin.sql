/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbAdminNet,bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_licensee]
GO

ALTER PROCEDURE [dbo].[Aff_UserLogin]
	@UserName		VARCHAR(50),
	@UserPwd		VARCHAR(50)		= '',	
	@LoginIP		VARCHAR(20),
	@ServerID		INT				= 0 OUTPUT,	
	@LoginDomain	NVARCHAR(253)	= NULL,
	@BrowserName	NVARCHAR(255)	= NULL,
	@Platform		NVARCHAR(255)	= NULL,  
	@CountryCode	VARCHAR(64)		= NULL,  	
	@Langkey		VARCHAR(20)		= 'en-US',
	@UserID			INT				OUTPUT,
	@ErrCode		INT				= 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000)	= '' OUTPUT
AS

/*
	Created: 20151012@Victor
	Task: User Login into Affiliate Admin site
	DB: DBCUST.bodb_Licensee
  
	Revisions:
		- 20171002@Percy: Write more password into log [RedmineID: #83692]
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee & Apply SP log wrapper [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Begin		DATETIME
	DECLARE @Duration	INT

	SET @Begin = GETDATE()

	DECLARE @FirstName	NVARCHAR(50)
	DECLARE @LastName	NVARCHAR(50)
	DECLARE @UserRole	VARCHAR(50)
	DECLARE @Email		VARCHAR(50)
	DECLARE @Status		VARCHAR(30)
	DECLARE @LogData	NVARCHAR(600)

	SELECT @UserID = UserID, @UserRole = UserRole, @FirstName = FirstName, @LastName = LastName, @Email = Email, @Status = Status
	FROM dbo.Users WITH (NOLOCK)
	WHERE Username = @UserName
		AND (
			ISNULL(@UserPwd,'') = '' 
			OR (ISNULL(@UserPwd,'') <> '' AND UserPwd = @UserPwd)
		)
		AND IsInternal = 0

	IF (ISNULL(@UserID, 0) = 0)
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = CASE @Langkey WHEN 'en-US' THEN 'Wrong username or password.' ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](80001, @Langkey) END
		
		SET @LogData = 'Failed(User_Not_Found)'
	END
	ELSE IF (@Status <> 'Open')
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = CASE @Langkey WHEN 'en-US' THEN 'This user is not active.' ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](200022, @Langkey) END
		
		SET @LogData = 'Failed(User_Not_Active)'
	END
	ELSE
	BEGIN
		DECLARE @LicenseeID INT, @RowCnt INT, @EnableBA BIT, @IsAllowedMemberComm BIT
		
		IF @UserRole = 'Admin'
		BEGIN
			SET @LicenseeID = -1 -- Admin will choose Licensee later

			SELECT
				@UserID		AS UserID,
				@Username	AS Username,
				@UserRole	AS UserRole,
				@FirstName	AS FirstName,
				@LastName	AS LastName,
				@Email		AS Email,
				@Status		AS Status,
				@LicenseeID AS LicenseeID,
				0			AS IsInternal
			
			SET @LogData = 'Success'
		END
		ELSE IF @UserRole = 'Licensee'
		BEGIN
			SELECT @RowCnt = COUNT(*) FROM dbo.Aff_LicenseeUser WITH (NOLOCK) WHERE UserID = @UserID AND IsActive = 1

			IF (@RowCnt > 1)
			BEGIN
				SELECT @ErrCode = 103, @ErrMsg = CASE @Langkey WHEN 'en-US' THEN 'This user has too many licensees.' ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](200023, @Langkey) END
				
				SET @LogData = 'Failed(User_Too_Many_Licensees)'
			END
			ELSE
			BEGIN
				SELECT @LicenseeID = LicenseeID FROM dbo.Aff_LicenseeUser WITH (NOLOCK) WHERE UserID = @UserID AND IsActive = 1
			
				IF (@LicenseeID IS NULL)
				BEGIN
					SELECT @ErrCode = 104, @ErrMsg = CASE @Langkey WHEN 'en-us' THEN 'This user has no licensee.' ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](200024, @Langkey) END
					
					SET @LogData = 'Failed(User_Not_Found_Licensee)'   
				END
				ELSE
				BEGIN
					SELECT @EnableBA = EnableBA FROM dbo.LicenseeBAConfig WITH (NOLOCK) WHERE LicenseeID = @LicenseeID
					SELECT @IsAllowedMemberComm = IsAllowedMemberComm FROM dbo.Licensees WITH (NOLOCK) WHERE LicenseeID = @LicenseeID

					SELECT
						@UserID							AS UserID,
						@Username						AS Username,
						@UserRole						AS UserRole,
						@FirstName						AS FirstName,
						@LastName						AS LastName,
						@Email							AS Email,
						@Status							AS Status,
						@LicenseeID						AS LicenseeID,
						ISNULL(@EnableBA, 0)			AS EnableBA,
						ISNULL(@IsAllowedMemberComm, 0) AS IsAllowedMemberComm,
						0								AS IsInternal
					
					SET @LogData = 'Success'
				END	
			END
		END
	END

	SELECT @UserID	= ISNULL(@UserID, 0), @ServerID	= 200, @Duration = DATEDIFF(MILLISECOND, @Begin, GETDATE())
	SELECT @LogData = CASE WHEN @LogData = 'Success' AND @UserRole = 'Admin' THEN 'Admin: ' ELSE 'User: ' END + @UserName +  ' - ' + 'Password: ' + @UserPwd + ' - ' + @LogData

	EXEC CustDB.dbo.Aff_WriteLog_UserLog_Login_Wrapper
		@UserID			= @UserID,
		@ServerID		= @ServerID,
		@LoginIP		= @LoginIP,
		@DomainName		= @LoginDomain,
		@ActionID		= 5000,
		@Doing			= @LogData,
		@BrowserName	= @BrowserName,
		@Platform		= @Platform,
		@CountryCode	= @CountryCode,
		@Duration		= @Duration
END
GO