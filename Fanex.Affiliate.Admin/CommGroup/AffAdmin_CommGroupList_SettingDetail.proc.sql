USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CommGroupList_SettingDetail] 
	@GroupIDList	VARCHAR(1000)
	,@Date			SMALLDATETIME = NULL
AS

/*
	Created: 20130909@Joseph
	Task: Get all group details
	DB: DBAFF
	Original:

	Revisions:
		- 20140820@Bobby: Apply SQL stylescope
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TblGroup TABLE (GroupID INT)

	INSERT INTO @TblGroup (GroupID)
	SELECT val FROM [dbo].[strSplit](@GroupIDList, ',')

	IF (@Date IS NULL OR DATEDIFF(MONTH, CURRENT_TIMESTAMP, @Date) >= 0)
	BEGIN
		SELECT g.GroupId
			,g.ProductID
			,s.ProductName
			,g.TierID
			,g.MinAmount
			,g.MaxAmount
			,g.MinQM
			,g.MaxQM
			,g.Commission
		FROM dbo.GroupSetting g WITH (NOLOCK)
			INNER JOIN dbo.Product s WITH (NOLOCK) ON s.ProductID = g.ProductID
		WHERE g.GroupID IN (SELECT GroupID FROM @TblGroup)
	END
	ELSE
	BEGIN
		SELECT g.GroupId
			,g.ProductID
			,s.ProductName
			,g.TierID
			,g.MinAmount
			,g.MaxAmount
			,g.MinQM
			,g.MaxQM
			,g.Commission
		FROM dbo.GroupSettingHistory g WITH (NOLOCK)
			INNER JOIN dbo.Product s WITH (NOLOCK) ON s.ProductID = g.ProductID
		WHERE g.GroupID IN (SELECT GroupID FROM @TblGroup)
			AND DATEDIFF(MONTH, g.MonthDate, @Date) = 0
	END
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupDetailSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupDetailSel] TO [vnteam]
GO