/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_CheckIn]
	@CustID INT,
	@NetSessionID VARCHAR(30),
	@ServerID INT,
	@On_UserID INT OUTPUT,
	@IP VARCHAR(50) = '',
	@SubAccID INT = 0
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Original:

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
*/
BEGIN
	SET NOCOUNT ON

	UPDATE On_User WITH (ROWLOCK)
	SET IsKickedOut = 1
	   ,ServerId = 0
	WHERE CustId = @CustID
		AND SubAccId = @SubAccID

	INSERT INTO On_User (CustId, NetSessionId, On_SessionId, ServerId, IsKickedOut, IP, SubAccId, Reload_Time)
	VALUES (@CustID, @NetSessionID, 0, @ServerID, 0, @IP, @SubAccID, current_timestamp)

	SELECT @On_UserID = SCOPE_IDENTITY()
END
GO