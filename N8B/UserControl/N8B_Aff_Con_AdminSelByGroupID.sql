/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
Alter PROCEDURE [dbo].[Aff_Con_AdminSelByGroupID]
	@Groupid int=null,
	@Username varchar(30)='%',
	@FirstChar nvarchar(6)='%'
	


AS 
/*
	DB: DBAFFN8B-Affiliate_N8B	
	
	Revisions:
	-- DB03.BODB02 --> DB052.Affiliate_12BET
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
	
	Param :		
		--Search username: '%username%'
		--Search first char:
		--A: 'A%'
		--B: 'B%'
		--0-9: '[0-9]%'
*/
SET NOCOUNT ON

IF @Groupid is null
BEGIN
	SELECT gi.groupname,ac.groupid,ac.custid, ac.username, ac.firstname, ac.lastname,
		ac.closed,ac.createdate,ct.username as creator
	FROM Affiliate_User ac with (nolock) 
		INNER JOIN AffGroupInfo gi with(nolock) on ac.groupid=gi.groupid
		LEFT JOIN Affiliate_User ct with(nolock) on ac.creator=ct.custid
	WHERE ac.username like @Username and ac.username like @FirstChar
	ORDER BY IsNull(ac.closed, 0), ac.username,ac.groupid
END
ELSE
BEGIN
	SELECT gi.groupname,ac.groupid,ac.custid, ac.username, ac.firstname, ac.lastname,
		ac.closed,ac.createdate,ct.username as creator
	FROM Affiliate_User ac with (nolock) 		
		INNER JOIN AffGroupInfo gi with(nolock) on ac.groupid=gi.groupid
		LEFT JOIN Affiliate_User ct with(nolock) on ac.creator=ct.custid
	WHERE ac.groupid=@groupid and ac.username like @Username and ac.username like @FirstChar 
	ORDER BY IsNull(ac.closed, 0), ac.username,ac.groupid
END
GO