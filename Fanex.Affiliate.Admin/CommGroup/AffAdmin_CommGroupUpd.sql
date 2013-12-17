-- =============================================
-- Script Template
-- =============================================

ALTER Procedure [dbo].[AffAdmin_CommGroupUpd]  
 @UserId int,  
 @GroupId int,  
 @Currency int,  
 @QualifiedAmount money,  
 @GroupName nvarchar(100),  
 @Description nvarchar(100)  = null,  
 @ProductIDList varchar(MAX),  
 @DeductionList varchar(MAX) = null,  
 @DeductedPercentageList varchar(MAX) = null,  
 @TierList varchar(MAX),  
 @MinAmountList varchar(MAX),  
 @MaxAmountList varchar(MAX),  
 @MinQMList varchar(MAX),  
 @MaxQMList varchar(MAX),  
 @CommissionList varchar(MAX),  
 @IP varchar(20),  
 @Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT   
AS  
/*  
Created: 20090719@DungTong  
Task : update an existing Commission Group  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
	- 20131121@Joseph: allow updating currency 'All'
Parameters:  
.@UserID : Administrator user id  
.@GroupID : if @GroupID=-1 (normal group)  
            if @GroupID>1000 ==> Special Setting for Affiliate that has AffID=@GroupID  
 .@GroupName The name of this Group  
 .@Description : description for this group  
 .@ProductIDList: list of ProductID separated by semi colon  
                1 : SportsBook  
                2 : Casino  
                Ex: 1;2        
 .@DeductionList: List of Deduction Setting for above Sport List.                     
                  each deduction separated by a comma                    
                  1 : HasPSP  
                  2 : HasBonus  
                  3 : Has Adjustment  
                  4 : Has Marketing  
                  5 : Has Bonus for Casino  
                  6 : Has Adjustment for Casino  
                 Ex: 1,2,3,5,6  
                 Mean: SportsBook has deduction setting: HasPSP,HasBonus,Has Adjusment  
                      Casino has deduction setting: Has Bonus for Casino, Has Adjustment for Casino  
  .@DeductedPercentageList : List of Deducted Percentage  
              Ex: 1,0.05,1,0.17,1                                       
  . @TierList : List of number of Tiers for each sport type separated by a semi colon  
                each sport type separated by a semi colon  
                Ex: 3;4  
                Mean: SportsBook has 3 tiers  
                       Casino has 4 tiers  
   . @MinAmountList: List of MinAmount for each tier (all sports)  
                      each minAmount number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 0,1,100001;0,1,5001,700001  
    . @MaxAmountList: List of MaxAmount for each tier (all sports)  
                      each maxAmount number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 0,10000,100000000000000;0,5000,70000,100000000000000  
     . @MinQMList: List of MinQM for each tier (all sports)  
                      each minQM number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 0,10,20;0,5,10,21  
    . @MaxQMList: List of MaxQM for each tier (all sports)  
                      each maxQM number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 9,19,1000000000;4,9,20,1000000000  
     . @CommissionList: List of Commission for each tier (all sports)  
                         each commission number separated by a @  
                      for each sport type separated by a semi colon  
                  Ex: 0.00@0.20@0.35;0.00@0.10@0.15@0.20  
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
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@UserID,@funcname='[CommissionGroup]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
if(@ErrCode <> 0)  
  return 

--Check Currency Permission
if(@Currency = 0)
	begin 		
		if(not exists(SELECT 1 FROM AdminUser WHERE custid = @UserId and GroupID = 2))
			return
		
	end
else
	begin
		EXEC [dbo].[AffAdmin_CheckPermissionCurrency]
			@UserId = @UserID,
			@CurrencyId = @Currency,
			@ErrCode = @ErrCode output
		if(@ErrCode <> 0)  
			return   
	 end

if (not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
  select @ErrCode=33 --'The group ID ' +  cast(@GroupId as varchar(10)) + ' is not existed. Please check.' 		
    return  
  end  
  
if(@GroupName is null or LTRIM(RTRIM(@GroupName))='')  
  begin  
 select @ErrCode = 34 -- Group name is empty. Please choose a name!
		
 return  
 end  
  
   
if (@GroupID<1000 and exists (select 1 from CommGroup where GroupID<>@GroupID and  GroupName = @GroupName  and IsDeleted=0))  
begin  
 select @ErrCode = 35 --Group name existed. Please choose another name!

 return  
end  
  
--Check Currency Is different -> do not allow to update when have an Affiliate Assign to this group  
  
if(Exists (select 1 from CommGroup (nolock) where GroupID=@GroupID and currency<>@Currency)   
 and (Exists(select top(1) 1 from AffCommission(nolock) where GroupID=@GroupID)   
  or Exists(select top(1) 1 from AffInfo ai (nolock) where ai.GroupID=@GroupID)   
  )  
)  
  
begin  
 select @ErrCode = 36 --The group has been used. Cannot change the currency. Please check!
 return  
end  
  
declare @DeductionSetting table(GroupID int,DeductionID tinyint,DeductedPercentage float)  
declare @GroupSetting table(GroupID int,ProductID tinyint,TierID tinyint,MinAmount money,MaxAmount money,MinQM int,MaxQM int,Commission decimal(9,8))  
   
--Insert Deduction Setting  
if(len(@DeductionList)>0)  
begin  
 Insert into @DeductionSetting(GroupID,DeductionID,DeductedPercentage)  
 select @GroupID,cast(t.val as tinyint),cast(p.val as float)  
 from dbo.strsplit(@DeductionList, ',') t  
      inner join dbo.strsplit(@DeductedPercentageList, ',') p on p.rank=t.rank      
   inner join DeductionType d with (nolock) on d.DTypeID=cast(t.val as tinyint)   
  
 IF @@Rowcount<>(select count(1) from dbo.strsplit(@DeductionList, ',')) or @@ERROR <> 0  
 BEGIN  
    
  Select @ErrCode = 37  --Error! Invalid Deduction Setting!
  return  
 END  
end  
--Insert Tier Setting  
declare @rank int,@ProductID int,@NTier int, @i int, @MinQM int, @MaxQM int,@PreMaxQM int  
declare @MinAmountArr varchar(500),@MaxAmountArr varchar(500),@MinQMArr varchar(500),@MaxQMArr varchar(500),@CommissionArr varchar(500)  
declare @MinAmount money,@MaxAmount money,@PreMaxAmount money  
declare @Commission decimal(9,8),@PreCommission decimal(9,8)   
select @rank=min(rank) from dbo.strsplit(@ProductIDList, ';')          
if @rank is not null  
 begin  
   while @rank is not null  
    begin  
       BEGIN TRY  
        --Voi moi ProductID  
        select @ProductID=cast(val as tinyint) from dbo.strsplit(@ProductIDList, ';') where rank=@rank  
        select @NTier=cast(val as tinyint) from dbo.strsplit(@TierList, ';') where rank=@rank  
        select @MinAmountArr=val from dbo.strsplit(@MinAmountList, ';') where rank=@rank  
        select @MaxAmountArr=val from dbo.strsplit(@MaxAmountList, ';') where rank=@rank  
        select @MinQMArr=val from dbo.strsplit(@MinQMList, ';') where rank=@rank  
        select @MaxQMArr=val from dbo.strsplit(@MaxQMList, ';') where rank=@rank  
        select @CommissionArr=val from dbo.strsplit(@CommissionList, ';') where rank=@rank  
  
        select @i=1  
        if(@NTier<1)  
         begin               
         Select @ErrCode = 38  --Error! Invalid Tier List!
         return  
         end  
         if(@NTier>50)  
          begin  
             ROLLBACK TRANSACTION  
          Select @ErrCode = 39 --Oops, maximum of 50 tiers are allowed! 
          return  
       end  
            
        while @i<=@NTier  
        begin  
       --Voi moi Tier  
       if(@i<>1) --Store previous setting to compare with current setting  
       begin  
        select @PreMaxAmount=@MaxAmount,               
               @PreMaxQM=@MaxQM,  
               @PreCommission=@Commission  
         
       end  
  
       select @MinAmount=cast(val as money) from dbo.strsplit(@MinAmountArr, ',') where rank=@i  
       select @MaxAmount=cast(val as money) from dbo.strsplit(@MaxAmountArr, ',') where rank=@i  
       select @MinQM=cast(val as int) from dbo.strsplit(@MinQMArr, ',') where rank=@i  
       select @MaxQM=cast(val as int) from dbo.strsplit(@MaxQMArr, ',') where rank=@i  
       select @Commission=cast(val as decimal(9,8)) from dbo.strsplit(@CommissionArr, '@') where rank=@i  
                 
       /*Kiem tra du lieu la hop le :   
                + cac gia tri khong nho hon 0   
                + min < max  
                + min sau = max truoc + 1 (@i>1)  
                + Commission sau > Commission truoc va khong duoc lon hon 1  
                + Neu la tier cuoi cung thi hai gia tri max phai la vo cuc  
                + Cac gia tri min, max khong duoc lon hon vo cuc  
                + Vo Cuc(MaxAmount)= 100000000000000  
                + Vo Cuc(MaxQM) =1000000000   
         
       */         
        
  
        if(@MinAmount>=0 and @MaxAmount<=100000000000000 and @MinAmount<=@MaxAmount  
                           and @MinQM>=0 and @MaxQM<=1000000000 and @MinQM<=@MaxQM  
                           and (@Commission between 0 and 1)  
                           and (  
             case when (@i=1 and @i<@NTier) then 1  
                  when (@NTier>1 and @i=@NTier and @MaxQM=1000000000 and @MaxAmount=100000000000000 and @MinAmount=@PreMaxAmount + 1 and @MinQM=@PreMaxQM + 1 and @Commission>= @PreCommission) then 1  
                  when (@NTier=1 and @i=@NTier and @MaxQM=1000000000 and @MaxAmount=100000000000000 and @MinQM=0 and @MinAmount=0) then 1  
                  when (@i>1 and @i<@NTier and @MinAmount=@PreMaxAmount + 1 and @MinQM=@PreMaxQM + 1 and @Commission>= @PreCommission) then 1  
                  else 0  
              end          
                           )=1  
                              )            
           begin  
              --Insert du lieu   
              Insert into @GroupSetting(GroupID,ProductID,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)  
              values (@GroupID,@ProductID,@i,@MinAmount,@MaxAmount,@MinQM,@MaxQM,@Commission)  
        --Neu khong dong nao duoc insert thi thoat <=> @@ROWCOUNT<>1   
        if(@@ROWCOUNT<>1)  
        begin            
           Select @ErrCode = 40  --There was an error when inserting tier setting.
           return    
        end    
           end  
         else  
           begin          
        Select @ErrCode = 41  --Error! Invalid Setting Data
        return    
            end    
                 --Increase @i by 1   
                 select @i=@i + 1                                     
        end --end inner while  
            
        select @rank=min(rank) from dbo.strsplit(@ProductIDList, ';') where rank>@rank  
       END TRY  
       BEGIN CATCH        
      Select @ErrMsg = ERROR_MESSAGE(), @ErrCode = 10034  
      return   
       END CATCH  
       
    end --end outer while  
 end --end if  
