/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [bodb_Licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_Con_SelByGroupID]
	@LicenseeID INT,
	@Groupid	INT=null,
	@Username	VARCHAR(30)='%',
	@FirstChar	NVARCHAR(6)='%',
	@IsIT		BIT = 0
AS

/*
	DB: DBCUST.bodb_Licensee

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @GroupIT INT
	SELECT  @GroupIT = GroupID FROM dbo.AffAdmin_f_GetITGroupID(@LicenseeID)

	IF @Username IS NULL SET @Username = '%'
	IF @FirstChar IS NULL SET @FirstChar = '%'

	SELECT userid, username, firstname, lastname, groupid, [status], createdate
	INTO #AdminUser
	FROM dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID)

	IF @Groupid is null
	BEGIN
		SELECT gi.groupname,ac.groupid, CASE WHEN ac.GroupId = @GroupIT THEN 1 ELSE 0 END AS IsIT, 
			ac.userid AS custid, ac.username, ac.firstname, ac.lastname,
			ac.[Status],ac.createdate,ct.username as creator
		FROM #AdminUser ac 
			INNER JOIN dbo.AffAdmin_f_GroupInfo_Select('',@LicenseeID) gi on ac.groupid=gi.groupid
			LEFT JOIN #AdminUser ct on ac.creator=ct.userid
		WHERE ac.username like @Username 
				and ac.username like @FirstChar
				and (case when @IsIT = 1 then 1 
					when ac.GroupID = @GroupIt then 0
					else 1 end) = 1
		ORDER BY IsNull(ac.[Status], 0), ac.username,ac.groupid
	END
	ELSE
	BEGIN
		SELECT gi.groupname,ac.groupid, CASE WHEN ac.GroupId = @GroupIT THEN 1 ELSE 0 END AS IsIT, 
			ac.userid as custid, ac.username, ac.firstname, ac.lastname,
			ac.[Status],ac.createdate,ct.username as creator
		FROM #AdminUser ac with (nolock) 		
			INNER JOIN dbo.AffAdmin_f_GroupInfo_Select('',@LicenseeID) gi on ac.groupid=gi.groupid
			LEFT JOIN #AdminUser ct on ac.creator=ct.userid
		WHERE ac.groupid=@groupid 
			and ac.username like @Username 
			and ac.username like @FirstChar 
			and (case when @IsIT = 1 then 1 
					when ac.GroupID = @GroupIt then 0
					else 1 end) = 1
		ORDER BY IsNull(ac.[Status], 0), ac.username,ac.groupid
	END

	DROP TABLE #AdminUser
END
GO