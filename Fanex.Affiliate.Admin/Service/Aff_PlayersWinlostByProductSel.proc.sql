USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_PlayersWinlostByProductSel]    Script Date: 04/16/2014 04:10:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_PlayersWinlostByProductSel]  
	@Xml xml,
	@Prefix varchar(100),
	@Date   SMALLDATETIME   
AS   
/*  
Created: 20130111@Peter  
Task :   
DB: DB052/DB054.bodb02  
  
  
Revisions:  
          - 20131028@Peter : Add more DB columns https://redmine.nexcel.vn/issues/5280
		  - 20140416@Dan: include Keno
		  - 20140502@Dan: optimize perfomance
  
Param's Explanation:  
  
   
*/  


SET NOCOUNT ON
  
select @Date=dateadd(dd, datediff(dd,0, @DATE), 0)
     
--create table #LicenseeCust(custID INT PRIMARY KEY,currency int,username varchar(100), srecommend int, mrecommend int, recommend int)  
create table #LicenseeCust(custID INT,currency int,username varchar(100), srecommend int, mrecommend int, recommend int)  
DECLARE @CutDate datetime , @MaxDate datetime 
  
SELECT @CutDate =  min(winlostdate), @MaxDate=MAX(Winlostdate)   
FROM bodb_licensee.dbo.rptLicWinloss2 with(nolock)    
  
CREATE TABLE #tmpRpt (  
	Winlostdate SMALLDATETIME,  
	CustID INT,  
	Username NVARCHAR(50),  
	ProductID INT,  
	Turnover MONEY,   
	Outstanding MONEY,   
	Winloss MONEY,   
	DrawGame MONEY,
	PlayerComm MONEY,
	BetCount int,
	TurnoverNoDraw MONEY,
	BetCountNoDraw int 
	  
 )   
  
  
  DECLARE @TempTrans TABLE
  --CREATE TABLE #TempTrans
	(UserName varchar(30))

insert into @TempTrans(UserName) --Convert xml to table
Select	[Table].[Column].value('./@username', 'varchar(30)') as UserName
	from @Xml.nodes('/root/trans') as [Table]([Column])

--print @sqlCommand

INSERT INTO #LicenseeCust  
Select c.CustID, c.Currency, t.UserName, c.srecommend, c.mrecommend, c.recommend  
from bodb02.dbo.customer c with(nolock) 
	inner join @TempTrans as t on  @Prefix + t.username=c.username2	
where c.roleid=1

-- select * from #LicenseeCust  (nolock)


if @Date> @MaxDate
begin  
    INSERT INTO #tmpRpt (  
		Winlostdate, CustID,Username,ProductID, Turnover, Outstanding, Winloss, DrawGame,PlayerComm,BetCount,TurnoverNoDraw,BetCountNoDraw
	)  
    SELECT 
	@Date,  
	b.custid, 
	c.username,  
	CASE
		WHEN bettype IN (71,72) THEN 251 --casino
		WHEN bettype = 1000 THEN 253 --games
		WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
		WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
		WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
		WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport	
		WHEN bettype BETWEEN 51 AND 69 THEN 201	 -- Financial	
		WHEN bettype BETWEEN 1501 AND 1599 THEN 202-- Keno  
		WHEN b.bettype<31 OR (b.bettype BETWEEN 121 AND 999) THEN 0 -- sportsbook
	ELSE -1 END, -- undefined productid

	SUM(b.stake	),--Turnover  
    SUM(CASE WHEN  ruben=0 then actual_stake ELSE 0 END),	--Outstanding  
	SUM(CASE WHEN ruben=1 then b.winlost-b.actual_stake ELSE 0 END), --Winloss      
	SUM(case when statusID = 111 then stake else 0 end), -- Draw game TO
	SUM(CASE WHEN ruben=1 then b.playercomm ELSE 0 END), --Playercomm      
	COUNT(1),  --betcount

	SUM( stake * case WHEN statusID=111 THEN 0 
	          WHEN (b.statusID = 112 OR b.statusID = 113) AND ABS(modds) = 0.25 AND b.bettype IN(1,3,7,8,17,18) AND ( b.bettype<31 OR (b.bettype BETWEEN 121 AND 999)) THEN 0.5 -- sportsbook rules
			  when (b.statusID = 112 OR b.statusID = 113) AND b.liveawayscore = 0 and b.bettype IN(33,43) then 0.5 -- Racing rules
			  else 1
           end

	), -- Turnover No Draw
	SUM(CASE WHEN b.statusID = 111 THEN 0 ELSE 1 END)
	 

