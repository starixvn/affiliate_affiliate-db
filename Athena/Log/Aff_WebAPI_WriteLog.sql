/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_CustomerLog]
GO

ALTER PROCEDURE [dbo].[Aff_WebAPI_WriteLog]
	@UserID			INT,
	@LogContent		NVARCHAR(MAX)
AS

/*
	Created by Percy
	Date: 2017-11-30
	DB: DBLOG.bodb_CustomerLog
	Task: Add log for web API

	Revisions:
		- 20171130@Percy: Create new SP [RedmineID: #87322]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TrackingValue NVARCHAR(MAX)
	SELECT  @TrackingValue = N'<Aff_WebAPI_WriteLog Content="' +  @LogContent + '" />'

	EXEC dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @UserID,
		@ActionID = 5200,
		@TrackingValue = @TrackingValue
END
GO