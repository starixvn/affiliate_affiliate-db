CREATE PROCEDURE [dbo].[Aff_CheckIn]
	@CustID int,
	@NetSessionID varchar(30),
	@ServerID int,
	@On_UserID int OUTPUT,
	@IP nvarchar(15) = '',
	@SubAccID int = 0
AS

/*
	Task: CheckIN
	DB: DB052.Affiliate_12Bet
	Original SP:LoginDownline_OnUser
	
	Revisions:
		- 20100812@Jamie:Grant permision for Thai site 
	
	Param's Explanation: 
	@Thien: to allow internal admin login without interfere with real agent
			--	pass @SubAccID = - CustID of Admin
	
	Note : @SubSystem to indicate which of admin site connected from
	1 : ASP admin
	2 : VN.NET RBS
	3 : VN.NET Account Site
	4 : TW.NET Admin
	5 : TW.NET Admin call to ASP Admin
	6 : Affiliate Admin Site


*/

--Use kick-out method, so comment the below lines
/*
declare @ErrMsg varchar(100)
if exists (select 1 from on_user with (nolock) where custid = @custid and subaccid=@subaccid and serverid<>0 group by custid having count(1)>=1 )
BEGIN
	Select @ErrMsg = 'Sorry, system does not allow multiple login.'
	RaisError (@ErrMsg, 16, 1)
	return
END
*/

--if @@servername <> '5WRHH1S'--Vinh: not kickout at local server for testing
	update on_user with (ROWLOCK) set IsKickedout=1, ServerID=0 where CustID = @CustID and SubAccID = @SubAccID

	
insert into on_user
	(custid, NetSessionID, on_sessionid, ServerID, IsKickedout, IP, SubAccID,reload_time)
values
	(@custid, @NetSessionid,0, @ServerID, 0, @IP, @SubAccID,current_timestamp)

Select @On_UserID = SCOPE_IDENTITY()

GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckIn] TO [VNTeam] 