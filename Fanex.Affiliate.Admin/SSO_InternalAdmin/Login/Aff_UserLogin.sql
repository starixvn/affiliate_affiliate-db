ALTER PROCEDURE [dbo].[Aff_UserLogin]
	@UserName VARCHAR(50),
	@UserPwd VARCHAR(50) = '',	
	@LoginIP VARCHAR(20),
	@ServerID INT = 0 OUTPUT,	
	@LoginDomain NVARCHAR(253) = NULL,
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,  	
	@Langkey VARCHAR(20) = 'en-US',
	@UserID	INT OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
	
AS
/*
	Created: 20151012@Victor
	Task : User Login into Affiliate Admin site
	DB: DBLIC/bodb_Licensee
  
	Revisions:	
*/
SET NOCOUNT ON

DECLARE @Begin		DATETIME
DECLARE @END		DATETIME
DECLARE @Duration	INT

SET @Begin = GETDATE()

DECLARE @FirstName NVARCHAR(50)
DECLARE @LastName NVARCHAR(50)
DECLARE @UserRole VARCHAR(50)
DECLARE @Email VARCHAR(50)
DECLARE @Status VARCHAR(30)
DECLARE @LogData NVARCHAR(500)

SELECT 
	@UserID=UserID, @UserRole=UserRole, @FirstName=FirstName, @LastName= LastName, @Email= Email, @Status=Status
FROM 
	Users WITH (NOLOCK)
WHERE 
	Username = @UserName AND 
	--UserPwd = @UserPwd AND
	(ISNULL(@UserPwd,'') = '' OR (ISNULL(@UserPwd,'') <> '' AND UserPwd = @UserPwd)) AND
	IsInternal = 0

IF (ISNULL(@UserID, 0) = 0)
BEGIN
	SELECT @ErrMsg = CASE @Langkey WHEN 'en-US' THEN 'Wrong username or password.'  
					 ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](80001,@Langkey)
        END ,@ErrCode=101     
    SET @LogData = 'User: ' + @UserName +  ' - ' + 'Failed(User_Not_Found)'   
END
ELSE IF (@Status <> 'Open')
BEGIN
	SELECT @ErrMsg = CASE @Langkey WHEN 'en-US' THEN 'This user is not active.'  
								   ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](200022,@Langkey)
        END ,@ErrCode=102     
    SET @LogData = 'User: ' + @UserName + ' - ' + 'Failed(User_Not_Active)'   
END
ELSE
BEGIN
	DECLARE @LicenseeID INT
	DECLARE @RowCnt INT
	DECLARE @EnableBA BIT
	DECLARE @IsAllowedMemberComm BIT
	IF @UserRole = 'Admin'
	BEGIN
		SET @LicenseeID = -1 --admin will choose Licensee later
		SELECT @UserID AS UserID, @Username AS Username, @UserRole AS UserRole, @FirstName AS FirstName, @LastName LastName, @Email AS Email, @Status AS Status, @LicenseeID AS LicenseeID, 0 AS IsInternal
		SET @LogData = 'Admin: ' + @username +  ' - ' + 'Success'
	END
	ELSE IF @UserRole = 'Licensee'
	BEGIN
	
		SELECT @RowCnt=COUNT(*) FROM Aff_LicenseeUser WITH (NOLOCK)
		WHERE UserID = @UserID
			AND IsActive = 1

		IF (@RowCnt>1)
		BEGIN
			SELECT @ErrMsg = CASE @Langkey WHEN 'en-US' THEN 'This user has too many licensees.'  
										   ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](200023,@Langkey)
			END ,@ErrCode=103   
			SET @LogData = 'User: ' + @UserName +  ' - ' + 'Failed(User_Too_Many_Licensees)'   
		END
		ELSE
		BEGIN
			SELECT @LicenseeID = LicenseeID FROM Aff_LicenseeUser WITH (NOLOCK)
			WHERE UserID = @UserID
				AND IsActive = 1
			
			IF (@LicenseeID IS NULL)
			BEGIN
					SELECT @ErrMsg = CASE @Langkey WHEN 'en-us' THEN 'This user has no licensee.'  
													ELSE [bodb02].[dbo].[Lrf_f_Get_MsgNamebyMsgID](200024,@Langkey)
					END ,@ErrCode=104   
					SET @LogData = 'User: ' + @UserName + ' - ' + 'Failed(User_Not_Found_Licensee)'   
			END
			ELSE
			BEGIN
				SELECT @EnableBA = EnableBA FROM LicenseeBAConfig (NOLOCK) WHERE LicenseeID = @LicenseeID
				SELECT @IsAllowedMemberComm = IsAllowedMemberComm FROM Licensees (NOLOCK) WHERE LicenseeID = @LicenseeID

				SELECT @UserID AS UserID,@Username AS Username,@UserRole AS UserRole, @FirstName AS FirstName,@LastName LastName, @Email AS Email, @Status AS Status, @LicenseeID AS LicenseeID, ISNULL(@EnableBA,0) EnableBA, isnull(@IsAllowedMemberComm,0) IsAllowedMemberComm, 0 AS IsInternal
				SET @LogData = 'User: ' + @username +  ' - ' + 'Success'
			END	
		END
	END
END

SET @UserID = ISNULL(@UserID,0)
SET @ServerID = 200

SET @END = GETDATE()
SET @Duration = DATEDIFF(millisecond,@Begin,@END)

EXEC Aff_WriteLog_UserLog_Login
		 @UserID = @UserID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 2301,
		 @Doing = @LogData,
		 @BrowserName = @BrowserName,
		 @Platform = @Platform,
		 @CountryCode = @CountryCode,
		 @Duration = @Duration

GO
GRANT EXECUTE ON [dbo].[Aff_UserLogin] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_UserLogin] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_UserLogin] TO [vnteam] AS [dbo]