else ---Invalid Setting Data  
  begin   
 Select @ErrCode = 42  -- Error! Invalid Setting Data (ProductIDList) !
 return   
  end      
  
--Checking again  
 if (not exists (select 1 from @GroupSetting))  
    begin  
       Select @ErrCode = 41  
 return   
    end  
--BEGIN TRANSACTIOn AFTER CHECKING VALID INPUT DATA  
BEGIN TRANSACTION    
  Update CommGroup with (rowlock,updlock)  
  set GroupName=@GroupName,   
      Description=@Description,  
   Currency=@Currency,  
   QualifiedAmount=@QualifiedAmount         
  where GroupID=@GroupID  
     
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrCode = 43  --There was an error when updating data.Please try again!
     return   
   end  
     
         
    delete DeductionSetting where GroupID=@GroupID  
      
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrCode = 43  
     return   
   end  
          
    insert into DeductionSetting(GroupID,DeductionID,DeductedPercentage)  
    select GroupID,DeductionID,DeductedPercentage from @DeductionSetting  
  
    if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrCode = 43  
     return   
   end   
     
   delete GroupSetting where GroupID=@GroupID  
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select 43  
     return   
   end  
   Insert into GroupSetting(GroupID,ProductID,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)  
   select GroupID,ProductID,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission  
   from @GroupSetting  
     
   if(@@ERROR <> 0 or @@ROWCOUNT<> (select count(1) from @GroupSetting))  
   begin  
        ROLLBACK TRANSACTION  
        Select 43  
     return   
   end  
        
          
commit transaction  
 --Write the log   
DECLARE @LogData nvarchar(max), @AffID int,@SPName varchar(100)  
if (@GroupID>1000)  
  select @AffID=@GroupID  
else  
  select @AffID=0    
SELECT @LogData = N'Update a commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
                  + '\n GroupName=' + @GroupName  
      + '\n Currency=' + dbo.Aff_ToString(@Currency)  
      + '\n QualifiedAmount=' + dbo.Aff_ToString(@QualifiedAmount)     
                  + '\n Description=' + @Description
                  + '\n ProductIDList=' + @ProductIDList
                  + '\n DeductionList=' + @DeductionList
                  + '\n DeductedPercentageList=' + @DeductedPercentageList
                  + '\n TierList=' + @TierList
                  + '\n MinAmountList=' + @MinAmountList  
                  + '\n MaxAmountList=' + @MaxAmountList
                  + '\n MinQMList=' + @MinQMList
                  + '\n MaxQMList=' + @MaxQMList
                  + '\n CommissionList=' + @CommissionList  
  
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'CommissionGroup',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData  





GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupUpd] TO [vnteam]