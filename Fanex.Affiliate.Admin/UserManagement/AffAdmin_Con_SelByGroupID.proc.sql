ALTER Procedure [dbo].[AffAdmin_Con_SelByGroupID]
	@LicenseeID INT,
	@Groupid int=null,
	@Username varchar(30)='%',
	@FirstChar nvarchar(6)='%',
	@IsIT bit = 0
--Search username: '%username%'
--Search first char:
--A: 'A%'
--B: 'B%'
--0-9: '[0-9]%'

AS 
/*
	DB03.BODB02 --> DB052.Affiliate_MYM
	-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
	-- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
*/
SET NOCOUNT ON

Declare @GroupIT int
Select @GroupIt = [dbo].AffAdmin_f_GetITGroupID(@LicenseeID)

IF @Username is null SET @Username = '%'
IF @FirstChar is null SET @FirstChar = '%'

SELECT * INTO #AdminUser FROM dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID)

IF @Groupid is null
BEGIN
	SELECT gi.groupname,ac.groupid,ac.userid AS custid, ac.username, ac.firstname, ac.lastname,
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
	SELECT gi.groupname,ac.groupid,ac.userid as custid, ac.username, ac.firstname, ac.lastname,
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






