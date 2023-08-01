/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_HotNewsDetail]
	@MsgID INT = NULL
AS

/*
	Created: 20090310@TrangLe
	Task : Select affiliate hot news by message id or latest messageid
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Original:

	Revisions:
		- 20090317@DungTong: allow to get latest message id
		- 20090819@DungTong : Add new Spanish language
		- 20090920@DungTong : Add new Vietnamese and Indonesia Language
		- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106
		- 20130426@LongLuu: Add Japanese Language
		- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
		- 20220301@Malcolm: Add Hindi Language [RedmineId: #169142]
		- 20220401@Malcolm: Add Malay Language [RedmineId: #170789]
		- 20230801@Sally: Support 3 more Languages Cambodian, Bangladeshi and Vietnamese [RedmineId: #191310]

	Param's Explanation:
	• @MsgID : >0 message id selected
			   null: select the latest message

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