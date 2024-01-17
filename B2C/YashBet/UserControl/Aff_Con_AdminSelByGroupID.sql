/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_AdminSelByGroupID]
	@Groupid INT = NULL,
	@Username VARCHAR(30) = '%',
	@FirstChar NVARCHAR(6) = '%'
AS 
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		-- DB03.BODB02 --> DB052.Affiliate_12BET
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP for Affiliate_YashBet [RedmineID: #198909]
	
	Param :		
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