/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbLicenseeNet" isFunction="0" isNested="1"></info>*/
USE [bodb_CustomerLog]
GO

ALTER PROCEDURE [dbo].[Aff_WriteLog_UserLog_Login]
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
	Task: Athena Affiliates - Login log

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
	
	INSERT INTO dbo.UserLog_Login_Aff (UserID,ServerID,IP,LogDate,ActionID,Doing,DomainName,BrowserName,Platform,CountryCode,Duration)
		VALUES (@UserID,@ServerID,@LoginIP,GETDATE(),@ActionID,@Doing,@DomainName,@BrowserName,@Platform,@CountryCode,@Duration)
END
GO