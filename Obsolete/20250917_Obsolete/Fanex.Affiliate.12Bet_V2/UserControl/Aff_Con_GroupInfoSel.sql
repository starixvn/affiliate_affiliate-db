ALTER PROCEDURE [dbo].[Aff_Con_GroupInfoSel]
	@GroupID int=null
AS 
/*
	DB03.bodb02-->DB052.Affiliate_12BET : Search department list
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
*/
SET NOCOUNT ON  
IF @groupid is null
BEGIN	
	declare @temp table(groupid int,groupname nvarchar(300),groupdesc nvarchar(300),nouser int,displayorder int)
	insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from AffGroupInfo  gi with(nolock)
			LEFT JOIN Affiliate_User ac with(nolock) on ac.groupid=gi.groupid
		where system = 'Affiliate' and gi.groupname <> 'none'
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.groupname
	insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from AffGroupInfo  gi with(nolock)
			LEFT JOIN Affiliate_User ac with(nolock) on ac.groupid=gi.groupid
		where system = 'Affiliate' and gi.groupname= 'none'
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
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupInfoSel] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoSel] TO [bodbAdminNet]