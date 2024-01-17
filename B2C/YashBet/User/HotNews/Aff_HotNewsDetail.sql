/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_HotNewsDetail]
	@MsgID INT = NULL
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task : Select affiliate hot news by message id or latest MessageId

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

	Param's Explanation:
		- @MsgID: 
			+ >0 message id selected
			+ null: select the latest message

*/

BEGIN
	SET NOCOUNT ON

	IF(COALESCE(@MsgID, -1) = -1) -- get the latest message
	BEGIN
		SELECT @MsgID = MAX(msgid) 
		FROM dbo.News WITH (NOLOCK)     
	END
	
	SELECT [message_en]
		,[message_cn]
		,[message_tw]
		,[message_es]
		,[message_th]
		,[message_vi]
		,[message_id]
		,[message_kr]
		,[message_jp]
		,[message_hi]
		,[message_ms]
		,[Message_Kh]
		,[Message_Bn]
		,n.creator
		,[posteddate]
		,[msgid]
		,[important]
		,c.username AS creatorname
	FROM dbo.News n WITH (NOLOCK)
		LEFT JOIN Affiliate_User c WITH (NOLOCK) ON c.CustId = n.Creator
	WHERE MsgId = @MsgID

END
GO