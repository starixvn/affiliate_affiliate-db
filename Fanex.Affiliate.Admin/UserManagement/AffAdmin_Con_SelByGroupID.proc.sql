ALTER Procedure [dbo].[AffAdmin_Con_SelByGroupID]
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
*/
SET NOCOUNT ON

Declare @GroupIT int
Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()

IF @Username is null SET @Username = '%'
IF @FirstChar is null SET @FirstChar = '%'

IF @Groupid is null
BEGIN
	SELECT gi.groupname,ac.groupid,ac.custid, ac.username, ac.firstname, ac.lastname,
		ac.closed as status,ac.createdate,ct.username as creator
	FROM AdminUser ac with (nolock) 
		INNER JOIN AffGroupInfo gi with(nolock) on ac.groupid=gi.groupid
		LEFT JOIN AdminUser ct with(nolock) on ac.creator=ct.custid
	WHERE ac.username like @Username 
			and ac.username like @FirstChar
			and (case when @IsIT = 1 then 1 
				when ac.GroupID = @GroupIt then 0
				else 1 end) = 1
	ORDER BY IsNull(ac.closed, 0), ac.username,ac.groupid
END
ELSE
BEGIN
	SELECT gi.groupname,ac.groupid,ac.custid, ac.username, ac.firstname, ac.lastname,
		ac.closed as status,ac.createdate,ct.username as creator
	FROM AdminUser ac with (nolock) 		
		INNER JOIN AffGroupInfo gi with(nolock) on ac.groupid=gi.groupid
		LEFT JOIN AdminUser ct with(nolock) on ac.creator=ct.custid
	WHERE ac.groupid=@groupid 
		and ac.username like @Username 
		and ac.username like @FirstChar 
		and (case when @IsIT = 1 then 1 
				when ac.GroupID = @GroupIt then 0
				else 1 end) = 1
	ORDER BY IsNull(ac.closed, 0), ac.username,ac.groupid
END






