/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Con_GroupInfoSel]
	@GroupID int=null
AS 
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		-- DB03.bodb02-->DB052.Affiliate_12BET : Search department list
		-- 20101214@Peter : Move this SP to DB DB052.Affiliate_12BET
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/
BEGIN
	SET NOCOUNT ON
	IF @GroupID IS NULL
	BEGIN
		DECLARE @temp TABLE (
			groupid INT
		   ,groupname NVARCHAR(300)
		   ,groupdesc NVARCHAR(300)
		   ,nouser INT
		   ,displayorder INT
		)
		INSERT INTO @temp (groupid, groupname, groupdesc, nouser, displayorder)
		SELECT
			gi.groupid
			,gi.groupname
			,gi.groupdesc
			,COUNT(ac.CustId) AS nouser
			,gi.displayorder
		FROM AffGroupInfo gi WITH (NOLOCK)
		LEFT JOIN Affiliate_User ac WITH (NOLOCK)
			ON ac.groupid = gi.groupid
		WHERE gi.groupname <> 'none'
		GROUP BY gi.groupid
				,gi.groupname
				,gi.groupdesc
				,gi.displayorder
		ORDER BY gi.groupname

		INSERT INTO @temp (groupid, groupname, groupdesc, nouser, displayorder)
		SELECT
			gi.groupid
			,gi.groupname
			,gi.groupdesc
			,COUNT(ac.CustId) AS nouser
			,gi.displayorder
		FROM AffGroupInfo gi WITH (NOLOCK)
			LEFT JOIN Affiliate_User ac WITH (NOLOCK) ON ac.groupid = gi.groupid
		WHERE gi.groupname = 'none'
		GROUP BY gi.groupid
				,gi.groupname
				,gi.groupdesc
				,gi.displayorder

		SELECT * FROM @temp

	END
	ELSE
	BEGIN
		SELECT
			gi.groupid
		   ,gi.groupname
		   ,gi.groupdesc
		   ,COUNT(ac.CustId) AS nouser
		   ,gi.displayorder
		FROM AffGroupInfo gi WITH (NOLOCK)
			LEFT JOIN Affiliate_User ac WITH (NOLOCK) ON gi.groupid = ac.groupid
		WHERE gi.groupid = @GroupID
		GROUP BY gi.groupid
				,gi.groupname
				,gi.groupdesc
				,gi.displayorder
		ORDER BY gi.displayorder, gi.groupname
	END
END
GO