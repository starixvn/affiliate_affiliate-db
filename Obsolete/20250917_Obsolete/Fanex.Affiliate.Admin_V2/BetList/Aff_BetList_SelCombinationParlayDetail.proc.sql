USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_BetListSystemParlayDetail]    Script Date: 10/17/2014 12:47:09 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  PROCEDURE [dbo].[Aff_BetList_SelCombinationParlayDetail]  
	@UserId 			INT
	,@Refno 			BIGINT
	,@TransId 			BIGINT 	= 0
	,@BetId 			BIGINT 	= 0
	,@CustId 			INT		= 0
	,@MoveBetsDay 		SMALLDATETIME
	,@BalanceUpDay 		SMALLDATETIME
	,@Outstanding 		MONEY = 0 OUTPUT
	,@OutstandingUSD 	MONEY = 0 OUTPUT
	,@OutstandingEUR 	MONEY = 0 OUTPUT
	,@OutstandingMYR 	MONEY = 0 OUTPUT
AS
/*
Created:20141017@Bobby.Nguyen
Task: Get Betlist Parlay by TransID
DB: DBEXT/bodb02
Orgiginal: dbo.Lrf_BetList_SelCombinationParlayDetail

Revisions:    
	- 20141017@Bobby.Nguyen: Initial SP
*/

