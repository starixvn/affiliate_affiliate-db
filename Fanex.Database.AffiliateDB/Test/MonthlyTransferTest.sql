declare @Month int, 
	@Year int, @FirstDay smalldatetime,@LastDay smalldatetime,@TransType int
select @Month=3,@Year=2013,
       @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime),
      @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0)),
	  @TransType = 201

delete CommGroupHistory where   monthdate=@LastDay
delete GroupSettingHistory  where monthdate=@LastDay
delete DeductionSettingHistory  where monthdate=@LastDay
delete AffGroupHistory  where monthdate=@LastDay

delete AffCommission  where winlostdate=@LastDay

delete AffTrans where transtype=@TransType and TransDate=@LastDay

exec [dbo].[Task_Aff_GroupSettingBackup]
	@Month=@Month , 
	@Year =@Year



exec [dbo].[Task_Aff_MonthlyTransfer]
	@Month=@Month , 
	@Year =@Year



select * from AffCommission (nolock) where winlostdate=@LastDay

select * from AffTrans(nolock) where transtype=@TransType and TransDate=@LastDay


---- FIX ISSUE OF NET WINLOST
/*


   update ad 
     set 
        ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),
        ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),
        ad.AffNetWinlost=( -isnull(ad.MemWinlost,0) 
                            - Cast(isnull(a.HasPSP,0) as int)* isnull(ad.MemPSP,0)* dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'PSP',a.Winlostdate)
							-Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Odds Fee',a.Winlostdate)
							-Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Marketing',a.Winlostdate)                 
							- Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)* dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Bonus',a.Winlostdate)
							
                       
                       ) * isnull(a.commission,0),
                       
       ad.HouseNetWinlost= (-isnull(ad.MemWinlost,0) 
                            - Cast(isnull(a.HasPSP,0) as int)* isnull(ad.MemPSP,0)* dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'PSP',a.Winlostdate)
							-Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Odds Fee',a.Winlostdate)
							-Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Marketing',a.Winlostdate)
							- Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)* dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Bonus',a.Winlostdate)
							
                           ) * (1-isnull(a.commission,0)) 
                
      from AffDaily ad with (rowlock,updlock)  
      inner join AffCommission a with (nolock) on a.AffID=ad.AffID and a.ProductID=ad.ProductID     
   where datediff (mm,ad.Winlostdate, a.Winlostdate)=0  
   
   update ad 
     set ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),
        ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),
        ad.AffNetWinlost=( -isnull(ad.MemWinlost,0) 
                            - Cast(isnull(a.HasPSP,0) as int)* isnull(ad.MemPSP,0)*dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'PSP',a.Winlostdate)
							-Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Odds Fee',a.Winlostdate)
							-Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Marketing',a.Winlostdate)                 
							- Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)* dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Bonus',a.Winlostdate)
							
                       
                       ) * isnull(a.commission,0),
                       
       ad.HouseNetWinlost= (-isnull(ad.MemWinlost,0) 
                            - Cast(isnull(a.HasPSP,0) as int)* isnull(ad.MemPSP,0)* dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'PSP',a.Winlostdate)
							-Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Odds Fee',a.Winlostdate) 
							-Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Marketing',a.Winlostdate)                 
							- Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Bonus',a.Winlostdate)							
                           ) * (1-isnull(a.commission,0)), 

	    ad.AffWinlost_aff = -isnull(ad.MemWinlost_aff,0) *  isnull(a.commission,0),
        ad.HouseWinlost_aff=-isnull(ad.MemWinlost_aff,0) * (1-isnull(a.commission,0)),
        ad.AffNetWinlost_aff=( -isnull(ad.MemWinlost_aff,0) 
                            - Cast(isnull(a.HasPSP,0) as int)* isnull(ad.MemPSP_aff,0)*dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'PSP',a.Winlostdate)
							-Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost_aff,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Odds Fee',a.Winlostdate)
							-Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost_aff,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Marketing',a.Winlostdate)                 
							- Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus_aff,0)*dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Bonus',a.Winlostdate)

                       
                       ) * isnull(a.commission,0),
                       
       ad.HouseNetWinlost_aff= (-isnull(ad.MemWinlost_aff,0) 
                            - Cast(isnull(a.HasPSP,0) as int)* isnull(ad.MemPSP_aff,0)*dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'PSP',a.Winlostdate)
							-Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost_aff,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Odds Fee',a.Winlostdate)
							-Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost_aff,0)) * dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Marketing',a.Winlostdate)                 
							- Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus_aff,0)* dbo.Aff_GetDeductionPercent(a.AffID,a.ProductID,'Bonus',a.Winlostdate)							
                           ) * (1-isnull(a.commission,0)) 
                
      from AffDailySummary ad with (rowlock,updlock)  
      inner join AffCommission a with (nolock) on a.AffID=ad.AffID and a.ProductID=ad.ProductID     
   where datediff (mm,ad.Winlostdate, a.Winlostdate)=0  
*/