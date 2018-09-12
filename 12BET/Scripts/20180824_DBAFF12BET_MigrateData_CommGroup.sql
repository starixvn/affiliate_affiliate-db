USE [Affiliate_12BET]
GO

/*
	Created: 20180827@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Migrate data to new tables - CommGroup
*/

-- I. Commission Group
	-- Exclude testing group
	DECLARE @MonthDate SMALLDATETIME = '2018-09-30'

	DECLARE @TestGroup TABLE (GroupId INT)
	INSERT INTO @TestGroup (GroupId)
	SELECT DISTINCT GroupId FROM dbo.TierSetting WITH (NOLOCK)

	-- I.1. Change name of private group = affiliate's username
	UPDATE cg WITH (ROWLOCK, UPDLOCK)
	SET cg.GroupName = ai.UserName
	FROM dbo.CommGroup cg
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON cg.GroupId = ai.AffId
		LEFT JOIN @TestGroup tg ON cg.GroupId = tg.GroupId
	WHERE cg.GroupId > 1000
		AND tg.GroupId IS NULL

-- II. Default value of new fees
	-- Remove old fees
	DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
	WHERE DeductionId < 10

	DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
	WHERE DeductionId < 10 AND MonthDate = @MonthDate

	-- Insert new fees
	INSERT INTO dbo.DeductionSetting (GroupID,DeductionID,DeductedPercentage,NextDeductedPercentage,ProductId)
	SELECT cg.GroupId,f.DeductionID,f.DeductedPercentage,f.NextDeductedPercentage,f.ProductId
	FROM dbo.CommGroup cg WITH (NOLOCK)
		CROSS JOIN (
			VALUES
				(10, 0.17, 0.17, 1), -- FlatForm Fee Sportsbook
				(10, 0.17, 0.17, 3), -- FlatForm Fee Playtech Casino
				(11, 0.15, 0.15, 0), -- Operational Fee
				(12, 0.02, 0.02, 0) -- Banking Fee
		) AS f (DeductionID,DeductedPercentage,NextDeductedPercentage,ProductId)
		LEFT JOIN @TestGroup tg ON cg.GroupId = tg.GroupId
	WHERE tg.GroupId IS NULL

-- III. Tier Setting
	INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
	SELECT GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
	FROM
	(
		SELECT
			gs.*,
			-- Sportsbook >> PTCS >> Racing
			ROW_NUMBER() OVER(PARTITION BY gs.GroupId, gs.TierId ORDER BY CASE gs.SportType WHEN 1 THEN 1 WHEN 2 THEN 3 WHEN 3 THEN 2 END ASC) AS RowNum
		FROM dbo.GroupSetting gs WITH (NOLOCK)
			LEFT JOIN @TestGroup tg ON gs.GroupId = tg.GroupId
		WHERE tg.GroupId IS NULL
	) AS A
	WHERE RowNum = 1
	ORDER BY GroupId, TierId

	INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
	SELECT GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
	FROM
	(
		SELECT
			gs.*,
			-- Sportsbook >> PTCS >> Racing
			ROW_NUMBER() OVER(PARTITION BY gs.GroupId, gs.TierId ORDER BY CASE gs.SportType WHEN 1 THEN 1 WHEN 2 THEN 3 WHEN 3 THEN 2 END ASC) AS RowNum
		FROM dbo.GroupSetting gs WITH (NOLOCK)
			LEFT JOIN @TestGroup tg ON gs.GroupId = tg.GroupId
		WHERE tg.GroupId IS NULL
	) AS A
	WHERE RowNum = 1
	ORDER BY GroupId, TierId

-- IV. QMTurnover
	UPDATE cg WITH (ROWLOCK, UPDLOCK)
	SET QMTurnover = 100, NextQMTurnover = 100
	FROM dbo.CommGroup cg
		LEFT JOIN @TestGroup tg ON cg.GroupId = tg.GroupId
	WHERE tg.GroupId IS NULL

	UPDATE cg WITH (ROWLOCK, UPDLOCK)
	SET QMTurnover = 100, NextQMTurnover = 100
	FROM dbo.CommGroupHistory cg
		LEFT JOIN @TestGroup tg ON cg.GroupId = tg.GroupId
	WHERE tg.GroupId IS NULL
		AND cg.MonthDate = @MonthDate