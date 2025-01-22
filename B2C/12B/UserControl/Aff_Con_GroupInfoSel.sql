/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Con_GroupInfoSel]
	@GroupID int=null
AS 
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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