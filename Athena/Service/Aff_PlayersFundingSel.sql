/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_PlayersFundingSel]  
	@Xml	XML,	
	@Prefix VARCHAR(100),
	@Date   SMALLDATETIME  
AS   
/*  
	Created: 20130111@Peter  
	Task : Report Turn Over  
	DB: DBACC.bodb02    
  
	Revisions:  
		- 20130111@Peter: Initialize SP 
		- 20211222@Malcolm: Split transfer out of bettrans [RedmineID: #165095] 
	Param's Explanation:  
  
*/  
BEGIN
	SET NOCOUNT ON  
     
	SELECT @Date = DATEADD(dd, DATEDIFF(dd,0, @DATE), 0)     
     
	CREATE TABLE #LicenseeCust (custID INT PRIMARY KEY,currency INT,username VARCHAR(100))  
	DECLARE @CutDate DATETIME  
  
	SELECT @CutDate =  MIN(winlostdate)   
	FROM bodb_report.dbo.rptdepwinlost WITH(NOLOCK)    
  
	CREATE TABLE #tmpRpt 
	(  
		Winlostdate			SMALLDATETIME,  
		CustID				INT,
		username			VARCHAR(100),  
		Currency			INT,  	
		Deposit				MONEY,  
		Withdrawal			MONEY,  
		AffiliateTransfer	MONEY,  
		Bonus				MONEY,  
		Adjustment			MONEY,  	
		Transfer3rd			MONEY  
	 )   
 
	DECLARE @TempTrans TABLE(UserName VARCHAR(30))

	INSERT INTO @TempTrans --Convert xml to table
	SELECT	[Table].[Column].value('./@username', 'varchar(30)') AS UserName
	FROM @Xml.nodes('/root/trans') AS [Table]([Column])


	INSERT INTO #LicenseeCust  

	SELECT c.CustID,c.Currency,t.UserName  
	FROM bodb02.dbo.customer c WITH(NOLOCK) 
		INNER JOIN @TempTrans AS t ON  @Prefix + t.username=c.username2
	WHERE c.roleid = 1


	DECLARE @maxdate_SUM SMALLDATETIME  
	SELECT @maxdate_SUM =  MAX(winlostdate) FROM bodb_report.dbo.rptdepwinlost WITH(NOLOCK)   

	IF DATEDIFF(d,@Date,CURRENT_TIMESTAMP) <=1
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
		SELECT @Date,b.CustID,c.username,b.currency,
			  SUM( CASE WHEN bettype = 22001 THEN winlost-actual_stake ELSE 0 END), --Deposit  
			  -SUM(CASE WHEN bettype IN (22002,22003) THEN winlost-actual_stake ELSE 0 END),--Withdrawal  
			  SUM( CASE WHEN bettype = 21006 THEN winlost-actual_stake ELSE 0 END), --Aff2MemTransfer  
			  SUM( CASE WHEN bettype = 22004 THEN winlost-actual_stake ELSE 0 END),--Bonus  
			  SUM( CASE WHEN bettype IN (21001, 21002, 21003, 21004, 21005, 22005) THEN winlost-actual_stake ELSE 0 END), --Adjustment  
			  SUM( CASE WHEN bettype IN (22006,22007) THEN winlost-actual_stake ELSE 0 END)--Transfer3rd  
		FROM bodb02.dbo.Transfer b WITH(NOLOCK)    
			INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  	
		WHERE b.winlostdate = @Date  		
			  AND b.custid > 0 
			  AND b.bettype IN (22001,22002,22003,22004, 22005,22006,22007,21001, 21002, 21003, 21004, 21005,21006) 
		  
		GROUP BY b.CustID,c.username,b.currency	   
	END  
	ELSE IF @Date < @CutDate  
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
			,ISNULL(b.deposit,0)  
			,ISNULL(b.withdrawal,0)  
			,ISNULL(b.Aff2MemTransfer,0) 
			,ISNULL(b.Bonus,0)  
			,ISNULL(b.Adjustment,0)  
			,ISNULL(b.Transfer3rd,0)  
		FROM bodb_Report.dbo.rptDepWinlost_bk b WITH(NOLOCK)    
			INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  	
		WHERE b.winlostdate = @Date  		
			AND (ISNULL(b.deposit, 0) <> 0 OR ISNULL(b.withdrawal, 0) <> 0 OR ISNULL(b.Bonus, 0) <> 0 OR ISNULL(b.Adjustment, 0) <> 0)
	END  

	ELSE IF @Date >= @CutDate  
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
			,ISNULL(b.deposit,0)  
			,ISNULL(b.withdrawal,0)  
			,ISNULL(b.Aff2MemTransfer,0) 
			,ISNULL(b.Bonus,0)  
			,ISNULL(b.Adjustment,0)  
			,ISNULL(b.Transfer3rd,0)  
		FROM bodb_report.dbo.rptdepwinlost b WITH(NOLOCK)     
			 INNER JOIN #LicenseeCust c WITH (NOLOCK) ON b.custid=c.custid  	
		WHERE b.winlostdate  = @Date  		
			AND (ISNULL(b.deposit, 0) <> 0 OR ISNULL(b.withdrawal, 0) <> 0 OR ISNULL(b.Bonus, 0) <> 0 OR ISNULL(b.Adjustment, 0) <> 0)
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
END
GO


