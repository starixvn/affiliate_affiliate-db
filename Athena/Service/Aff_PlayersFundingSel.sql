/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_PlayersFundingSel]  
	@Xml xml,	
	@Prefix varchar(100),
	@Date   SMALLDATETIME  
AS   
/*  
	Created: 20130111@Peter  
	Task : Report Turn Over  
	DB: DB06.bodb02    
  
	Revisions:  
		20220106@Malcolm: Split transfer 
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
	CustID int,
	username varchar(100),  
	Currency INT,  	
	Deposit MONEY,  
	Withdrawal MONEY,  
	AffiliateTransfer MONEY,  
	Bonus MONEY,  
	Adjustment MONEY,  	
	Transfer3rd MONEY  
 )   
 
DECLARE @TempTrans TABLE(
	UserName varchar(30))

insert into @TempTrans --Convert xml to table
Select	[Table].[Column].value('./@username', 'varchar(30)') as UserName
from @Xml.nodes('/root/trans') as [Table]([Column])


INSERT INTO #LicenseeCust  

Select c.CustID,c.Currency,t.UserName  
from bodb02.dbo.customer c with(nolock) 
inner join @TempTrans as t on  @Prefix + t.username=c.username2
where c.roleid=1


DECLARE @maxdate_SUM SMALLDATETIME  
SELECT @maxdate_SUM =  MAX(winlostdate) from bodb_report.dbo.rptdepwinlost with(nolock)   

if DATEDIFF(d,@Date,CURRENT_TIMESTAMP) <=1
begin
   INSERT INTO #tmpRpt (  
						Winlostdate ,  
						CustID ,
						username ,  
						Currency ,  						
						Deposit ,  
						Withdrawal ,  
						AffiliateTransfer ,  
						Bonus ,  
						Adjustment,
						Transfer3rd   
						)  
    select @Date,b.CustID,c.username,b.currency,
	      SUM( CASE WHEN bettype = 22001 then winlost-actual_stake ELSE 0 END), --Deposit  
		  -SUM(CASE WHEN bettype in (22002,22003) then winlost-actual_stake ELSE 0 END),--Withdrawal  
		  SUM( CASE WHEN bettype = 21006 then winlost-actual_stake ELSE 0 END), --Aff2MemTransfer  
		  SUM( CASE WHEN bettype = 22004 then winlost-actual_stake ELSE 0 END),--Bonus  
		  SUM( CASE WHEN bettype in (21001, 21002, 21003, 21004, 21005, 22005) then winlost-actual_stake ELSE 0 END), --Adjustment  
		  SUM( CASE WHEN bettype in (22006,22007) then winlost-actual_stake ELSE 0 END)--Transfer3rd  
	FROM bodb02.dbo.Transfer b with(nolock)    
	inner join #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  	
	WHERE b.winlostdate = @Date  		
	      and b.custid > 0 
		  and b.bettype in (22001,22002,22003,22004, 22005,22006,22007,21001, 21002, 21003, 21004, 21005,21006) 
		  
    group by b.CustID,c.username,b.currency	   
end  
else IF @Date < @CutDate  
BEGIN    
	INSERT INTO #tmpRpt (  
						Winlostdate ,  
						CustID ,
						username ,  
						Currency ,  						
						Deposit ,  
						Withdrawal ,  
						AffiliateTransfer ,  
						Bonus ,  
						Adjustment,
						Transfer3rd   
					)  
	SELECT   
		b.winlostdate  
		,b.CustID
		,c.Username
		,b.currency  
		,isnull(b.deposit,0)  
		,isnull(b.withdrawal,0)  
		,isnull(b.Aff2MemTransfer,0) 
		,isnull(b.Bonus,0)  
		,isnull(b.Adjustment,0)  
		,isnull(b.Transfer3rd,0)  
	FROM bodb_Report.dbo.rptDepWinlost_bk b with(nolock)    
	    inner join #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  	
	WHERE b.winlostdate = @Date  		
		and (isnull(b.deposit, 0) <> 0 or isnull(b.withdrawal, 0) <> 0 or isnull(b.Bonus, 0) <> 0 or isnull(b.Adjustment, 0) <> 0)
END  
  
else IF @Date >= @CutDate  
BEGIN  
	INSERT INTO #tmpRpt (  
						Winlostdate ,  
						CustID ,
						username ,  
						Currency ,  						
						Deposit ,  
						Withdrawal ,  
						AffiliateTransfer ,  
						Bonus ,  
						Adjustment,
						Transfer3rd   
					)  
	SELECT   
		b.winlostdate  
		,b.CustID
		,c.Username
		,b.currency  
		,isnull(b.deposit,0)  
		,isnull(b.withdrawal,0)  
		,isnull(b.Aff2MemTransfer,0) 
		,isnull(b.Bonus,0)  
		,isnull(b.Adjustment,0)  
		,isnull(b.Transfer3rd,0)  
	FROM bodb_report.dbo.rptdepwinlost b with(nolock)     
	     inner join #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  	
	WHERE b.winlostdate  = @Date  		
		and (isnull(b.deposit, 0) <> 0 or isnull(b.withdrawal, 0) <> 0 or isnull(b.Bonus, 0) <> 0 or isnull(b.Adjustment, 0) <> 0)
END   
   
SELECT  
	b.winlostdate,  
	b.CustID,  
	b.Username,  
	e.Currency AS Currency,  
	b.deposit,  
	b.withdrawal,  
	b.AffiliateTransfer ,  
	b.bonus,  
	b.adjustment,
	b.Transfer3rd  
FROM #tmpRpt b   	
	INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON b.currency = e.exchangeid  
  
DROP TABLE  #tmpRpt 
DROP table #LicenseeCust 

GO


