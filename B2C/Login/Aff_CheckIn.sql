/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_CheckIn]
	@CustID int,
	@NetSessionID varchar(30),
	@ServerID int,
	@On_UserID int OUTPUT,
	@IP nvarchar(15) = '',
	@SubAccID int = 0
AS
/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Original:

	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
*/

SET NOCOUNT ON

update on_user with (ROWLOCK) set IsKickedout=1, ServerID=0 where CustID = @CustID and SubAccID = @SubAccID
	
insert into on_user
	(custid, NetSessionID, on_sessionid, ServerID, IsKickedout, IP, SubAccID,reload_time)
values
	(@custid, @NetSessionid,0, @ServerID, 0, @IP, @SubAccID,current_timestamp)

Select @On_UserID = SCOPE_IDENTITY()
GO