ALTER  PROCEDURE [dbo].[AffAdmin_CommGroupAssign]  
 @UserId int,  
 @GroupId int,  
 @AffIDList nvarchar(4000),      
 @IP varchar(20),      
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT,  
 @RefNo bigint = null OUTPUT  
AS  
/*  
Created: 20090719@DungTong  
Task : Assign a commission group (GroupID<1000) for multiple Affilites   
DB: DB052.Affiliate_AoncashUAT
Original:  
  
Revisions:  
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID separated by comma.Maximum of 200 AffIDs are assiged each time                  
.@IP : IP of admin user               
.@ErrCode:    
              0 : no error raised  
              >0 : there was an error  
.@ErrMsg :     
              empty: no error raised  
              others : the error message detail                            
                            
*/  
SET NOCOUNT ON  
--Check permission  
/*EXEC [dbo].[Aff_Con_CheckPermission]  
     @custid=@UserID,@funcname='Affiliate',  
     @System = 'AFFILIATE',  
     @ErrCode=@ErrCode output,  
     @ErrMsg=@ErrMsg output  

If @ErrCode <> 0
    RETURN 
*/

Declare @AffId int
DECLARE @AffCurrency TABLE (AffID INT, Currency INT);  
  
--currency checking
INSERT INTO @AffCurrency(AffID, Currency)
SELECT DISTINCT AffID, Currency
FROM dbo.AffInfo WITH(NOLOCK)
WHERE AffID IN (SELECT cast(val AS INT) AS AffID
                    FROM dbo.strsplit(@AffIDList, ',')) 

SELECT @AffId = AffID
FROM @AffCurrency  
  
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
  
   
if(@ErrMsg<>'')  
  return  
  
IF (NOT EXISTS (
            SELECT 1
            FROM dbo.CommGroup WITH(NOLOCK)
            WHERE GroupID = @GroupID 
                AND IsDeleted = 0
                AND (@GroupId = 102 
                        OR Currency = ISNULL((SELECT TOP 1 Currency FROM @AffCurrency), Currency) 
                )
        )
    )
BEGIN
    SELECT @ErrCode = 601

    RETURN
END
  
  
--Check AffIDList  
/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/  
declare @NoAff int, @CountCurrency int  
BEGIN TRY  
    select @NoAff=sum(1)  
 from AffInfo with(nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
   and status='approved' -- and IsClosed=0  
      
 if(@NoAff<> (select sum(1) from dbo.strsplit(@AffIDList, ',')))  
 begin  
  select @ErrCode=602
  return  
 end   
  
 --Check Currency of Group and Currency of Match   
 Set @CountCurrency=0  
 Select @CountCurrency=count(distinct currency)  
 from AffInfo (nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
    
 if(isnull(@CountCurrency,0) > 1)  
 begin  
  Select @ErrCode=604
  return  
 end  
  
ENd TRY  
BEGIN CATCH  
 select @ErrCode=603
    return  
END CATCH  
  
  
--BEGIN TRANSACTION AFTER CHECKING VALID INPUT DATA  
BEGIN TRANSACTION    
  --Delete GroupID>1000 where GroupID in AffiliateID list and already assigned before  
  Delete DeductionSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ','))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrCode=605  
     return   
   end  
     
  Delete GroupSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ','))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrCode=606  
     return   
   end   
    
  Delete CommGroup     
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ','))         
                       and AffID=GroupID  
    )   
        
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrCode=607  
     return   
   end  
  
  Update AffInfo with (rowlock,updlock)  
  set GroupID=@GroupID        
  where AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ','))         
  
  -- Update MemberDaily, AffDaily, AffDailySummary
  
  Declare @SportsBookID tinyint

select @SportsBookID = dbo.Aff_GetSportID('SportsBook') 	


--Update MemberDaily PSP, Marketting fee,...
Update m
set PSP = ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent) * isnull(dbo.Aff_GetDeductionPercent(m.AffID,@SportsBookID,'PSP',NULL),0)  ),
	Marketing = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Marketing',NULL),0),
	MemOddsFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Odds Fee',NULL),0),
	MemPLayTechFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'PlayTech Royalties', NULL),0),
	MemWinlostFake = -(-Winlost  
						   - ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent))* isnull(dbo.Aff_GetDeductionPercent(m.AffID,@SportsBookID,'PSP',NULL),0)  
						   -  abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Marketing', NULL),0)  
						   - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Odds Fee', NULL),0)  
						   - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'PlayTech Royalties', NULL),0)  
						)
from MemberDaily as m with (rowlock,updlock)
   
	inner join Exchange as e (nolock) on m.Currency = e.ExchangeId

where datediff(m, m.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND m.AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ','))

