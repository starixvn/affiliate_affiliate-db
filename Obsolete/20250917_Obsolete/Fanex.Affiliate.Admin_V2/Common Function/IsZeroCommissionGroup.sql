ALTER FUNCTION [dbo].[IsZeroCommissionGroup] (
	@GroupID		INT
	,@MonthDate		DATETIME
	)
RETURNS BIT
AS
/*
   - 20120514@Peter : Check all the setting commission is Zero only             
   - 20140916@Bobby : Refactor code
*/
BEGIN
	DECLARE @NoCommGroupID INT

	SELECT @NoCommGroupID = ISNULL(cg.GroupID, 0)
	FROM dbo.CommGroup cg WITH (NOLOCK)
	WHERE cg.GroupName = 'NoCommission'

	IF (@GroupID = @NoCommGroupID -- Check is NoCommission group setting
			OR NOT EXISTS (
				SELECT TOP 1 1
				FROM dbo.GroupSetting gs WITH(NOLOCK)
				WHERE gs.GroupID = @GroupID
					AND gs.Commission <> 0
					AND DATEDIFF(M, CURRENT_TIMESTAMP, @MonthDate) = 0
				
				UNION
				SELECT TOP 1 1
				FROM dbo.GroupSettingHistory gh WITH (NOLOCK)
				WHERE gh.GroupID = @GroupID
					AND gh.Commission <> 0
					AND DATEDIFF(M, gh.MonthDate, @MonthDate) = 0
				)
			)
	BEGIN
		RETURN 1
	END
	RETURN 0
END
GO

	