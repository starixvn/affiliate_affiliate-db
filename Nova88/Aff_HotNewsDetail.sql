/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_HotNewsDetail]
	@MsgID int=null
AS
/*
Created: 20090310@TrangLe
Task : Select affiliate hot news by message id or latest messageid
DB: DBAFFN8G-Affiliate_N8G
Original:

Revisions:
	- 20090317@DungTong: allow to get latest message id
	- 20090819@DungTong : Add new Spanish language
	- 20090920@DungTong : Add new Vietnamese and Indonesia Language
	- 20130218@LongLuu : Add Korean Language http://ccs.nexcel.vn/viewtopic.php?f=6&t=8460&start=0&st=0&sk=t&sd=a#p36106
	- 20130426@LongLuu: Add Japanese Language
	- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
Param's Explanation:
• @MsgID : >0 message id selected
		   null: select the latest message

*/
SET NOCOUNT ON
if(coalesce(@MsgID,-1)=-1) -- get the latest message
  begin
		select  @MsgID=max(msgid) 
		from News with (nolock)     
  end
	
	SELECT [message_en]
		  ,[message_cn]
		  ,[message_tw]
		  ,[message_es]
		  ,[message_th]
		  ,[message_vi]
		  ,[message_id]
		  ,[message_kr]
		  ,[message_jp]
		  ,n.creator
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,c.username as creatorname
	  FROM News n with (nolock)
			LEFT JOIN Affiliate_User c WITH (NOLOCK) ON c.custid=n.creator
	  WHERE 
			msgid=@MsgID
GO 