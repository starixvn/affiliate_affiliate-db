ALTER PROCEDURE [dbo].[Aff_PlayersWinlostByProductSel]  
	@Xml xml,
	@Prefix varchar(100),
	@Date   SMALLDATETIME   
AS   
/*  
Created: 20130111@Peter  
Task :   
DB: DB06.bodb02  
  
  
Revisions:  
  
Param's Explanation:  
  
   
*/  

SET NOCOUNT ON
  
select @Date=dateadd(dd, datediff(dd,0, @DATE), 0)
     
create table #LicenseeCust ( custID INT PRIMARY KEY,currency int,username varchar(100))  
DECLARE @CutDate datetime  
  
SELECT @CutDate =  min(winlostdate)   
FROM bodb_report.dbo.rptdepwinlost with(nolock)    
  
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
	BetCount int  
 )   
  
  
  DECLARE @TempTrans TABLE(
	UserName varchar(30))

insert into @TempTrans --Convert xml to table
Select	[Table].[Column].value('./@username', 'varchar(30)') as UserName
	from @Xml.nodes('/root/trans') as [Table]([Column])

--print @sqlCommand


INSERT INTO #LicenseeCust  

Select c.CustID,c.Currency,t.UserName  
from bodb02.dbo.customer c with(nolock) 
inner join @TempTrans as t on  @Prefix + t.username=c.username2
where c.roleid=1

if DATEDIFF(d,@Date,CURRENT_TIMESTAMP)<=1
begin
    INSERT INTO #tmpRpt (  
		Winlostdate, CustID,Username,ProductID, Turnover, Outstanding, Winloss, DrawGame,PlayerComm,BetCount
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
	ELSE 0 END, -- ProductID

	SUM(		
		case when b.liveawayscore = 0 and b.bettype IN(33,43) then ABS(b.stake/2) else ABS(b.stake) end		 
		),--Turnover  
    SUM(CASE WHEN  ruben=0 then actual_stake ELSE 0 END),	--Outstanding  
	SUM(CASE WHEN ruben=1 then b.winlost-b.actual_stake ELSE 0 END), --Winloss      
	SUM(case when [status] = 'DRAW' then stake else 0 end), -- Draw game TO
	SUM(CASE WHEN ruben=1 then b.playercomm ELSE 0 END), --Playercomm      
	COUNT(1)  --betcount
	/*--114: half win, 115: half lose
	CASE 
		WHEN bettrans.statusID = 112 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 114 
		WHEN bettrans.statusID = 113 AND bettrans.bettype IN(1,3,7,8,17,18) AND ABS(modds) = 0.25 THEN 115
		ELSE bettrans.statusID END AS statusID,*/
	
FROM bettrans b with(rowlock)   
inner join #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid 
WHERE winlostdate = @date	
	and bettype < 19999	
	and StatusID not in (101, 102, 103, 121, 1)  
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
	ELSE 0 END

end

else IF @Date < @CutDate  
BEGIN    
    INSERT INTO #tmpRpt (  
		Winlostdate, CustID,Username,ProductID, Turnover, Outstanding, Winloss, DrawGame,PlayerComm,BetCount
	)  
	SELECT   
		b.winlostdate  
		,b.CustID  
		,c.username  
		,b.Sporttype  
		,isnull(b.turnover,0)  
		,isnull(b.Outstanding,0)  
		,isnull(b.winlost,0) 
		,isnull(b.drawTO,0)  
		,isnull(b.playercomm,0)
		,isnull(b.BetCount,0)
	FROM bodb_report.dbo.rptDepWinlostByProduct_bk b with(nolock)    
	     inner join #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  		
	WHERE b.winlostdate = @Date 
		and b.BetCount>0
    
	
END  
  
else IF @Date >= @CutDate  
BEGIN  
       
	INSERT INTO #tmpRpt (  
		Winlostdate, CustID,Username,ProductID, Turnover, Outstanding, Winloss, DrawGame,PlayerComm,BetCount
	)  
	SELECT   
		b.winlostdate  
		,b.CustID  
		,c.username  
		,b.Sporttype  
		,isnull(b.turnover,0)
		,isnull(b.Outstanding,0)
		,isnull(b.winlost,0)
		,isnull(b.drawTO,0)  
		,isnull(b.playercomm,0)
		,isnull(b.BetCount,0)
	FROM bodb_report.dbo.rptDepWinlostByProduct b with(nolock)    
	     inner join #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  		
	WHERE b.winlostdate = @Date 
		and b.BetCount>0
   

END   


SELECT  
 *  
FROM #tmpRpt b   
  
DROP TABLE  #tmpRpt
DROP table #LicenseeCust 


  

  
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnTeam]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersWinlostByProductSel] TO [vnTeam]