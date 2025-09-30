ALTER FUNCTION [dbo].[Aff_Con_GetGroupItID]
(
)
RETURNS INT
AS
BEGIN
	Declare @GroupIT int
	Select @GroupIt = GroupID from AffGroupInfo nolock where GroupName = 'Aff_IT_Dept'

	RETURN @GroupIT
END