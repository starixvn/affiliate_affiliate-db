/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Aff_WriteLog_UserLog_Login_Wrapper]
	@UserID			INT,
    @ServerID		INT,
    @LoginIP		VARCHAR(20) = '',
    @DomainName		NVARCHAR(253) = NULL,
    @ActionID		INT = 0,
    @Doing			VARCHAR(300),
    @BrowserName	NVARCHAR(255) = NULL,
    @Platform		NVARCHAR(255) = NULL,
    @CountryCode	VARCHAR(64) = NULL,
    @Duration		INT = NULL
AS

/*
	Created: 20190424@Percy
	DB: DBCUST.bodb_CustomerLog, DBLOG.bodb_CustomerLog
	Task: Athena Affiliates - Login log - SP Wrapper

	Revisions:
		- 20190424@Percy: Initialize SP [RedmineID: #103658]
 
	Param's Explanation:
		• @UserID: main account login.
		• @ServerID: serverID.
		• @DomainName: Domain user login.
		• @LoginIP: IP user login.
		• @BrowserName: Browser user using.
		• @Platform: Platform user login.
		• @CountryCode: CountryCode user login.
		• @Duration: Time process login.
*/

BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.Aff_WriteLog_UserLog_Login
			@UserID			= @UserID,
			@ServerID		= @ServerID,
			@LoginIP		= @LoginIP,
			@DomainName		= @DomainName,
			@ActionID		= @ActionID,
			@Doing			= @Doing,
			@BrowserName	= @BrowserName,
			@Platform		= @Platform,
			@CountryCode	= @CountryCode,
			@Duration		= @Duration
	END TRY
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.Aff_WriteLog_UserLog_Login
			@UserID			= @UserID,
			@ServerID		= @ServerID,
			@LoginIP		= @LoginIP,
			@DomainName		= @DomainName,
			@ActionID		= @ActionID,
			@Doing			= @Doing,
			@BrowserName	= @BrowserName,
			@Platform		= @Platform,
			@CountryCode	= @CountryCode,
			@Duration		= @Duration
	END CATCH
END
GO