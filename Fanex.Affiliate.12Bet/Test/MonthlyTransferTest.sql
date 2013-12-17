/*DungTest*/
 SET NOCOUNT ON
declare @Month int, 
		@Year int
select @Month=05,@Year=2012
Declare @FirstDay smalldatetime,@LastDay smalldatetime


Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))

print @FirstDay
print  @LastDay

exec Task_Aff_GroupSettingBackup @Month , @Year

---Delete all transfer from this month if exists

delete from  AffCommission 
where WinlostDate=@LastDay
delete from AffTrans 
where TransType=201 and Transdate=@LastDay	
		
--SB/ Casino  QMs: (159)/(20)

exec Task_Aff_MonthlyTransfer @Month,@Year


select * from AffCommission(nolock) where Winlostdate=@LastDay
Select * from AffTrans (nolock) where TransType in (201,204) and TransDate=@LastDay

/*
/*DungTest*/
 SET NOCOUNT ON
declare @AffID int,
		 @Month int, 
		@Year int
select @AffID=10023,@Month=06,@Year=2013
Declare @FirstDay smalldatetime,@LastDay smalldatetime


Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))

print @FirstDay
print  @LastDay

--exec Task_Aff_GroupSettingBackup @Month , @Year

---Delete all transfer from this month if exists

delete from  AffCommission 
where WinlostDate=@LastDay and AffID=@AffID
delete from AffTrans 
where TransType=201 and Transdate=@LastDay and AffID=@AffID	
		
--SB/ Casino  QMs: (159)/(20)

exec Task_Aff_MonthlyTransferForAff @AffID,@Month,@Year


select * from AffCommission(nolock) where Winlostdate=@LastDay and AffID=@AffID
Select * from AffTrans (nolock) where TransType in (201,204) and TransDate=@LastDay and AffID=@AffID




*/