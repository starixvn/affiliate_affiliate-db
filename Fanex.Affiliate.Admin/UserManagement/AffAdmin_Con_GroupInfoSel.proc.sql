/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_Con_GroupInfoSel]
	@LicenseeID INT,
	@GroupID int=null,
	@IsIT bit = 0
AS

/*
	DBCUST.bodb_Licensee
	
	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151116@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @GroupIT INT
	SELECT  @GroupIt = [dbo].[AffAdmin_f_GetITGroupID](@LicenseeID)

	IF @groupid IS NULL
	BEGIN	
		declare @temp table(groupid int,groupname nvarchar(300),groupdesc nvarchar(300),nouser int,displayorder int)

		insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.UserID) as nouser ,gi.displayorder
			from dbo.AffAdmin_f_GroupInfo_Select('',@LicenseeID)  gi 
				LEFT JOIN dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) ac on ac.groupid=gi.groupid
			where gi.groupname NOT LIKE 'None'
			GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
			ORDER BY gi.groupname

		insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.UserID) as nouser ,gi.displayorder
			from dbo.AffAdmin_f_GroupInfo_Select('',@LicenseeID)  gi
				LEFT JOIN dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) ac on ac.groupid=gi.groupid
			WHERE gi.groupname LIKE 'None'
			GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		
		select groupid ,groupname,groupdesc,nouser,displayorder
		from @temp
		where (case when @IsIT = 1 then 1 
					when GroupID = @GroupIt then 0
					else 1 end) = 1
	
	END
	ELSE
	BEGIN
		SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.UserID) as nouser , cast(gi.displayorder as int) as displayorder
		from AffAdmin_f_GroupInfo_Select('',@LicenseeID)  gi
			LEFT JOIN dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) ac on gi.groupid=ac.groupid	
		WHERE gi.groupid=@groupid 
			and (case when @IsIT = 1 then 1 
					when gi.GroupID = @GroupIt then 0
					else 1 end) = 1
		GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
		ORDER BY gi.displayorder ,gi.groupname
	END
END
GO