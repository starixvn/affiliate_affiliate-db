ALTER FUNCTION [dbo].[AffAdmin_f_GroupInfo_Select]
(		
	@GroupID INT,
	@LicenseeID INT
)
RETURNS @tbData TABLE
(
	GroupID			INT,
	LicenseeID		INT,
	GroupName		NVARCHAR(50),
	GroupDesc		NVARCHAR(50),
	CreateDate		DATETIME,
	ModifyDate		DATETIME,
	DisplayOrder	INT,
	Creator			INT
) 
AS	
/*
Created:20151113@Victor
Task :  SSO from Internal Admin to Affiliate Admin
DB: DBAFF - Affiliate database

Revisions:
Param's Explanation:

*/

BEGIN
	SET @GroupID = ISNULL(@GroupID,'')
	SET @LicenseeID = ISNULL(@LicenseeID,'')

	INSERT INTO @tbData (GroupID, LicenseeID, GroupName, GroupDesc, CreateDate, ModifyDate, DisplayOrder, Creator)
	SELECT g.GroupID, g.LicenseeID, g.GroupName, g.GroupDesc, g.CreateDate, g.ModifyDate, g.DisplayOrder, g.Creator
	FROM DBLIC.bodb_licensee.dbo.Aff_GroupInfo g WITH (NOLOCK) 
	WHERE (@GroupID = '' OR g.GroupID = @GroupID)
		AND (@LicenseeID = '' OR g.LicenseeID = @LicenseeID)
	
	RETURN
END

GO
GRANT SELECT ON [dbo].[AffAdmin_f_GroupInfo_Select] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_f_GroupInfo_Select] TO [vnteam]


