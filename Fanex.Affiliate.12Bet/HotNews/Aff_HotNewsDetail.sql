/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_HotNewsDetail]
	@MsgId INT = NULL
AS

/*
	Created: 20090310@TrangLe
	DB: DBAFF12BET-Affiliate_12BET
	Task: Select affiliate hot news by message id or latest messageid

	Revisions:
		- 20090317@DungTong: allow to get latest message id
		- 20090819@DungTong : Add new Spanish language
		- 20090920@DungTong : Add new Vietnamese and Indonesia Language
		- 20130218@LongLuu : Add Korean Language
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20220811@Malcolm: Add Cambodian Language [RedminID: #176429]
*/

BEGIN
	SET NOCOUNT ON

	IF ISNULL(@MsgId, -1) = -1
		SELECT @MsgId = MAX(MsgId) FROM dbo.News WITH (NOLOCK)

	SELECT
		message_en,message_cn,message_tw,message_es,message_th,message_vi,message_id,message_kr, message_km
		,n.creator,posteddate,msgid,important,u.UserName as creatorname
	FROM dbo.News n WITH (NOLOCK)
		LEFT JOIN dbo.Users u WITH (NOLOCK) ON n.Creator = u.CustId
	WHERE n.MsgId = @MsgId
END
GO