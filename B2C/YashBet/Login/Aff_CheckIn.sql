/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_CheckIn]
	@CustID INT,
	@NetSessionID VARCHAR(30),
	@ServerID INT,
	@On_UserID INT OUTPUT,
	@IP NVARCHAR(15) = '',
	@SubAccID INT = 0
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Original:

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
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