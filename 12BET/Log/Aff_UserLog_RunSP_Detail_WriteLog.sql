/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbAdminNet,bodbDownlineNet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_UserLog_RunSP_Detail_WriteLog]
	@SPName		VARCHAR(200),
	@UserId		INT,
	@AffId		INT = 0,
	@OldData	NVARCHAR(MAX) = NULL,
	@NewData	NVARCHAR(MAX) = NULL,
	@IP			VARCHAR(50) = '',
	@Language	VARCHAR(20) = 'en-US'
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: UserLog - Log data
	
	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20200731@Percy: Set default param value [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	IF @SPName LIKE '%_xtest'
		SELECT @SPName = LEFT(@SPName, LEN(@SPName) - 6)
	ELSE IF @SPName LIKE '%_xpre'
			OR @SPName LIKE '%_UAT1'
			OR @SPName LIKE '%_UAT2'
			OR @SPName LIKE '%_UAT3'
			OR @SPName LIKE '%_UAT4'
		SELECT @SPName = LEFT(@SPName, LEN(@SPName) - 5)

	DECLARE @LogTypeId INT, @LogActionId INT

	SELECT @LogTypeId = lt.TypeID, @LogActionId = la.ActionId
	FROM dbo.LogAction la WITH (NOLOCK)
		LEFT JOIN dbo.LogType lt WITH (NOLOCK) ON lt.TypeID = la.ActionTypeId
	WHERE la.SPName = @SPName

	SELECT @LogTypeId = ISNULL(@LogTypeId, 0), @LogActionId = ISNULL(@LogActionId, 0)

	INSERT INTO dbo.UserLog_RunSP_Detail
	(
		LogTypeId,
		LogActionId,
		SPName,
		UserId,
		AffId,
		LogDate,
		OldData,
		NewData,
		IP,
		Language
	)
	VALUES
	(
		@LogTypeId,
		@LogActionId,
		@SPName,
		@UserId,
		@AffId,
		GETDATE(),
		@OldData,
		@NewData,
		@IP,
		@Language
	)
END
GO