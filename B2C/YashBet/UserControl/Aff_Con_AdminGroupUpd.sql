/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE  [dbo].[Aff_Con_AdminGroupUpd]
	@CustID INT,
	@UserID INT,
	@GroupID INT,
	@IP VARCHAR(15) = '',
	@Language VARCHAR(2)= 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		-- 20121220@Dan: Change linked server from DB052.Affiliate_12BET-->DBAFF12BET.Affiliate_12BET
		- 20240115@Sally: Initialize SP for Affiliate_YashBet [RedmineID: #198909]	
*/
BEGIN
	SET NOCOUNT ON
	IF EXISTS (
		SELECT 1
		FROM AffGroupInfo WITH (NOLOCK)
		WHERE GroupId = @GroupID
	)
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM Affiliate_User ac WITH (NOLOCK)
			WHERE CustId = @CustID
			AND GroupId <> @GroupID
		)
		BEGIN

			UPDATE Affiliate_User WITH (ROWLOCK, UPDLOCK)
			SET GroupId = @GroupID
			WHERE CustId = @CustID

			DECLARE @SPName VARCHAR(50)
					,@LogData NVARCHAR(200)

			SELECT @SPName = OBJECT_NAME(@@procid)
			SELECT @LogData = 'Update Group for Admin custid:' + dbo.Aff_ToString(@CustID) + ' GroupID:' + dbo.Aff_ToString(@GroupID)

		END
	END
	ELSE
	BEGIN
		SELECT
			@ErrMsg =
			CASE @Language
				WHEN 'E' THEN N'This groupid ' + CONVERT(VARCHAR(20), @GroupID) + ' is invalid.'
				WHEN 'CS' THEN N'This groupid ' + CONVERT(VARCHAR(20), @GroupID) + ' is invalid.'
				WHEN 'J' THEN N'This groupid ' + CONVERT(VARCHAR(20), @GroupID) + ' is invalid.'
				ELSE N'This groupid ' + CONVERT(VARCHAR(20), @GroupID) + ' is invalid.'
			END
			,@ErrCode = 103
		RETURN
	END
END
GO