FROM bettrans b with(nolock, index(IX_recommend_transid))   
	INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid and b.recommend=c.recommend
WHERE winlostdate = @date		
	AND bettype < 19999	
	AND StatusID not in (101, 102, 103, 121, 1)  
    --and status not in ('VOID', 'REJECT', 'REFUND','DONE') and 'waiting'      
GROUP BY b.custid,c.username,
	CASE
	    WHEN bettype IN (71,72) THEN 251 --casino
		WHEN bettype = 1000 THEN 253 --games
		WHEN bettype IN (31,32,33,41,42,43) THEN 151 -- Horse Racing
		WHEN bettype BETWEEN 81 AND 120 THEN 161 -- Number Game 
		WHEN bettype BETWEEN 1101 AND 1199 THEN 162 -- Live Casino
		WHEN bettype BETWEEN 1201 AND 1299 THEN 180 --Virtual Sport	
		WHEN bettype BETWEEN 51 AND 69 THEN 201	 -- Financial
		WHEN bettype BETWEEN 1501 AND 1599 THEN 202-- Keno  
		WHEN b.bettype<31 OR (b.bettype BETWEEN 121 AND 999) THEN 0 -- sportsbook 
	ELSE -1 END

end

else IF @Date >= @CutDate  
BEGIN  
    
    INSERT INTO #tmpRpt (  
		Winlostdate, CustID,Username,ProductID, Turnover, Outstanding, Winloss, DrawGame,PlayerComm,BetCount,TurnoverNoDraw,BetCountNoDraw
	)  
	SELECT   
		b.winlostdate  
		,b.CustID  
		,c.username  
		,b.Sporttype  
		,sum(b.turnover)  
		,0 as Outstanding
		,sum(b.winlost) 
		,sum(case when statusID = 111 then turnover else 0 end)  
		,sum(b.playercomm)
		,sum(b.BetCount)
		,SUM( case when (b.statusID = 112 OR b.statusID = 113) then turnover 
		           when (b.statusID = 114 OR b.statusID = 115) then turnover/2  
		    else 0 end )	
	    ,SUM(CASE WHEN b.statusID = 111 THEN 0 ELSE BetCount END) -- Betcount No Draw

	FROM bodb_licensee.dbo.rptLicWinloss2 b with(nolock)    
	     INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid and b.recommend=c.recommend and b.srecommend=c.srecommend  		
	WHERE b.winlostdate = @Date 
	 
		and b.BetCount>0
		and b.roleid=1
		and b.sporttype in (0,151,161,162,180,201,251,253,202)
		-- and b.isBA=0
		and StatusID not in (101, 102, 103, 121, 1)  

    GROUP BY b.winlostdate  
		,b.CustID  
		,c.username  
		,b.Sporttype
	
END  
  
else IF @Date < @CutDate  
BEGIN  
    
       
	  INSERT INTO #tmpRpt (  
		Winlostdate, CustID,Username,ProductID, Turnover, Outstanding, Winloss, DrawGame,PlayerComm,BetCount,TurnoverNoDraw,BetCountNoDraw
	)  
	SELECT   
		b.winlostdate  
		,b.CustID  
		,c.username  
		,b.Sporttype  
		,sum(b.turnover)  
		,0 as Outstanding
		,sum(b.winlost) 
		,sum(case when statusID = 111 then turnover else 0 end)  
		,sum(b.playercomm)
		,sum(b.BetCount)
		,SUM( case when (b.statusID = 112 OR b.statusID = 113) then turnover 
		           when (b.statusID = 114 OR b.statusID = 115) then turnover/2  
		    else 0 end )	
	,SUM(CASE WHEN b.statusID = 111 THEN 0 ELSE BetCount END) -- Betcount No Draw

	FROM bodb_licensee.dbo.rptLicWinloss_old b with(nolock)    
	     inner join #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid and b.recommend=c.recommend and b.srecommend=c.srecommend  		
	WHERE b.winlostdate = @Date 
	 
		and b.BetCount>0
		and b.roleid=1
		and b.sporttype in (0,151,161,162,180,201,251,253,202)
		-- and b.isBA=0
		and StatusID not in (101, 102, 103, 121, 1)  

    GROUP BY b.winlostdate  
		,b.CustID  
		,c.username  
		,b.Sporttype

   

END   


SELECT * FROM #tmpRpt b with (nolock)  
  
DROP TABLE  #tmpRpt
DROP table #LicenseeCust 
  
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnteam] AS [dbo]
  
