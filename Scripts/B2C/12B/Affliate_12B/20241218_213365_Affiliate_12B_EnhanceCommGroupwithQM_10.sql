/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20241218@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Enhance comm group with Qualified Member [RedmineID: #212201]
*/

USE Affiliate_12B
GO


-- Table:  CommGroup
UPDATE [dbo].[CommGroup] WITH (ROWLOCK, UPDLOCK)
SET [QMTurnover] = 100.0000
GO

-- Table:  CommGroupHistory

-- Table:  TierSetting
UPDATE [dbo].[TierSetting] WITH (ROWLOCK, UPDLOCK)
SET [MinQM] = MinAM, [MaxQM] = MaxAM
GO

-- Table:  TierSettingHistory

-- Initial data for CommGroupHistory, TierSettingHistory, DeductionSettingHistory, StraightSettingHistory
DECLARE @MonthDate SMALLDATETIME
SELECT @MonthDate = EOMONTH(GETDATE())

INSERT INTO [dbo].[CommGroupHistory] (GroupId, MonthDate, SubCommRate, QMTurnover)
SELECT c.GroupId, @MonthDate, c.SubCommRate, c.QMTurnover
FROM dbo.CommGroup c WITH (NOLOCK)
	LEFT JOIN dbo.CommGroupHistory cg WITH (NOLOCK) ON cg.GroupId = c.GroupId
												   AND cg.MonthDate = @MonthDate
WHERE cg.GroupId IS NULL
   OR cg.MonthDate IS NULL


INSERT INTO [dbo].[TierSettingHistory] (GroupId, GroupProductId, MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum)
SELECT t.GroupId, t.GroupProductId, @MonthDate, t.TierId, t.MinAmount, t.MaxAmount, t.MinQM, t.MaxQM, t.Commission, t.IsActivePlayerSum
FROM dbo.TierSetting t WITH (NOLOCK)
	LEFT JOIN dbo.TierSettingHistory ts WITH (NOLOCK) ON ts.GroupId = t.GroupId
												     AND ts.MonthDate = @MonthDate
												     AND ts.GroupProductId = t.GroupProductId
												     AND ts.TierId = t.TierId
WHERE ts.GroupId IS NULL
   OR ts.MonthDate IS NULL
   OR ts.GroupProductId IS NULL
   OR ts.TierId IS NULL


INSERT INTO [dbo].[DeductionSettingHistory] (GroupId, MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
SELECT d.GroupId, @MonthDate, d.GroupProductId, d.DeductionId, d.ProductId, d.DeductedPercentage, d.DeductedAmount, d.IsDeductedPercent
FROM dbo.DeductionSetting d WITH (NOLOCK)
	LEFT JOIN dbo.DeductionSettingHistory ds WITH (NOLOCK) ON ds.GroupId = d.GroupId
														  AND ds.MonthDate = @MonthDate
														  AND ds.DeductionId = d.DeductionId
														  AND ds.ProductId = d.ProductId
WHERE ds.GroupId IS NULL
   OR ds.MonthDate IS NULL
   OR ds.DeductionId IS NULL
   OR ds.ProductId IS NULL


INSERT INTO [dbo].[StraightSettingHistory] (GroupId, MonthDate, ProductId, GroupProductId, DeductedPercentage, Commission)
SELECT s.GroupId, @MonthDate, s.ProductId, s.GroupProductId, s.DeductedPercentage, s.Commission
FROM dbo.StraightSetting s WITH (NOLOCK)
	LEFT JOIN dbo.StraightSettingHistory st WITH (NOLOCK) ON st.GroupId = s.GroupId
														 AND st.MonthDate = @MonthDate
														 AND st.ProductId = s.ProductId
WHERE st.GroupId IS NULL
   OR st.MonthDate IS NULL
   OR st.ProductId IS NULL
GO