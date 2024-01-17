/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Logout]  
	@On_UserID INT,  
	@ServerID INT = NULL,  
	@UserName VARCHAR(30) = NULL  
AS  
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Original:

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/
	SET NOCOUNT ON

	--Write log to record user logout  
	DECLARE @CustID INT
		   ,@Creator INT
		   ,@LoginIP VARCHAR(20)
		   ,@TypeName VARCHAR(20)
		   ,@Role VARCHAR(20)
		   ,@SubAccID INT

	SELECT @CustID = CustId
	   ,@ServerID = COALESCE(@ServerID, ServerId, '')
	   ,@LoginIP = IP
	   ,@SubAccID = SubAccId
	FROM On_User WITH (NOLOCK)
	WHERE On_UserId = @On_UserID

	SELECT @ServerID = NULL

	SELECT @TypeName =	CASE WHEN @SubAccID = 6 THEN 'LogoutAdmin' ELSE 'LogoutAffiliate' END


	DELETE FROM On_User
	WHERE On_UserId = @On_UserID

	--Write log
	DECLARE @SPName VARCHAR(50)
		   ,@LogData NVARCHAR(200)

	SELECT @SPName = OBJECT_NAME(@@procid)

	SELECT
		@LogData =
		CASE
			WHEN @SubAccID = 6 THEN 'Admin'
			ELSE 'Affiliate'
		END +
		CASE
			WHEN ISNULL(@UserName, '') = '' THEN CAST(ISNULL(@CustID, '') AS VARCHAR(30))
			ELSE ISNULL(@Username, '')
		END + ' IP:' + ISNULL(@LoginIP, '') + ' Logout ServerID:' + CAST(ISNULL(@ServerID, '') AS NVARCHAR(20))


	SELECT
		@Creator =
		CASE
			WHEN @SubAccID < 0 THEN ABS(@SubAccID)
			ELSE @CustID
		END
GO