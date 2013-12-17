ALTER Procedure [dbo].[AffAdmin_Con_GroupInfoSel]
	@GroupID int=null,
	@IsIT bit = 0
AS 
/*
	DB03.bodb02-->DB052.Affiliate_MYM : Search department list
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON  

Declare @GroupIT int
Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()

IF @groupid is null
BEGIN	
	declare @temp table(groupid int,groupname nvarchar(300),groupdesc nvarchar(300),nouser int,displayorder int)
	insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from AffGroupInfo  gi with(nolock)
			LEFT JOIN AdminUser ac with(nolock) on ac.groupid=gi.groupid
		where system = 'Affiliate' 
				and gi.groupname <> 'none'
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.groupname
	insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
		from AffGroupInfo  gi with(nolock)
			LEFT JOIN AdminUser ac with(nolock) on ac.groupid=gi.groupid
		where system = 'Affiliate' 
				and gi.groupname= 'none'
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		
	select * 
	from @temp
	where (case when @IsIT = 1 then 1 
				when GroupID = @GroupIt then 0
				else 1 end) = 1
	
END
ELSE
BEGIN
	SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser , cast(gi.displayorder as int) as displayorder
	from AffGroupInfo  gi with(nolock)
		LEFT JOIN AdminUser ac with(nolock) on gi.groupid=ac.groupid	
	WHERE gi.groupid=@groupid 
		and (case when @IsIT = 1 then 1 
				when gi.GroupID = @GroupIt then 0
				else 1 end) = 1
	GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
	ORDER BY gi.displayorder ,gi.groupname
END