/*
CREATE TABLE #MemberDailySum (AffID int, MemCurrency int,Winlostdate smalldatetine, ProductID tinyint,SysExRate float, AffExRate float, MemMarketing money, MemPSP money,
                               MemWinlostFake money, MemOddsFee money, MemPlayTechFee money)*/

	
	SELECT m.[AffID]
		,m.[Currency] AS [MemCurrency]
		,m.[WinlostDate]
		,m.[ProductID]
		,m.[SysExRate]
		,m.AffExRate
		,Sum(Marketing) AS MemMarketing
		,Sum(PSP) AS MemPSP
		,Sum(MemWinlostFake) AS MemWinlostFake
		,Sum(MemOddsFee) AS MemOddsFee
		,Sum(MemPLayTechFee) AS MemPLayTechFee
	INTO #MemberDailySum
	FROM MemberDaily(NOLOCK) AS m
	
	WHERE datediff(m, m.WinlostDate, CURRENT_TIMESTAMP) = 0
		 AND m.AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ','))
	GROUP BY m.AffID
		,m.Currency
		,m.Winlostdate
		,m.ProductID
		,m.[SysExRate]
		,m.[AffExRate]

	--Update AffDaily
	UPDATE ad
	SET ad.MemMarketing = md.MemMarketing
		,ad.MemPSP = md.MemPSP
		,ad.MemOddsFee=md.MemOddsFee
		, ad.MemPLayTechFee=md.MemPlayTechFee  
	FROM AffDaily ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #MemberDailySum md (nolock)
		ON ad.AffID = md.AffId
			AND ad.MemCurrency = md.MemCurrency
			AND ad.Winlostdate = md.Winlostdate
			AND ad.ProductID = md.ProductID
			
			
update ad    
set 
	HouseNetWinLost=HouseWinLost  
		 - isnull(MemBonus,0) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Bonus',Winlostdate),0))     
		 -isnull(MemAdjustment,0)  * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Adjustment',Winlostdate),0))  
		 - abs(isnull(MemWinlost,0)) * (1- isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Marketing',Winlostdate),0))  
		 - abs(isnull(MemWinlost,0)) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Odds Fee',Winlostdate),0))
		 - abs(isnull(MemWinlost,0)) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'PlayTech Royalties',Winlostdate),0)) 
From  AffDaily  ad with (rowlock,updlock)		
 
	WHERE datediff(m, ad.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ad.AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ','))
		  

--AffDailySummary

	UPDATE ad
	SET ad.MemMarketing = tmp.MemMarketing
		,ad.MemPSP = tmp.MemPSP
		,ad.MemOddsFee=tmp.MemOddsFee
		, ad.MemPLayTechFee=tmp.MemPlayTechFee  
	FROM AffDaily ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN 
		
		( Select md.AffID, md.Winlostdate,md.ProductID,
		         Sum(MemMarketing)* SysExRate as MemMarketing,
		         Sum(MemMarketing)* AffExRate as MemMarketing_aff, 
		         Sum(MemPSP)* SysExRate as MemPSP,
		         Sum(MemPSP)* AffExRate as MemPSP_aff,
		         Sum(MemOddsFee)* SysExRate as MemOddsFee,
		         Sum(MemOddsFee)* AffExRate as MemOddsFee_aff,
		         Sum(MemPlayTechFee)* SysExRate as MemPlayTechFee,
		         Sum(MemPlayTechFee)* AffExRate as MemPlayTechFee_aff
		From #MemberDailySum md (nolock)
		Group by md.AffID,md.Winlostdate, md.SysExRate,md.AffExRate, md.ProductID
		
		) tmp on tmp.AffID=ad.AffID and tmp.Winlostdate=ad.Winlostdate and tmp.ProductID=ad.ProductID
		
update ad    
set 
	HouseNetWinLost=HouseWinLost  
		 - isnull(MemBonus,0) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Bonus',Winlostdate),0))     
		 -isnull(MemAdjustment,0)  * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Adjustment',Winlostdate),0))  
		 - abs(isnull(MemWinlost,0)) * (1- isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Marketing',Winlostdate),0))  
		 - abs(isnull(MemWinlost,0)) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Odds Fee',Winlostdate),0))
		 - abs(isnull(MemWinlost,0)) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'PlayTech Royalties',Winlostdate),0)),
	HouseNetWinLost_aff=HouseWinLost_aff  
		 - isnull(MemBonus_aff,0) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Bonus',Winlostdate),0))     
		 -isnull(MemAdjustment_aff,0)  * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Adjustment',Winlostdate),0))  
		 - abs(isnull(MemWinlost_aff,0)) * (1- isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Marketing',Winlostdate),0))  
		 - abs(isnull(MemWinlost_aff,0)) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'Odds Fee',Winlostdate),0))
		 - abs(isnull(MemWinlost_aff,0)) * (1-isnull(dbo.Aff_GetDeductionPercent(ad.AffID,ProductID,'PlayTech Royalties',Winlostdate),0))	  
From  AffDailySummary  ad with (rowlock,updlock)		

	WHERE datediff(m, ad.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ad.AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ','))
		  	
		
			
	DROP TABLE #MemberDailySum;
	
     
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrCode=608  
     return   
   end  
          
commit transaction  
 --Write the log   
DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
if ((select count(1) from dbo.strsplit(@AffIDList, ','))=1)  
  select @AffID=cast(@AffIDList as int)  
else  
  select @AffID=0     
SELECT @LogData = N'Assign a common commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
                  + '\n AffIDList=' + dbo.Aff_ToString(@AffIDList)     
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'CommissionGroup',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @RefNo = @RefNo OUTPUT,   
 @Details=@LogData

GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupAssign] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupDel] TO [vnteam]

