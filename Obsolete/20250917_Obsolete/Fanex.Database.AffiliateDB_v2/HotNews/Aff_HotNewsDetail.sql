Alter PROCEDURE [dbo].[Aff_HotNewsDetail]
	@MsgID int=null
AS
/*
Created: 20090310@TrangLe
Task : Select affiliate hot news by message id or latest messageid
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090317@DungTong: allow to get latest message id
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
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
		  ,n.[creator]
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,c.username as creatorname
	  FROM News n with (nolock)
			LEFT JOIN AdminUser c WITH (NOLOCK) ON c.custid=n.[creator]
	  WHERE 
			msgid=@MsgID



GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsDetail] TO [vnteam]
GO

