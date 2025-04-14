/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_HotNewsDetail]
	@MsgID INT = NULL
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task : Select affiliate hot news by message id or latest MessageId

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250317@Lewis: Add Korean [RedmineID: #219810]

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
	
	SELECT [message_en] --eng
		,[message_cn] --chinese simplified
		,[message_th] --thai
		,[message_vi] --vietnam
		,[message_id] --indo
		,[message_kr] --korean
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