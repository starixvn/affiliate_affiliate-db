ALTER FUNCTION [dbo].[AffAdmin_f_GroupPolicy_Select]
(		
	@GroupID INT,
	@FunctionID INT
)
RETURNS @tbData TABLE
(
	GroupID			INT,
	FunctionID		INT,
	Policy			TINYINT,
	CreateDate		DATETIME,
	ModifyDate		DATETIME,
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
	SET @FunctionID = ISNULL(@FunctionID,'')

	INSERT INTO @tbData (GroupID, FunctionID, Policy, CreateDate, ModifyDate, Creator)
	SELECT g.GroupID, g.FunctionID, g.Policy, g.CreateDate, g.ModifyDate, g.Creator
	FROM DBLIC.bodb_licensee.dbo.Aff_GroupPolicy g WITH (NOLOCK) 
	WHERE (@GroupID = '' OR g.GroupID = @GroupID)
		AND (@FunctionID = '' OR g.FunctionID = @FunctionID)
	
	RETURN
END

GO
GRANT SELECT ON [dbo].[AffAdmin_f_GroupPolicy_Select] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_f_GroupPolicy_Select] TO [vnteam]


