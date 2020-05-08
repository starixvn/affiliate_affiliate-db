/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_GroupInfoSel]
	@GroupID int=null
AS 
/*
DB: DBAFFN88-Affiliate_N88	
Revisions:

	-- DB03.bodb02-->DB052.Affiliate_12BET : Search department list
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
	-- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88 [RedmineID: #128775]
*/
SET NOCOUNT ON  
IF @groupid is null
BEGIN	
	declare @temp table(groupid int,groupname nvarchar(300),groupdesc nvarchar(300),nouser int,displayorder int)
	insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from AffGroupInfo  gi with(nolock)
			LEFT JOIN Affiliate_User ac with(nolock) on ac.groupid=gi.groupid
		where gi.groupname <> 'none'
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.groupname
	insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from AffGroupInfo  gi with(nolock)
			LEFT JOIN Affiliate_User ac with(nolock) on ac.groupid=gi.groupid
		where gi.groupname= 'none'
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		
	select * from @temp
	
END
ELSE
BEGIN
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
	from AffGroupInfo  gi with(nolock)
		LEFT JOIN Affiliate_User ac with(nolock) on gi.groupid=ac.groupid	
	WHERE gi.groupid=@groupid 
	GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
	ORDER BY gi.displayorder ,gi.groupname
END

GO 