BEGIN	
	SET NOCOUNT ON

	DECLARE @Today 		SMALLDATETIME
		,@Fromdate 		DATETIME
		,@Todate 		DATETIME
		
	DECLARE @currency 	INT
		,@USD 			FLOAT
		,@EUR 			FLOAT
		,@MYR 			FLOAT
		
	SELECT @Today = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)

	DECLARE @tmpBettrans AS TABLE (
		transid BIGINT
		,transdate DATETIME
		,refno BIGINT
		,winlostdate SMALLDATETIME
		,odds SMALLMONEY
		,stake MONEY
		,actual_stake MONEY
		,winlost MONEY
		,STATUS VARCHAR(20)
		,betteam VARCHAR(20)
		,IP VARCHAR(40)
		,spositiontaking SMALLMONEY
		,mpositiontaking SMALLMONEY
		,apositiontaking SMALLMONEY
		,swinlost MONEY
		,mwinlost MONEY
		,awinlost MONEY
		,sdiscount SMALLMONEY
		,adiscount SMALLMONEY
		,discount SMALLMONEY
		,scomm MONEY
		,acomm MONEY
		,comm MONEY
		,playercomm MONEY
		,
		--for generating combination parlays if not in BetParlayResult  
		[N] [tinyint]
		,-- total selection (match)  
		[cnt] [smallint]
		,-- total sub-ticket count  
		[bitmap] [smallint] -- bitmap to identify which parlay set is choosen     
	)
	DECLARE @parlay_base AS TABLE (
		transid BIGINT
		,refno BIGINT
		,winlostdate SMALLDATETIME
		,bettype INT
		,homeid INT
		,awayid INT
		,hdp1 SMALLMONEY
		,hdp2 SMALLMONEY
		,odds SMALLMONEY
		,betteam VARCHAR(20)
		,statusid INT
		,livehomescore INT
		,liveawayscore INT
		,liveindicator BIT
		,leagueid INT
		,sporttype INT
		,isNeutral BIT
		,matchid INT
		,matchcode VARCHAR(50)
		,matchdate DATETIME
		,
		--for generating combination parlays  
		RN TINYINT
		,-- set No. for selection in the combination  
		CNT TINYINT
		,-- total selection count, base on bettransm/14  
		bCNT TINYINT -- total selection count, stored in bettrans  
	)
	DECLARE @tmpResults TABLE (
		winlostdate DATETIME
		,transid BIGINT
		,serial BIGINT
		,statusid INT
		,STATUS VARCHAR(20)
		,modds SMALLMONEY
		,stake MONEY
		,winlost MONEY
		,comm MONEY
		,playercomm MONEY
		)
	DECLARE @betParlayDetail TABLE (
		RefNo BIGINT
		,Serial INT
		,matchid INT
		)
	DECLARE @tmpMatch AS TABLE (
		serial BIGINT
		,homeid INT
		,awayid INT
		)
	DECLARE @minMatchdate DATETIME
		,@maxMatchdate DATETIME

		
	SELECT @currency = c.currency
	FROM dbo.custinfo c WITH (NOLOCK)
	WHERE c.custid = @custid

	-----  
	-- DROP TABLE #Currency  
	----  
	INSERT INTO @parlay_base (
		transid
		,refno
		,winlostdate
		,bettype
		,homeid
		,awayid
		,hdp1
		,hdp2
		,odds
		,betteam
		,statusid
		,livehomescore
		,liveawayscore
		,liveindicator
		,leagueid
		,sporttype
		,isNeutral
		,matchid
		,matchcode
		,matchdate
		)
	SELECT bm.transid
		,bm.refno
		,bm.winlostdate
		,bm.bettype
		,m.homeid
		,m.awayid
		,bm.hdp1
		,bm.hdp2
		,bm.odds
		,bm.betteam
		,bm.statusid
		,bm.livehomescore
		,bm.liveawayscore
		,bm.liveindicator
		,m.leagueid
		,m.sporttype
		,m.isNeutral
		,m.matchid
		,m.matchcode
		,bm.matchdate
	FROM bettransm bm WITH (NOLOCK)
		INNER JOIN match m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE refno = @refno
		AND custid = @custid

	UNION
	SELECT bm.transid
		,bm.refno
		,bm.winlostdate
		,bm.bettype
		,m.homeid
		,m.awayid
		,bm.hdp1
		,bm.hdp2
		,bm.odds
		,bm.betteam
		,bm.statusid
		,bm.livehomescore
		,bm.liveawayscore
		,bm.liveindicator
		,m.leagueid
		,m.sporttype
		,m.isNeutral
		,m.matchid
		,m.matchcode
		,bm.matchdate
	FROM bettransm14 bm WITH (NOLOCK)
		INNER JOIN match14 m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE refno = @refno

	UNION
	SELECT bm.transid
		,bm.refno
		,bm.winlostdate
		,bm.bettype
		,m.homeid
		,m.awayid
		,bm.hdp1
		,bm.hdp2
		,bm.odds
		,bm.betteam
		,bm.statusid
		,bm.livehomescore
		,bm.liveawayscore
		,bm.liveindicator
		,m.leagueid
		,m.sporttype
		,m.isNeutral
		,m.matchid
		,m.matchcode
		,bm.matchdate
	FROM DB06.bodb_archive.dbo.bettransm bm WITH (NOLOCK)
		INNER JOIN DB06.bodb_archive.dbo.match_bk m WITH (NOLOCK) ON bm.matchid = m.matchid
	WHERE refno = @refno

	SELECT @minMatchdate = MIN(matchdate)
		,@maxMatchdate = MAX(matchdate)
	FROM @parlay_base

	IF @minMatchdate < @BalanceUpDay
	BEGIN
		INSERT INTO @tmpBettrans (
			transid
			,transdate
			,refno
			,winlostdate
			,odds
			,stake
			,actual_stake
			,winlost
			,playercomm
			,STATUS
			,betteam
			,ip
			,spositiontaking
			,mpositiontaking
			,apositiontaking
			,swinlost
			,mwinlost
			,awinlost
			,sdiscount
			,adiscount
			,discount
			,scomm
			,acomm
			,comm
			,N
			,cnt
			,bitmap
			)
		SELECT transid
			,transdate
			,refno
			,winlostdate
			,modds AS odds
			,stake
			,actual_stake
			,CASE 
				WHEN statusid NOT IN (0, 1) THEN winlost - actual_stake
				ELSE winlost
				END AS winlost
			,playercomm
			,STATUS
			,betteam
			,ip
			,spositiontaking
			,mpositiontaking
			,apositiontaking
			,swinlost
			,mwinlost
			,awinlost
			,sdiscount
			,adiscount
			,discount
			,scomm
			,acomm
			,comm
			,len(betteam) AS N
			,hdp1 AS cnt
			,hdp2 AS bitmap
		FROM DB06.bodb_archive.dbo.bettrans_bk b WITH (NOLOCK)
		WHERE custid = @custid
			AND refno = @refno
			AND matchid = 29
			AND bettype = 29
			AND transid NOT IN (
				SELECT transid
				FROM @tmpBettrans
				)

		INSERT INTO @tmpResults (
			winlostdate
			,serial
			,modds
			,stake
			,winlost
			,statusid
			,comm
			,playercomm
			)
		SELECT winlostdate
			,serial
			,modds
			,stake
			,winlost
			,statusid
			,comm
			,CASE 
				WHEN statusid IN (112, 113) THEN playercomm
				ELSE 0
				END AS playercomm
		FROM DB06.bodb_archive.dbo.betparlayresult b WITH (NOLOCK)
		WHERE refno = @refno
	END

	IF @minMatchdate <= @MoveBetsDay --- get data from bettrans14  
	BEGIN
		INSERT INTO @tmpBettrans (
			transid
			,transdate
			,refno
			,winlostdate
			,odds
			,stake
			,actual_stake
			,winlost
			,playercomm
			,STATUS
			,betteam
			,ip
			,spositiontaking
			,mpositiontaking
			,apositiontaking
			,swinlost
			,mwinlost
			,awinlost
			,sdiscount
			,adiscount
			,discount
			,scomm
			,acomm
			,comm
			,N
			,cnt
			,bitmap
			)
		SELECT transid
			,transdate
			,refno
			,winlostdate
			,modds AS odds
			,stake
			,actual_stake
			,CASE 
				WHEN statusid NOT IN (0, 1) THEN winlost - actual_stake
				ELSE winlost
				END AS winlost
			,playercomm
			,STATUS
			,betteam
			,ip
			,spositiontaking
			,mpositiontaking
			,apositiontaking
			,swinlost
			,mwinlost
			,awinlost
			,sdiscount
			,adiscount
			,discount
			,scomm
			,acomm
			,comm
			,len(betteam) AS N
			,hdp1 AS cnt
			,hdp2 AS bitmap
		FROM bettrans14 b WITH (NOLOCK)
		WHERE custid = @custid
			AND refno = @refno
			AND matchid = 29
			AND bettype = 29
			AND transid NOT IN (
				SELECT transid
				FROM @tmpBettrans
				)
	END

	IF @maxMatchdate > @MoveBetsDay --- get data from bettrans  
	BEGIN
		INSERT INTO @tmpBettrans (
			transid
			,transdate
			,refno
			,winlostdate
			,odds
			,stake
			,actual_stake
			,winlost
			,playercomm
			,STATUS
			,betteam
			,ip
			,spositiontaking
			,mpositiontaking
			,apositiontaking
			,swinlost
			,mwinlost
			,awinlost
			,sdiscount
			,adiscount
			,discount
			,scomm
			,acomm
			,comm
			,N
			,cnt
			,bitmap
			)
		SELECT transid
			,transdate
			,refno
			,winlostdate
			,modds AS odds
			,stake
			,actual_stake
			,winlost - actual_stake AS winlost
			,playercomm
			,STATUS
			,betteam
			,ip
			,spositiontaking
			,mpositiontaking
			,apositiontaking
			,swinlost
			,mwinlost
			,awinlost
			,sdiscount
			,adiscount
			,discount
			,scomm
			,acomm
			,comm
			,len(betteam) AS N
			,hdp1 AS cnt
			,hdp2 AS bitmap
		FROM bettrans b WITH (NOLOCK)
		WHERE custid = @custid
			AND refno = @refno
			AND matchid = 29
			AND bettype = 29
			AND transid NOT IN (
				SELECT transid
				FROM @tmpBettrans
				)
	END

	INSERT INTO @tmpResults (
		winlostdate
		,serial
		,modds
		,stake
		,winlost
		,statusid
		,comm
		,playercomm
		)
	SELECT winlostdate
		,serial
		,modds
		,stake
		,winlost
		,statusid
		,comm
		,CASE 
			WHEN statusid IN (112, 113) THEN playercomm
			ELSE 0
			END AS playercomm
	FROM betparlayresult b WITH (NOLOCK)
	WHERE refno = @refno
		AND serial NOT IN (
			SELECT serial
			FROM @tmpResults
			)

	----- generate betparlay detail  
	IF @minMatchdate < @BalanceUpday
	BEGIN
			;

		WITH sub
		AS (
			SELECT ROW_NUMBER() OVER (
					ORDER BY matchid
					) RN
				,matchid
			FROM @parlay_base
			)
		UPDATE pb
		SET RN = sub.RN
		FROM sub
			INNER JOIN @parlay_base pb ON sub.matchid = pb.matchid
			-- prepare N  
			;

		WITH sub
		AS (
			SELECT count(*) cnt
			FROM @parlay_base
			)
		UPDATE pb
		SET CNT = sub.cnt
			,bCNT = t.N
		FROM sub
			,@parlay_base pb
			,@tmpBettrans t

		IF NOT EXISTS (
				SELECT 1
				FROM @parlay_base
				WHERE cnt <> bCnt
				)
		BEGIN
			INSERT INTO @betParlayDetail (
				RefNo
				,Serial
				,matchid
				)
			SELECT pb.RefNo
				,rc.Serial
				,matchid
			FROM @parlay_base pb
				INNER JOIN @tmpBettrans tb ON pb.refno = tb.refno
				INNER JOIN dbo.RefCombination rc ON pb.RN = rc.seq
				AND pb.CNT = rc.N
				AND (tb.bitmap & rc.bitmap) > 0
		END
	END
	ELSE
	BEGIN
		INSERT INTO @betParlayDetail (
			RefNo
			,Serial
			,matchid
			)
		SELECT refno
			,serial
			,matchid
		FROM betParlayDetail WITH (NOLOCK)
		WHERE refno = @refno
	END

	----- get homeid, awayid  
	IF @MinMatchdate < @BalanceUpday
	BEGIN
		INSERT INTO @tmpMatch
		SELECT p.serial
			,homeid
			,awayid
		FROM @tmpResults p
			INNER JOIN @betParlayDetail b ON p.Serial = b.Serial
			INNER JOIN DB06.BODB_Archive.dbo.match_bk m WITH (NOLOCK) ON b.matchid = m.matchid
		WHERE p.statusid <> 113
	END

	IF @MinMatchdate <= @MoveBetsDay
	BEGIN
		INSERT INTO @tmpMatch
		SELECT p.serial
			,homeid
			,awayid
		FROM @tmpResults p
			INNER JOIN @betParlayDetail b ON p.Serial = b.Serial
			INNER JOIN match14 m WITH (NOLOCK) ON b.matchid = m.matchid
		WHERE p.statusid <> 113
	END

	IF @MaxMatchdate > @MoveBetsDay
	BEGIN
		INSERT INTO @tmpMatch
		SELECT p.serial
			,homeid
			,awayid
		FROM @tmpResults p
			INNER JOIN @betParlayDetail b ON p.Serial = b.Serial
			INNER JOIN match m WITH (NOLOCK) ON b.matchid = m.matchid
		WHERE p.statusid <> 113
	END

	---- calculate outstanding  
	SELECT @Outstanding = MAX(stake)
	FROM @tmpBettrans

	SELECT @Outstanding = @Outstanding - ISNULL(SUM(stake), 0)
	FROM @tmpResults
	WHERE statusID NOT IN (0, 1)

	SELECT @USD = e.USD
		,@EUR = e.EUR
		,@MYR = e.MYR
	FROM (
		SELECT *
		FROM Lrf_f_GetExchangeDaily(@Today, @Today)
		) e
	WHERE e.ExchangeDate = @Today
		AND e.ExchangeId = @currency

	SELECT @Outstanding = ISNULL(@Outstanding, 0)

	SELECT @OutstandingUSD = ISNULL(@Outstanding, 0) * ISNULL(@USD, 0)

	SELECT @OutstandingEUR = ISNULL(@Outstanding, 0) * ISNULL(@EUR, 0)

	SELECT @OutstandingMYR = ISNULL(@Outstanding, 0) * ISNULL(@MYR, 0)

	SELECT @Fromdate = MIN(winlostdate)
		,@Todate = MAX(winlostdate)
	FROM @tmpResults

	-- return combo detail  
	SELECT 0 AS [order]
		,winlostdate
		,0 transid
		,serial
		,statusid
		,CASE statusid
			WHEN 101 THEN 'REJECT'
			WHEN 102 THEN 'VOID'
			WHEN 103 THEN 'REFUND'
			WHEN 111 THEN 'DRAW'
			WHEN 112 THEN 'WON'
			ELSE ''
			END AS STATUS
		,modds
		,stake
		,CAST(stake * e.usd AS MONEY) AS stakeusd
		,CAST(stake * e.eur AS MONEY) AS stakeeur
		,CAST(stake * e.myr AS MONEY) AS stakemyr
		,winlost - stake AS winlost
		,cast((winlost - stake) * e.usd AS MONEY) AS winlostusd
		,cast((winlost - stake) * e.eur AS MONEY) AS winlosteur
		,cast((winlost - stake) * e.myr AS MONEY) AS winlostmyr
		,comm
		,cast(comm * e.usd AS MONEY) AS commusd
		,cast(comm * e.eur AS MONEY) AS commeur
		,cast(comm * e.myr AS MONEY) AS commmyr
		,playercomm
		,cast(playercomm * e.usd AS MONEY) AS playercommusd
		,cast(playercomm * e.eur AS MONEY) AS playercommeur
		,cast(playercomm * e.myr AS MONEY) AS playercommmyr
	FROM @tmpResults b
		INNER JOIN (
		SELECT *
		FROM Lrf_f_GetExchangeDaily(@FromDate, @ToDate)
		) e ON e.ExchangeDate = b.winlostdate
		AND e.exchangeid = @currency
	WHERE statusid NOT IN (0, 1, 113)

	UNION ALL
	SELECT 999 AS [order]
		,winlostdate
		,0 AS transid
		,0 AS serial
		,113 AS statusid
		,'LOSE' AS STATUS
		,0 AS modds
		,SUM(stake) AS stake
		,CAST(sum(stake * e.usd) AS MONEY) AS stakeusd
		,cast(sum(stake * e.eur) AS MONEY) AS stakeeur
		,cast(sum(stake * e.myr) AS MONEY) AS stakemyr
		,SUM(winlost - stake) AS winlost
		,cast(SUM((winlost - stake) * e.usd) AS MONEY) AS winlostusd
		,cast(SUM((winlost - stake) * e.eur) AS MONEY) AS winlosteur
		,cast(SUM((winlost - stake) * e.myr) AS MONEY) AS winlostmyr
		,sum(comm) AS comm
		,cast(sum(comm * e.usd) AS MONEY) AS commusd
		,cast(sum(comm * e.eur) AS MONEY) AS commeur
		,cast(sum(comm * e.myr) AS MONEY) AS commmyr
		,sum(playercomm) AS playercomm
		,cast(sum(playercomm * e.usd) AS MONEY) AS playercommusd
		,cast(sum(playercomm * e.eur) AS MONEY) AS playercommeur
		,cast(sum(playercomm * e.myr) AS MONEY) AS playercommmyr
	FROM @tmpResults b
		INNER JOIN (
		SELECT *
		FROM Lrf_f_GetExchangeDaily(@FromDate, @ToDate)
		) e ON e.ExchangeDate = b.winlostdate
		AND e.exchangeid = @currency
	WHERE statusid = 113
	GROUP BY winlostdate
	ORDER BY [order] ASC
		,winlostdate ASC

	SELECT *
	FROM @tmpMatch
END
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_SelCombinationParlayDetail] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_SelCombinationParlayDetail] TO [bodbDownlineNet] AS [dbo]
GO  
