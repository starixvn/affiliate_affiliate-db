/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_CasinoImportData]	
	@AdminID		INT,
	@ImportDate		SMALLDATETIME,
	@XmlData		XML,
	@IsReplaceData	BIT = 0,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(500) = '' OUTPUT
AS

/*
	Task : Import casino transactions FROM excel file INTo 2 tables, memberdaily and AffDailySummary
	Author : Johnny@20110801
	DB: DB052.Affiliate_12BET
	Original: [Aff_CasinoImportData]
	Revisions: 
		- 20120409@Johnny:
			+ link: http://ccs.nexcel.vn/viewtopic.php?f=4&t=6320
			+ Desc: import monthly Casino data in excel file to Affiliate_12BET DB when a month is completed to calculate Casino Commission
		- 20121211@Johnny: only import casino data for affiliate has been approved Casino before the date import data
		- 20150907@Bobby.Nguyen:  Hotfix#42274 - Add/check data constraINT of removal members
		- 20171010@Percy: Upgrade service job [RedmineID: #84602]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tmpData TABLE
	(
		winlostdate	SMALLDATETIME,
		UserName	NVARCHAR(30),
		Currency	NVARCHAR(50),
		Turnover	MONEY,
		Winlost		MONEY,
		Deposit		MONEY,
		Bonus		MONEY
	)

	BEGIN TRY
		INSERT INTO @tmpData -- Convert xml to table
		SELECT 	 
			winlostdate,
			Username,
			Currency,
			Turnover,
			Winlost,
			Deposit,
			Bonus
		FROM
			(SELECT
				[Table].[Column].value('./@date', 'SMALLDATETIME') AS [winlostdate],
				[Table].[Column].value('./@username', 'VARCHAR(200)') AS [Username],
				[Table].[Column].value('./@currency', 'NVARCHAR(50)') AS [Currency],
				[Table].[Column].value('./@turnover', 'FLOAT') AS [Turnover],
				[Table].[Column].value('./@winlostaff', 'FLOAT') AS [Winlost],
				[Table].[Column].value('./@deposit', 'FLOAT') AS [Deposit],
				[Table].[Column].value('./@bonus', 'FLOAT') AS [Bonus]
			FROM @XmlData.nodes('/root/trans') AS [Table]([Column])
			) AS tmp
	END TRY
	BEGIN CATCH
		SELECT
			@ErrCode = 10102,
			@ErrMsg = 'Convert xml failed'

			RETURN
	END CATCH

	DECLARE @tmpWinlostdate TABLE (winlostdate SMALLDATETIME) -- all winlostdates
	INSERT INTO @tmpWinlostdate (winlostdate)
	SELECT DISTINCT winlostdate FROM @tmpData

	DECLARE @minWinlostdate SMALLDATETIME
	SELECT  @minWinlostdate = MIN(winlostdate) FROM @tmpWinlostdate

	DECLARE @CasinoId INT
	SELECT  @CasinoId = dbo.Aff_GetSportID('Casino')
	
	-- Check Monthly transfer or not
	IF EXISTS (SELECT 1 FROM dbo.AffTrans WITH (NOLOCK) WHERE TransType = 201 AND DATEDIFF(MONTH, TransDate, @minWinlostdate) = 0)
	BEGIN
		SELECT
			@ErrCode = 10101,
			@ErrMsg = 'You cannot import Casino transaction because monthly transfers for the month '
						+ CONVERT(VARCHAR(3), @minWinlostdate) + ' '
						+ CONVERT(VARCHAR(4), YEAR(@minWinlostdate)) +  ' has been completed!'
		RETURN
	END

	-- Check Data whether Casino data import or not.
	IF @IsReplaceData = 0
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM dbo.MemberDaily md WITH (NOLOCK)
				INNER JOIN @tmpWinlostdate w ON md.WinlostDate = w.winlostdate
			WHERE md.SportType = @CasinoId
		)
		BEGIN
			SELECT
				@ErrCode = 10100,
				@ErrMsg = 'You cannot import Casino transaction! Because data has been imported already!'
			
			RETURN
		END
	END

	DECLARE @Exchange TABLE
	(
		ExchangeDate	SMALLDATETIME,
		ExchangeId		INT,
		Currency		NVARCHAR(50),
		MemberExRate	FLOAT,
		AffExRate		FLOAT
	)

	INSERT INTO @Exchange (ExchangeDate, ExchangeId, Currency, MemberExRate, AffExRate)
	SELECT ex1.winlostdate, ex.ExchangeId, ex.Currency, ex.ActualRate AS MemberExRate, ex.ActualRate2 AS AffExRate
	FROM dbo.Exchange ex WITH (NOLOCK)
		INNER JOIN
		(
			SELECT w.winlostdate, e.ExchangeID, MAX(e.UpdatedTime) AS UpdatedTime
			FROM dbo.Exchange e WITH (NOLOCK)
				INNER JOIN @tmpWinlostdate w ON e.UpdatedTime <= w.winlostdate
			GROUP BY w.winlostdate, e.ExchangeID
		) ex1 ON ex.ExchangeId = ex1.ExchangeId AND ex.UpdatedTime = ex1.UpdatedTime

	DECLARE @SuccessTrans TABLE(winlostdate SMALLDATETIME, IBCCustID INT, UserName NVARCHAR(30), ExchangeId INT, Currency NVARCHAR(50), Turnover MONEY, Winlost MONEY, Deposit MONEY, Bonus MONEY)--List trans insert successfully

	BEGIN TRANSACTION 

		IF @IsReplaceData = 1--If Replace Data => delete old data and import new data
		BEGIN
			DELETE md WITH (ROWLOCK, UPDLOCK)
			FROM dbo.MemberDaily md
				INNER JOIN @tmpWinlostdate w ON md.WinlostDate = w.winlostdate
			WHERE md.SportType = @CasinoId

			DELETE mdi WITH (ROWLOCK, UPDLOCK)
			FROM dbo.MemberDaily_Invalid mdi
				INNER JOIN @tmpWinlostdate w ON mdi.WinlostDate = w.winlostdate
			WHERE mdi.SportType = @CasinoId

			DELETE ad WITH (ROWLOCK, UPDLOCK)
			FROM dbo.AffDaily ad
				INNER JOIN @tmpWinlostdate w ON ad.WinlostDate = w.winlostdate
			WHERE ad.SportId = @CasinoId

			DELETE ads WITH (ROWLOCK, UPDLOCK)
			FROM dbo.AffDailySummary ads
				INNER JOIN @tmpWinlostdate w ON ads.WinlostDate = w.winlostdate
			WHERE ads.SportId = @CasinoId

			IF @@ERROR <> 0 
			BEGIN
				SELECT
					@ErrCode = 1008,
					@ErrMsg = 'There was an error when updating data.'
				
				ROLLBACK TRANSACTION
				
				RETURN
			END
		END
		
		-- Insert transactions to MemberDaily
		INSERT INTO MemberDaily
		(
			[WinlostDate]
			,[IBCCustID]
			,[SportType]
			,[Currency]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[AWinlost]
			,[ABonus]
			,[AffExRate]
			,[MemberExRate]
			,[DrawGame]
			,[PSP]
			,[Marketing]
			,[AffID]
			,[MemOddsFee]
			,[MemWinlostFake]
			,[MemPLayTechFee]
		)
		OUTPUT
			INSERTED.WinlostDate,
			INSERTED.IBCCustID,
			INSERTED.Currency,
			INSERTED.Turnover,
			INSERTED.Winlost,
			INSERTED.Deposit,
			INSERTED.Bonus
		INTO @SuccessTrans
		(
			winlostdate,
			IBCCustID,
			ExchangeId,
			Turnover,
			Winlost,
			Deposit,
			Bonus
		)
		SELECT
			t.winlostdate, 
			IBCCustId, 
			3 AS SportType, 
			m.Currency,
			t.Deposit,
			0 AS Withdrawal,
			t.Bonus,		
			0 AS Adjustment,
			Turnover,
			0 AS Outstanding,
			-Winlost,
			0 AS AWinlost,
			0 AS ABonus,		
			ex.AffExRate,--Get AffRate here
			ex.MemberExRate,--Get MemberExrate here
			0 AS DrawGame,
			0 AS PSP,
			abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'Marketing',t.winlostdate),0) AS Marketing,
			AffId,
			0 AS MemOddsFee,
			-(-Winlost
				- (abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'PlayTech Royalties',t.winlostdate),0))
				-  (abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'Marketing',t.winlostdate),0))
			) AS MemWinlostFake,

			abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@CasinoId,'PlayTech Royalties',t.winlostdate),0) AS MemPLayTechFee
		FROM @tmpData t
			INNER JOIN (
				SELECT m.IBCCustID, m.UserName, m.Currency, m.AffID, a.CasinoJoinedDate
				FROM dbo.MemberInfo m WITH (NOLOCK)
					INNER JOIN dbo.AffInfo a WITH (NOLOCK) ON m.AffID = a.AffID
					LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON m.IBCCustID = mr.IBCCustID
				WHERE a.CasinoJoinedDate IS NOT NULL
					AND m.CreatedDate IS NOT NULL
					AND DATEDIFF(DAY, m.CreatedDate, @ImportDate) >= 0
					AND (
						m.IsRemoved = 0
						OR (
							m.IsRemoved = 1
							AND DATEDIFF(MONTH, mr.RemovedDate, @ImportDate) < 0
						)
					)
			) AS m ON '12bet$' + t.UserName = m.UserName AND t.winlostdate >= m.CasinoJoinedDate
			INNER JOIN @Exchange ex ON m.Currency = ex.ExchangeID AND t.winlostdate = ex.ExchangeDate

		--Insert Data INTo Affiliate Daily
		INSERT INTO AffDaily
		(
			[AffID]
			,[Currency]
			,[Winlostdate]
			,[SportID]
			,[ExRate2]
			,[MemDeposit]
			,[MemWithdrawal]
			,[MemTurnover]
			,[MemBonus]
			,[MemAdjustment]
			,[MemMarketing]
			,[MemPSP]
			,[MemWinlost]
			,[AffWinlost]
			,[HouseWinlost]
			,[AffNetWinlost]
			,[HouseNetWinlost]
			,[MemWinlostFake]
			,[MemOddsFee]
			,[MemPLayTechFee]
		)
		SELECT
			d.AffID AS AffID,      
			d.Currency AS Currency,       
			d.Winlostdate AS Winlostdate,       
			d.SportType AS SportID,      
			d.AffExRate AS Exrate2,       
			SUM(isnull(d.Deposit, 0)) AS MemDeposit,   
			0 AS MemWithdrawal,       
			SUM(isnull(d.Turnover, 0)) AS MemTurnover,       
			SUM(isnull(d.Bonus, 0)) AS MemBonus,    
			0 AS MemAdjustment,    
			0 AS MemMarketing,    
			0 AS MemPSP,        
			SUM(isnull(d.Winlost, 0)) AS MemWinLost,        
			0 AS AffWinLost,      
			-SUM(d.Winlost) AS HouseWinLost,        
			0 AS AffNetWinlost,      
			0 AS HouseNetWinLost,	
			0 AS MemWinlostFake,      
			0 AS MemOddsFee,
			0 AS MemPLayTechFee
		FROM dbo.MemberDaily d WITH (NOLOCK)
		WHERE SportType = @CasinoId AND winlostdate IN (SELECT winlostdate FROM @tmpWinlostdate)
		GROUP BY d.AffID,d.Winlostdate, d.Currency, d.SportType,d.AffExRate   

		UPDATE dbo.AffDaily WITH (ROWLOCK, UPDLOCK)
		SET 
			MemPLayTechFee= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0),
			[MemMarketing]= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0),
			--MemOddsFee= abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Odds Fee',Winlostdate),0),  
			HouseNetWinLost=HouseWinLost
								- isnull(MemBonus,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Casino Bonus',Winlostdate),0)   
								- isnull(MemWinlost,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
								- isnull(MemWinlost,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0),
			MemWinlostFake=-(-isnull(MemWinlost,0)
							 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
							 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)							 
							)
		WHERE winlostdate IN (SELECT winlostdate FROM @tmpWinlostdate) AND SportID = @CasinoId

		

		--Insert Data INTo Affiliate Summary Daily
		INSERT INTO [dbo].[AffDailySummary]
		(
			[AffID]
			,[Winlostdate]
			,[SportID]
			,[MemDeposit]
			,[MemWithdrawal]
			,[MemTurnover]
			,[MemBonus]
			,[MemAdjustment]
			,[MemMarketing]
			,[MemPSP]
			,[MemWinlost]
			,[AffWinlost]
			,[HouseWinlost]
			,[AffNetWinlost]
			,[HouseNetWinlost]
			,[MemOddsFee]
			,[MemWinlostFake]
			,[MemPLayTechFee]	   
		)
		SELECT
			[AffID]
			,[Winlostdate]
			,[SportID]
			,sum([MemDeposit]* ExRate2) AS MemDeposit
			,sum([MemWithdrawal]*ExRate2) AS MemWithdrawal
			,sum([MemTurnover]*ExRate2) AS MemTurnover
			,sum([MemBonus]*ExRate2) AS MemBonus
			,sum([MemAdjustment] * ExRate2) AS MemAdjustment
			,0 AS MemMarketing	
			,sum([MemPSP] * ExRate2) AS MemPSP
			,sum([MemWinlost] * ExRate2) AS MemWinlost
			,sum([AffWinlost] * ExRate2) AS AffWinlost
			,sum([HouseWinlost] * ExRate2) AS HouseWinlost
			,sum([AffNetWinlost]*ExRate2) AS AffNetWinlost
			,sum([HouseNetWinlost]*ExRate2) AS HouseNetWinlost
			,0 AS MemOddsFee
			,0 AS MemWinlostFake
			,0 AS MemPLayTechFee
		FROM dbo.AffDaily WITH (NOLOCK)
		WHERE winlostdate IN (SELECT winlostdate FROM @tmpWinlostdate) AND SportID = @CasinoId
		GROUP BY AffID, Winlostdate, SportID

		UPDATE dbo.AffDailySummary WITH (ROWLOCK, UPDLOCK)
		SET
			MemMarketing=abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',WinlostDate),         
			MemWinlostFake=-(-isnull(MemWinlost,0)
							 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
							 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)							 
							),
	   
			 HouseNetWinlost=(
								-MemWinlost
								-MemBonus * dbo.Aff_GetDeductionPercent(AffID,SportID,'Bonus',WinlostDate)
								 -abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'PlayTech Royalties',Winlostdate),0)
								-abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,SportID,'Marketing',Winlostdate),0)							 
							 )
		WHERE winlostdate IN (SELECT winlostdate FROM @tmpWinlostdate) AND SportID = @CasinoId 
	  
	 /*update last MemWinlostFake of last transaction date for each acount
		For example: Affiliate 1 : last day =28/11
					Affiliate 2 : last day= 29/11
					Affiliate 3 : last day= 31/11								
	 */
		DECLARE @minFirstDayOfImportDate datetime

		SELECT @minFirstDayOfImportDate=[dbo].[Aff_GetFirstDayOfMonth](min(winlostdate))
		FROM @tmpWinlostdate

		DECLARE @temp table(affid INT,totalWinlost MONEY, playTechFeePercent FLOAT,marketingPercent FLOAT,WLFake MONEY,maxWinlostDate SMALLDATETIME,previousMaxWinlostDate SMALLDATETIME,firstday SMALLDATETIME)

		INSERT INTO @temp(Affid,maxWinlostDate)
		SELECT a.AffID, MAX(a.Winlostdate)
		FROM dbo.AffDailySummary a WITH (NOLOCK)
			CROSS APPLY @tmpWinlostdate t
		WHERE a.winlostdate >= @minFirstDayOfImportDate
			AND DATEDIFF(m, a.winlostdate, t.winlostdate) = 0 
			AND a.SportID = @CasinoId 
		GROUP BY a.AffID, MONTH(a.winlostdate), YEAR(a.winlostdate)

		UPDATE t
		SET
			t.previousMaxWinlostDate
				= ISNULL(
					(
						SELECT MAX(winlostdate)
						FROM dbo.AffDailySummary a WITH (NOLOCK)
						WHERE a.SportID = @CasinoId AND a.Winlostdate < t.maxWinlostDate
							AND DATEDIFF(MONTH, a.Winlostdate, t.maxWinlostDate) = 0
							AND a.AffID = t.affid
					)
					, t.maxWinlostDate)
		   ,t.firstday=[dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate)    
		   ,t.playTechFeePercent=dbo.Aff_GetDeductionPercent(AffID,@CasinoId,'PlayTech Royalties',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))
		   ,marketingPercent=dbo.Aff_GetDeductionPercent(AffID,@CasinoId,'Marketing',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))
		FROM @temp t
	
		UPDATE ad
		SET ad.MemWinlostFake=-(-isnull(ad.MemWinlost,0)
							 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,@CasinoId,'PlayTech Royalties',ad.Winlostdate),0)
							 -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,@CasinoId,'Marketing',ad.Winlostdate),0)							 
							)
		FROM dbo.AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @temp t ON t.affid = ad.AffID AND t.previousMaxWinlostDate = ad.WinlostDate 
		WHERE ad.SportID = @CasinoId

		UPDATE d
		SET
			d.totalWinlost=isnull(c.totalwinlost,0)
		   ,d.WLFake=isnull(c.memWinlostFake,0)
		FROM @temp d
			LEFT JOIN (
				SELECT
					t.affid
				   ,SUM(ad.memwinlost) totalwinlost
				   ,SUM(ad.memWinlostFake) memWinlostFake
				FROM AffDailySummary ad (NOLOCK)
					INNER JOIN @temp t ON t.AffID = ad.AffID
				WHERE ad.WinlostDate BETWEEN t.firstday AND t.previousMaxWinlostDate
					AND ad.SportID = @CasinoId
				GROUP BY t.Affid  
			) AS c ON c.AffID = d.AffID

		UPDATE d
		SET d.MemWinlostFake=-(-(d1.totalwinlost + d.memwinlost) - abs (d1.totalwinlost + d.memwinlost) * (d1.playTechFeePercent+d1.marketingPercent))- d1.WLFake
		FROM dbo.AffDailySummary d WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @temp d1 ON d1.affid = d.affid AND d1.maxWinlostDate = d.winlostdate 			 
		WHERE d.sportid = @CasinoId
			AND d1.previousMaxWinlostDate < d1.maxWinlostDate
		
		IF @@ERROR <> 0
		BEGIN
			SELECT
				@ErrMsg = 'There was an error when updating data.'
			   ,@ErrCode = 1008
		
			ROLLBACK TRANSACTION
		
			RETURN
		END

	COMMIT TRANSACTION
		
	-- List successs transactions
	UPDATE st
	SET
		st.UserName = REPLACE(mi.Username, '12bet$', ''),
		st.Currency = ex.Currency
	FROM @SuccessTrans st
		INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON st.IBCCustID = mi.IBCCustID
		INNER JOIN dbo.Exchange_Current ex WITH (NOLOCK) ON st.ExchangeId = ex.ExchangeID

	-- Return list success transaction
	SELECT winlostdate AS DateImport, Username, Currency, Turnover, Winlost, Deposit, Bonus
	FROM @SuccessTrans 
	ORDER BY winlostdate

	-- List Failed Transaction
	INSERT INTO dbo.MemberDaily_Invalid
	(
		WinlostDate,
		IBCCustID,
		SportType,
		Currency,
		Deposit,
		Withdrawal,
		Bonus,
		Adjustment,
		Turnover,
		Outstanding,
		Winlost,
		AWinlost,
		ABonus,
		AffExRate,
		MemberExRate,
		DrawGame,
		PSP,
		Marketing,
		AffID,
		MemWinlostFake,
		MemOddsFee,
		MemPLayTechFee,
		OpeningBalance,
		ClosingBalance,
		Reason
	)
	SELECT
		t.WinlostDate,
		ISNULL(mi.IBCCustID, -1),
		@CasinoId AS SportType,
		ISNULL(ex.ExchangeID, -1),
		t.Deposit,
		0 AS Withdrawal,
		t.Bonus,
		0 AS Adjustment,
		t.Turnover,
		0 AS Outstanding,
		t.Winlost,
		0 AS AWinlost,
		0 AS ABonus,
		0 AS AffExRate,
		0 AS MemberExRate,
		0 AS DrawGame,
		0 AS PSP,
		0 AS Marketing,
		ISNULL(mi.AffID, -1),
		0 AS MemWinlostFake,
		0 AS MemOddsFee,
		0 AS MemPLayTechFee,
		0 AS OpeningBalance,
		0 AS ClosingBalance,
		CASE
			WHEN mi.IBCCustID IS NULL THEN 'Invalid Username: ' + t.UserName
			WHEN mi.IsRemoved = 1 AND DATEDIFF(MONTH, mr.RemovedDate, @ImportDate) >= 0 THEN 'Member was removed'
			WHEN mi.CreatedDate IS NULL THEN 'Invalid Member''s CreatedDate'
			WHEN ai.CasinoJoinedDate IS NULL THEN 'Invalid Aff''s CasinoJoinDate'
			WHEN t.winlostdate < ai.CasinoJoinedDate THEN 'Member''s Winlostdate less than Aff''s CasinoJoinDate'
		END AS Reason
	FROM @tmpData t
		LEFT JOIN @SuccessTrans st ON t.UserName = st.UserName AND t.winlostdate = st.winlostdate
		LEFT JOIN dbo.MemberInfo mi WITH (NOLOCK) ON '12Bet$' + t.UserName = mi.UserName
		LEFT JOIN dbo.AffInfo ai WITH (NOLOCK) ON mi.AffID = ai.AffID
		LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON mi.IBCCustID = mr.IBCCustID
		LEFT JOIN dbo.Exchange_Current ex WITH (NOLOCK) ON t.Currency = ex.Currency
	WHERE st.UserName IS NULL

	SELECT 
		t.winlostdate AS DateImport,
		t.Username, 
		(case t.Currency when 'CNY' then 'RMB'
				when 'USD' then 'US$'
				when 'EUR' then 'EURO'
				when 'VDO' then 'VND'
				when 'THB' then 'TB'
				when 'RUP' then 'IN'
				when 'MYR' then 'RM'
				else t.Currency end
		) AS Currency, 
		t.Turnover, 
		t.Winlost,
		t.Deposit,
		t.Bonus
	FROM @tmpData t
		LEFT JOIN @SuccessTrans st ON t.UserName = st.UserName AND t.winlostdate = st.winlostdate
	WHERE st.UserName IS NULL
	ORDER BY t.winlostdate
END
GO