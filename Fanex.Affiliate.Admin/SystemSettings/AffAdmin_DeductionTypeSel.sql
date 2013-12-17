-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_DeductionTypeSel]
AS

/*
Created: 20130909@Joseph
Task : Get all deduction types (paging)
DB: DB052.
Original:

Revisions:
*/
SET NOCOUNT ON
 
 Select DTypeID,ProductID,DTypeName,DTypeDesc,DeductedPercentage 
	from DeductionType (nolock)

GO
GRANT EXECUTE ON [dbo].[AffAdmin_DeductionTypeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_DeductionTypeSel] TO [vnteam]