/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_AdminSelByGroupID]
	@Groupid INT = NULL,
	@Username VARCHAR(30) = '%',
	@FirstChar NVARCHAR(6) = '%'
AS 
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
	
	Parameter's Explanation:	
		--Search username: '%username%'
		--Search first char:
		--A: 'A%'
		--B: 'B%'
		--0-9: '[0-9]%'
*/
BEGIn
	SET NOCOUNT ON

	IF @Groupid IS NULL
	BEGIN
		SELECT
			gi.GroupName
		   ,ac.GroupId
		   ,ac.CustId
		   ,ac.UserName
		   ,ac.FirstName
		   ,ac.LastName
		   ,ac.Closed
		   ,ac.CreateDate
		   ,ct.UserName AS creator
		FROM Affiliate_User ac WITH (NOLOCK)
			INNER JOIN AffGroupInfo gi WITH (NOLOCK) ON ac.GroupId = gi.GroupId
			LEFT JOIN Affiliate_User ct WITH (NOLOCK) ON ac.creator = ct.CustId
		WHERE ac.UserName LIKE @Username
			AND ac.UserName LIKE @FirstChar
		ORDER BY ISNULL(ac.Closed, 0), ac.UserName, ac.GroupId
	END
	ELSE
	BEGIN
		SELECT
			gi.GroupName
		   ,ac.GroupId
		   ,ac.CustId
		   ,ac.UserName
		   ,ac.FirstName
		   ,ac.LastName
		   ,ac.Closed
		   ,ac.CreateDate
		   ,ct.UserName AS creator
		FROM Affiliate_User ac WITH (NOLOCK)
			INNER JOIN AffGroupInfo gi WITH (NOLOCK) ON ac.GroupId = gi.GroupId
			LEFT JOIN Affiliate_User ct WITH (NOLOCK) ON ac.creator = ct.CustId
		WHERE ac.GroupId = @groupid
			AND ac.UserName LIKE @Username
			AND ac.UserName LIKE @FirstChar
		ORDER BY ISNULL(ac.Closed, 0), ac.UserName, ac.GroupId
	END
END
GO