/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffMediaChannel_Sel]
	@AffId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/

BEGIN
	SET NOCOUNT ON

	SELECT ChannelCode, ChannelName
	FROM dbo.AffMediaChannel WITH (NOLOCK)
	WHERE AffId = @AffId
END
GO