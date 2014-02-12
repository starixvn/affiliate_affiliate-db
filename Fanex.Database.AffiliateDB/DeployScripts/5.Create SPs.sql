--use Affiliate_Licensee;


GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminSelDBTime]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminSelDBTime    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_AdminSelDBTime]
    @DBTime DateTime output,
    @GMTOffset varchar(20) output
AS
/*
Created: 20090708@DungTong
Task : Select current DB Time to display to website
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
.@DBTime: OUTPUT of current DB Time,
*/
SET NOCOUNT ON
Select @DBTime=getdate()
declare @OffsetMinute int
select @OffsetMinute=DATEDIFF(minute,getutcdate(),getdate())

select @GMTOffset=' GMT'
if @OffsetMinute=0
  return   

if(@OffsetMinute>0) 
  set @GMTOffset=@GMTOffset + '+' 
else 
  set @GMTOffset=@GMTOffset + '-' 
select @OffsetMinute=abs(@OffsetMinute)
if(@OffsetMinute/60>= 10)
  set @GMTOffset=@GMTOffset + cast(@OffsetMinute/60 as varchar(5))
else
  set @GMTOffset=@GMTOffset + '0' + cast(@OffsetMinute/60 as varchar(5))

if @OffsetMinute%60 >= 10
      set @GMTOffset=@GMTOffset + ':' + cast(@OffsetMinute%60 as varchar(5))
else
      set @GMTOffset=@GMTOffset + ':0' + cast(@OffsetMinute%60 as varchar(5))
GO
/****** Object:  StoredProcedure [dbo].[DBA_GrantPermissions]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
/****** Object:  Stored Procedure dbo.DBA_GrantPermissions    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE PROCEDURE [dbo].[DBA_GrantPermissions] 
            @SPs            nvarchar(4000), 
            @strPermission    varchar(4000)='' OUTPUT 
            AS 
             BEGIN 
             SET NOCOUNT ON; 
            DECLARE @SP_name nvarchar(4000), @i int, @StringPermission nvarchar(4000) 
             SELECT @SPs = @SPs + ',' , @strPermission ='GO nnn' 
             SELECT @SPs = replace(@SPs, ',,', ',') 
             SELECT @i = charindex(',', @SPs) 
             WHILE @i > 0 
            BEGIN 
             SELECT @SP_name = left(@SPs, @I-1) 
             SELECT @SPs = replace(@SPs, @SP_name + ',', '') 
             SELECT @strPermission = @strPermission + ' ' + state_desc + ' '+ permission_name + ' ON ' +  '[dbo].[' + OBJECT_NAME(major_id)  + ']' + ' TO '+ '['+ USER_NAME(grantee_principal_id)+']' + 'nnnGO nnn' 
             FROM sys.database_permissions 
            WHERE OBJECT_NAME(major_id)= @SP_Name 
            SELECT @i = charindex(',', @SPs) 
            END 
            Select @strPermission 
            END
GO
/****** Object:  StoredProcedure [dbo].[Aff_SportTypeSel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SportTypeSel    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_SportTypeSel]
    
AS
/*
    Created: @VinhTrinh
    Task : Select Sport type
    DB: DB052.Affiliate_MYM    
    Revisions:    
*/
SET NOCOUNT ON
Select SportID, SportName
from SportType with(nolock)
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductIDSel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductIDSel    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_ProductIDSel]
    
AS
/*
    Created: @VinhTrinh
    Task : Select Sport type
    DB: DB052.Affiliate_MYM    
    Revisions:    
*/
SET NOCOUNT ON
Select ProductID, SportName
from ProductID with(nolock)
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductSelByID]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductSelByID    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_ProductSelByID]    
    @ID tinyint
AS
/*
Created: 20110221@Peter
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From Product (nolock)
where ProductID=@ID
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductSelByAffID]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductSelByAffID    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_ProductSelByAffID]
    @AffID int,
    @MonthDate datetime=null,
    @Language varchar(10) ='en-US'
AS

BEGIN
   if(@MonthDate is null or DATEDIFF(m,current_timestamp,@MonthDate)>=0)
   begin
       
       Select ProductID,isnull(r.ResourceValue,ProductName) as ProductName
       from Product p (nolock)
        left join RefResources r (nolock) on r.RefID='Product' and r.LanguageCode=@Language and r.ResourceKey=p.ProductName

        where p.ProductID in
       (
       select distinct ProductID from GroupSetting g (nolock)
        inner join AffInfo a (nolock) on a.GroupID=g.GroupID
        where a.AffID=@AffID
         
       )          
   end
   else
   begin
          Select ProductID,isnull(r.ResourceValue,ProductName) as ProductName
       from Product p (nolock)
        left join RefResources r (nolock) on r.RefID='Product' and r.LanguageCode=@Language and r.ResourceKey=p.ProductName

        where p.ProductID in
       (
       select distinct g.ProductID from GroupSettingHistory g (nolock)
       inner join AffGroupHistory a (nolock) on a.GroupID=g.GroupID

       where a.AffID=@AffID and a.MonthDate=@MonthDate and g.MonthDate=@MonthDate
        
       )          
   end
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductSelAll]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductSelAll    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ProductSelAll]        
    @Name varchar(255) = NULL,    
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
--count nrows
select @NRows=count(1)
FROM Product N WITH (NOLOCK)    
where ProductName like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
    
SELECT ProductID, ProductName,Description,au.username AS Creator,CreatedDate,BettypeList
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY ProductName asc) AS TheCount,
        C.*
    FROM Product C WITH (NOLOCK)        
    where ProductName like @Name
    ) x
LEFT JOIN AdminUser au ON x.Creator = au.custid
where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductSel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductSel    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ProductSel]
    
AS
/*
    Created: @VinhTrinh
    Task : Select Product list
    DB: DB052.Affiliate_MYM    
    Revisions:    
*/
SET NOCOUNT ON
Select ProductID, ProductName
from Product with(nolock)
GO
/****** Object:  StoredProcedure [dbo].[Aff_ReportDetailSelByAff]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ReportDetailSelByAff    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ReportDetailSelByAff]
    @AffID int,
    @Fromdate datetime,
    @Todate datetime,
    @AffType tinyint = 0
AS
/*
Created: @VinhTrinh
Task : Get report by date for all affiliate.
    Three cases to calculate report:
      + @Todate<=@OldReportDate ---> use old formula
      + @FromDate>@OldReportDate
         . @FromDate --> @MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)
         . @MaxTransDate + 1 --> @Todate-1: use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
         . @CurDate : from bettrans     and cannot calculate Affiliate Winlost and House Winlost
      + @FromDate-->@OldReportDate-->@Todate:
         .@FromDate -->@OldReportDate:use old formula
         .@OldReportDate + 1 --->@MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)
         .@MaxTransDate +1 --->@Todate-1 :use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
         . @CurDate : from bettrans     and cannot calculate Affiliate Winlost and House Winlost 
DB: DB052.Affiliate_MYM
Original: [Aff_CustomerSelDetailsByAff]
Revisions:
    
Param's Explanation:
    • @Fromdate Month search from
    • @Todate To month.
*/
SET NOCOUNT ON


if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN

declare @CurrDate datetime,@TmpToDate datetime


select @CurrDate =  getdate()
        
        
Select @TmpToDate=@ToDate
if(@Todate>=@CurrDate)
select @TmpToDate=@CurrDate
    
      
Select Winlostdate, 
            at.Name as AffTypeName,
            e.Code as Currency, 
            --e.Currency, 
            a.SysExRate as Actualrate, 
            isnull(Sum(MemDeposit), 0) as Deposit,
            isnull(Sum(MemTurnover), 0) as Turnover,            
            isnull(Sum(MemBonus), 0) as Bonus,
            isnull(Sum(MemWinLost), 0) as MemberWinLost,
            isnull(Sum(AffWinLost), 0) as AffiliateWinLost,
            isnull(Sum(HouseWinLost), 0) as HouseWinLost,
            isnull(Sum(AffNetWinLost), 0) as AffiliateNetWinLost,
            isnull(Sum(HouseNetWinLost), 0) as HouseNetWinLost
        From AffDaily a with(nolock)
            inner join Exchange e with(nolock) on a.MemCurrency = e.ExchangeID
            inner join AffInfo ai with(nolock) on a.AffID = ai.AffID
             left join AffType at with (nolock) on ai.AffType = at.TypeID
        Where winlostdate between @FromDate and @TmpToDate and a.AffID = @AffId
        and (@AffType = 0 OR ai.AffType = @AffType)
        Group By Winlostdate, e.Code, a.SysExRate,at.Name
        order by Winlostdate,e.Code
GO
/****** Object:  StoredProcedure [dbo].[Aff_ReportDetailSelAll]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ReportDetailSelAll    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ReportDetailSelAll]
    @Fromdate datetime,
    @Todate datetime,
    @AffType tinyint = 0
AS
/*
Created: @VinhTrinh
Task : Get report by date for all affiliate.
     Three cases to calculate report:
      + @Todate<=@OldReportDate ---> use old formula
      + @FromDate>@OldReportDate
         . @FromDate --> @MaxTransDate : use new formula MemberDaily (need to join AffCommission to calculate)
         . @MaxTransDate + 1 --> @Todate-1: use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
         . @CurDate : from bettrans     and cannot calculate Affiliate Winlost and House Winlost
      + @FromDate-->@OldReportDate-->@Todate:
         .@FromDate -->@OldReportDate:use old formula
         .@MaxTransDate +1 --->@Todate-1 :use new formula MemberDaily and cannot calculate Affiliate Winlost and House Winlost
         . @CurDate : from bettrans     and cannot calculate Affiliate Winlost and House Winlost        
DB: DB052.Affiliate_MYM
Original: [Aff_ReportDetailSelAll]
Revisions:
    
Param's Explanation:
    • @Fromdate Month search from
    • @Todate To month.
*/


SET NOCOUNT ON



if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN

declare @CurrDate datetime, @TmpToDate datetime

select @CurrDate = GETDATE(),
        @Fromdate = dbo.Aff_GetStartDate(@Fromdate),
        @Todate = dbo.Aff_GetEndDate(@Todate)
        
Select @TmpToDate=@ToDate

if(@Todate>=@CurrDate)
    select @TmpToDate=@CurrDate    

   
Select Winlostdate, 
            at.Name as AffTypeName,
            e.Code as Currency, 
            
            a.SysExRate as Actualrate, 
            isnull(Sum(MemDeposit), 0) as Deposit,
            isnull(Sum(MemTurnover), 0) as Turnover,            
            isnull(Sum(MemBonus), 0) as Bonus,
            isnull(Sum(MemWinLost), 0) as MemberWinLost,
            isnull(Sum(AffWinLost), 0) as AffiliateWinLost,
            isnull(Sum(HouseWinLost), 0) as HouseWinLost,
            isnull(Sum(AffNetWinLost), 0) as AffiliateNetWinLost,
            isnull(Sum(HouseNetWinLost), 0) as HouseNetWinLost
        From AffDaily a with(nolock)
            inner join AffInfo ai with (nolock) on ai.affid=a.AffID
           inner join Exchange e with(nolock) on a.MemCurrency = e.ExchangeID
           left join AffType at with (nolock) on ai.AffType = at.TypeID
        Where winlostdate between @FromDate and @TmpToDate
            and (@AffType=0 or ai.AffType=@AffType)
        Group By Winlostdate, e.Code, a.SysExRate,at.Name
        order by Winlostdate, e.Code
GO
/****** Object:  StoredProcedure [dbo].[Aff_RecheckIn]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_RecheckIn    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_RecheckIn]     
 @On_UserID int,    
 @IsKickedOut bit = 0 OUTPUT    
AS    
SET NOCOUNT ON    
    
--Original:On_UserUpd    
----------------------------------    
--Allow multi-login, will remove after testing    
/*Select @IsKickedOut = 0    
update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate()     
where on_userid = @On_UserID    
return     */
  
--------------------------------    
    
if exists (select 1 from on_user with (NOLOCK) where On_UserID = @On_UserID and isKickedOut=1)    
BEGIN    
 Select @IsKickedOut=1    
END    
else    
BEGIN    
 Select @IsKickedOut = 0    
 update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate()     
 where on_userid = @On_UserID    
     
 IF @@ROWCOUNT = 0    
  Select @IsKickedOut=1    
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourceKeySelByID]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourceKeySelByID    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ResourceKeySelByID]    
    @ID uniqueidentifier
AS
/*
Created: 20110221@Peter
Task : Get 1 Resource From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From RefResources (nolock)
where ResourceID=@ID
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourceKeySel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourceKeySel    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ResourceKeySel]    
    @ResourceType varchar(50) =NULL,
    @LanguageCode varchar(8)=NULL,
    @Key varchar(50)=NULL,
    @Value nvarchar(256)=NULL,
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20110221@Peter
Task : Search Resources From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Key='%' + isnull(rtrim(ltrim(@Key)),'') + '%'
Select @Value='%' + isnull(rtrim(ltrim(@Value)),'') + '%'
/*Select @ResourceType='%' + isnull(@ResourceType,'') + '%'
Select @LanguageCode='%' + isnull(@LanguageCode,'') + '%'*/

DECLARE @Types TABLE
(
  SName varchar(50)
)

if @ResourceType is null 
    insert into @Types select SName from systemsettings where type ='ResourceRefID'
    

--count nrows
select @NRows=count(1)
FROM RefResources N WITH (NOLOCK)    
where ((@ResourceType is null and RefID in (Select SName from @Types)) or RefID = @ResourceType)
    and LanguageCode=coalesce(@LanguageCode,LanguageCode) and ResourceKey like @Key
    and ResourceValue like @Value
    And LanguageCode in (select LanguageID from Language (nolock))

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

    
SELECT [ResourceID],[RefID], [LanguageCode], [ResourceKey],[ResourceValue],[Description]
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY ResourceKey asc) AS TheCount,
        [ResourceID],[RefID], [LanguageCode], [ResourceKey],[ResourceValue],[Description]
    FROM RefResources N WITH (NOLOCK)    
    where ((@ResourceType is null and RefID in (Select SName from @Types)) or RefID = @ResourceType)
             and LanguageCode=coalesce(@LanguageCode,LanguageCode) and ResourceKey like @Key
                and (@Value = '%%' OR ResourceValue like @Value)
                And LanguageCode in (select LanguageID from Language (nolock))

    ) x
    where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourcesSel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourcesSel    Script Date: 7/29/2013 1:41:20 AM ******/
-- =============================================
-- Author:        Smith
-- Create date: 2011/02/23
-- Description:    <Description,,>
-- =============================================
CREATE Procedure [dbo].[Aff_ResourcesSel]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    select * from RefResources (nolock)
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_TaskLogUpdStatus]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TaskLogUpdStatus    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_TaskLogUpdStatus]
    @LogID int,
    @Status varchar(50) 
AS
BEGIN
    update TaskLog with (rowlock,updlock)
    set Status=@Status, CompletedDate=CURRENT_TIMESTAMP 
    where LogID=@LogID

    if lower(@Status)='completed'
    begin
        update TaskManager with (rowlock,updlock)
        set  LastRun=CURRENT_TIMESTAMP
        where TaskID= (select top(1) TaskID from TaskLog (nolock) where LogID=@LogID)
    end
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_TaskLogIns]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TaskLogIns    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_TaskLogIns]
    @TaskID smallint,
    @RunDate datetime,
    @Status varchar(50),
    @LogID int OUTPUT
AS

BEGIN
    
    insert into TaskLog(TaskID,RunDate,Status,CompletedDate)
    values(@TaskID,@RunDate,@Status,GETDATE())
    select @LogID=SCOPE_IDENTITY()
    if lower(@Status)='completed'
    begin
        update TaskManager with (rowlock,updlock)
        set  LastRun=GETDATE()
        where TaskID=@TaskID
    end
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_TaskDetailSelByName]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TaskDetailSelByName    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_TaskDetailSelByName]
    @TaskName varchar(100)
    
AS
BEGIN
    select top(1) * from TaskManager(nolock) where TaskName=@TaskName
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSupportedCurrencies]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSupportedCurrencies    Script Date: 7/29/2013 1:41:21 AM ******/

-- =============================================
-- Author:        Peter
-- Create date: 19-02-2013
-- Description:    Get Affiliate System Supported Currencies Information
-- =============================================
CREATE Procedure [dbo].[Aff_SystemSupportedCurrencies] 
        
AS
BEGIN
    
    SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AFF_SupportedCurrencies' and Type ='Meta')
    -- Insert statements for procedure here
    select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID,MultipliedBy from Currency (nolock)
    where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_SelRefNo]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SelRefNo    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_SelRefNo]
    @RefNo bigint OUTPUT,
    @RefName varchar(10) = 'AFF_Comm'
AS  
/*
    DB052.Affiliate_MYM
*/
SET NOCOUNT ON
begin tran 
  
UPDATE Ref with (rowlock,updlock)
SET  @RefNo=RefNo=RefNo+1  
WHERE RefName=@RefName
  
commit tran  

GRANT EXECUTE ON [dbo].[Aff_SelRefNo] TO [bodbAdminNet]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourcesTypeSel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourcesTypeSel    Script Date: 7/29/2013 1:41:21 AM ******/
-- =============================================
-- Author:        Smith
-- Create date: 2011/02/23
-- Description:    <Description,,>
-- =============================================
CREATE Procedure [dbo].[Aff_ResourcesTypeSel]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    select SID,SName as [Key],SValue as [TypeName] from SystemSettings (nolock) where [Type]='ResourceRefID' order by SValue
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourcesTranslationSel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourcesTranslationSel    Script Date: 7/29/2013 1:41:21 AM ******/
/*Select Resources Translation for export to excel*/
CREATE Procedure [dbo].[Aff_ResourcesTranslationSel]    
    @ResourceType varchar(50) =NULL,
    @LanguageCode varchar(8)=NULL,
    @Key varchar(50)=NULL,
    @Value nvarchar(256)=NULL,
    @Option int = 0,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS

SET NOCOUNT ON

SELECT @Key='%' + isnull(rtrim(ltrim(@Key)),'') + '%'
SELECT @Value='%' + isnull(rtrim(ltrim(@Value)),'') + '%'
DECLARE @Types TABLE
(
  SName varchar(50)
)
if @ResourceType is null 
    insert into @Types select SName from systemsettings where type ='ResourceRefID'

IF(@Option=1)
    BEGIN        
        declare @langCount int
        set @langCount = (select count(*) From Language (NOLOCK))
        
        select R.RefID,R.ResourceKey,R.LanguageCode,R.ResourceValue, L.LanguageName as SValue
        from RefResources R (NOLOCK)
        inner join Language L ON L.LanguageID = R.LanguageCode
        Inner join 
        (
                    SELECT DISTINCT R.RefID,R.ResourceKey
                    from RefResources R (NOLOCK)
                    where R.LanguageCode In (select LanguageID From Language (NOLOCK))                    
                    AND RefID != 'AffiliateContent'    
                    AND ((@ResourceType is null and RefID in (Select SName from @Types)) or RefID = @ResourceType)
                    AND R.ResourceKey LIKE @Key
                    AND (R.ResourceValue IS NULL OR R.ResourceValue  LIKE @Value )
                    group by R.RefID, R.ResourceKey
                    having count(R.LanguageCode) < @langCount
        ) T on R.RefID = T.RefID and R.ResourceKey =T.ResourceKey            
    
        order by R.RefID, R.ResourceKey,R.LanguageCode    
    END
ELSE
    BEGIN

        SELECT DISTINCT R1.ResourceID,R1.RefID,R1.LanguageCode, R1.ResourceKey,R1.ResourceValue,S.LanguageName as [SValue]
        FROM RefResources  AS R1 WITH (NOLOCK),
                (
                    SELECT DISTINCT R1.[ResourceKey]
                                FROM RefResources  AS R1 WITH (NOLOCK), 
                                    RefResources AS R2 WITH (NOLOCK)
                                WHERE R1.[LanguageCode]='en-US'
                                AND R2.[LanguageCode] <> 'en-US'
                                AND R1.RefID != 'AffiliateContent'    
                                AND R2.RefID != 'AffiliateContent'    
                                AND ((@ResourceType is null and R1.RefID in (Select SName from @Types)) or R1.RefID = @ResourceType)
                                AND R1.[ResourceKey] = R2.[ResourceKey]
                                --AND R1.[ResourceValue]=R2.[ResourceValue]
                )R2 ,Language S(NOLOCK)
        WHERE    ((@ResourceType is null and R1.RefID in (Select SName from @Types)) or R1.RefID = @ResourceType)
                AND R1.RefID != 'AffiliateContent'    
                AND R1.LanguageCode = coalesce(@LanguageCode,R1.LanguageCode) 
                AND R1.ResourceKey LIKE @Key
                AND (R1.ResourceValue IS NULL OR R1.ResourceValue  LIKE @Value )
                AND R1.[ResourceKey] = R2.[ResourceKey]                
                AND S.LanguageID = R1.[LanguageCode]
        ORDER BY R1.RefID,R1.ResourceKey,R1.LanguageCode

    END
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemCurrencySel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemCurrencySel    Script Date: 7/29/2013 1:41:22 AM ******/
-- =============================================
-- Author:        <Author,,Name>
-- Create date: <Create Date,,>
-- Description:    <Description,,>
-- =============================================
CREATE Procedure [dbo].[Aff_SystemCurrencySel]
    -- Add the parameters for the stored procedure here
    
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    select Code,Prefix, ExchangeID from Exchange (nolock)
    where Code = (select SValue from SystemSettings where SName = 'SystemCurrency')
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_SupportedLanguagesSel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SupportedLanguagesSel    Script Date: 7/29/2013 1:41:22 AM ******/
-- =============================================
-- Author:        Smith
-- Create date: 2011/02/23
-- Description:    <Description,,>
-- =============================================
CREATE Procedure [dbo].[Aff_SupportedLanguagesSel]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    select SID,SName as [Key],SValue as [TypeName] from SystemSettings (nolock) where [Type]='SupportedLanguages' order by [SValue]
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsSelByType]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsSelByType    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_SystemSettingsSelByType]    
    @Type varchar(50)=NULL
AS
/*
Created: 20110221@Peter
Task : Get All Settings By Type
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

SELECT [SID], [SName], [SValue],[Type],[Description]
FROM SystemSettings S WITH (NOLOCK)        
where Type =coalesce(@Type,Type)
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsSelByName]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsSelByName    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_SystemSettingsSelByName]    
    @Name varchar(50)
AS
/*
Created: 20110222@Johnny
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From SystemSettings (nolock)
where SName=@Name
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsSelByID]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsSelByID    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_SystemSettingsSelByID]    
    @ID int
AS
/*
Created: 20110221@Peter
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From SystemSettings (nolock)
where SID=@ID
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsSelAll]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsSelAll    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_SystemSettingsSelAll]    
    @Type varchar(50)=NULL,
    @Key varchar(50) =NULL,
    @Value nvarchar(256)=NULL,
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20110221@Peter
Task : Get All Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Key='%' + isnull(rtrim(ltrim(@Key)),'') + '%'
Select @Value='%' + isnull(rtrim(ltrim(@Value)),'') + '%'
--count nrows
select @NRows=count(1)
FROM SystemSettings N WITH (NOLOCK)    
where SName like @Key and Type =coalesce(@Type,Type) and SValue like @Value 

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
    
SELECT [SID], [SName], [SValue],[Type],[Description]
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY SName asc) AS TheCount,
        [SID], [SName], [SValue],[Type],[Description]
    FROM SystemSettings S WITH (NOLOCK)        
    where SName like @Key and Type =coalesce(@Type,Type) and SValue like @Value 
    ) x
where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsSel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsSel    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_SystemSettingsSel]
    @ID int = 0,
    @Type varchar(50)=NULL,
    @Name varchar(50) =NULL,
    @Environment varchar(50) = NULL,
    @Value nvarchar(256)=NULL
AS
/*
Created: 20130327@Joseph
Task : Get All Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
Select @Value='%' + isnull(rtrim(ltrim(@Value)),'') + '%'

SELECT [SID], [SName], [SValue],[Type],[Description]
    FROM SystemSettings S WITH (NOLOCK)        
    where (@ID IS NULL OR @ID = 0 OR SID = @ID)
        AND (@Environment IS NULL OR @Environment = '' OR Environment = @Environment)
         AND SName like @Name and Type =coalesce(@Type,Type) and SValue like @Value
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_ClearLogin]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_ClearLogin    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Task_Aff_ClearLogin]
    
AS

/*
    Created:  20110221@Jamie
    Task: Clear Login
    DB: DB052.Affiliate_MYM
    Original SP:
    
    Revisions:
        
*/
SET NOCOUNT ON
DELETE FROM On_User with (updlock)
WHERE        
reload_time is null or reload_time < dateadd(minute,-5,CURRENT_TIMESTAMP)
GO
/****** Object:  StoredProcedure [dbo].[Aff_TextSel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TextSel    Script Date: 7/29/2013 1:41:23 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextSel_1_xpre    Script Date: 4/3/2012 3:07:13 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextSel_1    Script Date: 2/24/2012 10:17:35 AM ******/

CREATE Procedure [dbo].[Aff_TextSel]    
    @Category varchar(50)=NULL,
    @Language varchar(50)=NULL,
    @Currency varchar(50)=NULL,
    @PageSize int=50,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS

SET NOCOUNT ON

--count nrows
select @NRows=count(1)
FROM Banners with (nolock)
WHERE Category=coalesce(@Category,Category) 
      and [Language]=coalesce(@Language,[Language])
      and [ImageType] = 'Text'
      and isnull(Currency,'')=coalesce(@Currency,Currency,'') 

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT     BannerID, Category,
    [Language],Lastupdate,Currency,[Content]
FROM(       
SELECT TOP(@RowEnd) 
            ROW_NUMBER() OVER(ORDER BY bannerid DESC) AS TheCount,
            BannerID, Category,
            [LanguageName] as Language, Lastupdate,Ex.Currency,[Content]
FROM Banners B with (nolock)
inner join language L with (nolock) on B.Language = L.LanguageID
inner join Exchange Ex with (nolock) on Ex.ExchangeID = B.Currency
WHERE Category=coalesce(@Category,Category) 
      and [Language]=coalesce(@Language,[Language])
      and [ImageType] = 'Text'
      and isnull(B.Currency,'')=coalesce(@Currency,B.Currency,'') 
   ) x
 where x.TheCount between @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_GetPrefixByAff]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_GetPrefixByAff    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE Procedure [dbo].[Aff_GetPrefixByAff]  
    @AffID int,
    @Prefix varchar(3)='$' OUTPUT   
AS  
/*
    Created: 20110330@VinhTrinh 
    Task : [description of SP]  
    DB: DB052.Affiliate_MYM1
    Revisions:          
          - Get Prefix by AffId
    Param's Explanation:  
*/  
SET NOCOUNT ON

Select @Prefix = isnull(Prefix, '$')
from AffInfo a with(nolock)
    left join Exchange e with(nolock) on a.Currency = e.ExchangeID
where AffId = @AffId
GO
/****** Object:  StoredProcedure [dbo].[Aff_GetMemberStatistics]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_GetMemberStatistics    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE Procedure [dbo].[Aff_GetMemberStatistics]
    @AffType tinyint = 0,
    @DepositAll money= 0 Output,
    @DepositMonth money= 0 Output,
    @PSPFeeAll money= 0 Output,
    @PSPFeeMonth money= 0 Output,
    @WinlostAll money= 0 Output,
    @WinlostMonth money= 0 Output,
    @BonusAll money= 0 Output,
    @BonusMonth money= 0 Output,
    @AdjustmentAll money= 0 Output,
    @AdjustmentMonth money= 0 Output,
    @NetWinlostAll money= 0 Output,
    @NetWinlostMonth money= 0 Output
AS
SET NOCOUNT ON

declare @MaxWinLostDateAffComm smalldatetime,@NextMaxWinlostDate smalldatetime
declare @CurrentDate smalldatetime

select @MaxWinLostDateAffComm=max(winlostdate) from  AffCommission with(nolock)


if @MaxWinLostDateAffComm is null
begin
   Select @NextMaxWinlostDate=cast ((select top(1) SValue from SystemSettings(nolock) where Type='Meta' and SName='SystemStartDate') as smalldatetime )   
end
else   
begin
  Select @NextMaxWinlostDate=dateadd(d, 1, @MaxWinLostDateAffComm)
end
  
  
select @CurrentDate= getdate()

print @NextMaxWinlostDate
declare @TblStatistics as table(deposit money, winlost money, bonus money, psp money, Adjustment money, WinlostDate smalldatetime)

Insert into @TblStatistics(deposit, winlost, bonus, psp, Adjustment, winlostdate)        
    select 
        sum(isnull(MemberDeposit, 0)) as deposit,
        sum((isnull(MemberWinlost, 0))) as winlost,
        sum(isnull(MemberBonus, 0)) as bonus,
        sum(isnull(MemberPSP, 0)) as psp,
        sum(isnull(MemberAdjustment, 0)) as Adjustment,
        @MaxWinLostDateAffComm as winlostdate        
    from AffCommission ac with (nolock)
        inner join AffInfo ai with (nolock) on ac.AffId = ai.AffId
    where  (@AffType=0 or ai.AffType = @AffType) and ProductID>0 and winlostdate<@NextMaxWinlostDate
    union all
    select 
        sum(isnull(MemDeposit, 0)*SysExRate) as deposit,
        sum((isnull(MemWinlost, 0))*SysExRate) as winlost,
        sum(isnull(MemBonus, 0)*SysExRate) as bonus,
        sum(isnull(MemPSP, 0)*SysExRate) as psp,
        sum(isnull(MemAdjustment, 0)*SysExRate) as Adjustment,
        dateadd(mm, DATEDIFF(m,0,md.Winlostdate), 0) as winlostdate
    from AffDaily md with (nolock)
        inner join AffInfo ai with(nolock) on md.AffId = ai.AffId 
    where (@AffType=0 or ai.AffType = @AffType) and Winlostdate between @NextMaxWinlostDate  and @CurrentDate
    group by dateadd(mm, DATEDIFF(m,0,md.winlostdate), 0)
                  
    SELECT        
        @DepositAll =  SUM(isnull(Deposit,0)),
        @WinlostAll = SUM(isnull(Winlost,0)),
        @BonusAll = SUM(isnull(Bonus,0)),
        @PSPFeeAll = SUM(isnull(PSP,0)),
        @AdjustmentAll = SUM(isnull(Adjustment,0)),
        @DepositMonth =SUM(case when datediff(m, @CurrentDate, winlostdate)=0  then isnull(Deposit,0) else 0 end),
        @WinlostMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Winlost,0) else 0 end),
        @BonusMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Bonus,0) else 0 end),
        @PSPFeeMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(PSP,0) else 0 end),
        @AdjustmentMonth = SUM(case when datediff(m, @CurrentDate, winlostdate)=0 then isnull(Adjustment,0) else 0 end) 
    FROM @TblStatistics     
    
    
    
    SELECT @NetWinlostAll = isnull(@WinlostAll,0) + isnull(@BonusAll,0) + isnull(@AdjustmentAll,0),
           @NetWinlostMonth = isnull(@WinlostMonth,0) + isnull(@BonusMonth,0) + isnull(@AdjustmentMonth,0)
GO
/****** Object:  StoredProcedure [dbo].[Aff_GetMembers]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_GetMembers    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE Procedure [dbo].[Aff_GetMembers]          
    @Date SMALLDATETIME  
AS   
/*
	Created: 2013@Joseph	
	Task : Get list of member for task import member daily
	DB:  DB052.Affiliate_ZZun for Testing
	Revisions:
		- 20130731@Don : Fixed bug [Data isn't saved in DB when winlostdate < transdate in table bodb02.bettrans] (redmine.nexcel.vn/issues/4195)
		
*/
Select m.username  
from dbo.MemberInfo m (nolock)
left join dbo.MemberRemoval m1 (nolock) on m1.username=m.username
where datediff(d,m.RegisteredDate, cast(@Date as varchar(50)))>=-1 and 
(m.IsRemoved=0 or (m.IsRemoved=1 and datediff(m, cast(@Date as varchar(50)) 
,isnull(m1.RemovedDate,GetDate()))>0)) and m.CreatedDate is not null 
GO
/****** Object:  StoredProcedure [dbo].[Aff_GetMaxAdjustmentAmount]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_GetMaxAdjustmentAmount    Script Date: 7/29/2013 1:41:23 AM ******/
create PROCEDURE [dbo].[Aff_GetMaxAdjustmentAmount]    
    @Currency varchar(5) = 'USD'
AS
/*
Created: 20110222@Johnny
Task : Get 1 Settings From System
DB: 
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select SValue
From SystemSettings (nolock)
where SName = 'AFF_MaximumAdjustment' + @Currency
GO
/****** Object:  StoredProcedure [dbo].[Aff_ErrorLogInsert]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ErrorLogInsert    Script Date: 7/29/2013 1:41:23 AM ******/
-- =============================================
-- Author:        Joseph
-- Create date: 2013/03/26
-- Description:    <Description,,>
-- =============================================
CREATE Procedure [dbo].[Aff_ErrorLogInsert]
  @Message nvarchar(255) = NULL,
  @StackTrace nvarchar(MAX) = NULL,  
  @SiteID int = NULL,
  @IP varchar(20) = null,
  @Browser varchar(50) = null,
  @OS varchar(50) = null,
  @SessionID varchar(255) = null
AS
BEGIN
    
    SET NOCOUNT ON
    
    INSERT INTO [dbo].[ErrorLog]
           ([ExMessage]
           ,[StackTrace]
           ,[LogDate]
           ,[SiteID]
           ,[IP]
           ,[Browser]
           ,[OS]
           ,[SessionID])
     VALUES
          (@Message
           ,@StackTrace
           ,CURRENT_TIMESTAMP
           ,@SiteID
           ,@IP
           ,@Browser
           ,@OS
           ,@SessionID)
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_EmailHistorySel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_EmailHistorySel    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_EmailHistorySel]
	@MID int = NULL,
	@SenderName nvarchar(50)=NULL,
	@Email nvarchar(50)=NULL,
	@AffiliateUserName varchar(30)=NULL,
	@fromdate smalldatetime=null,
    @todate smalldatetime=null,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: 20090626@VinhTrinh
Task : Insert new email for EmailHistory
DB: DB052.Affiliate_ZZun
Original:

Revisions:
	- 20130916@Don: if values of column sender/email/affname are NULL, the data rows are included to resultset

Param's Explanation:
• @MID : mail id
        Null: search all
        id>0 : search for id
        <0 : search unknown email( affiliateid=-1)
.@SenderName: search by sender name.
.@Email: search by email    
.@AffiliateUserName: search by Affiliate User Name   
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows

*/
SET NOCOUNT ON
DECLARE @RowStart int, @RowEnd int, @AffiliateID int

  
--Search by unregistered affiliate
if(@MID<0)
begin
   select @AffiliateID=-1,@MID=null
end

select @AffiliateUserName = '%' + Coalesce(@AffiliateUserName, '') + '%' 
select @SenderName= '%' + Coalesce(@SenderName, '') + '%' 
select @Email= '%' + Coalesce(@Email, '') + '%'  

select @Nrows=count(1)
from EmailHistory with (nolock)
where MID=Coalesce(@MID,mid)
     and (sender LIKE @SenderName OR sender IS NULL)
     and (email LIKE @Email OR email IS NULL)
     and ( Affname like @AffiliateUserName OR AffName IS NULL)  
	 and (
		case when AffID = @AffiliateID or @AffiliateID is null then 1 
		else 0 end
	 ) = 1
     and (
          case when @fromdate is null or @todate is null then 1
                when CreatedDate between @fromdate and @todate then 1
                else 0
          end     
      )=1

if(isnull(@NRows,0)=0)
   return	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
       

select mid,content,sender,AffId as AffiliateID,affname,email,subject,CreatedDate as CreateDate,ip,browser
from (
     select mid,content,sender,AffId,affname,email,subject,CreatedDate,ip,browser,
            ROW_NUMBER() OVER(ORDER BY CreatedDate desc,AffId asc) AS TheCount
     from EmailHistory with (nolock)
     where MID=Coalesce(@MID,mid)
          and (sender LIKE @SenderName OR sender IS NULL)
		  and (email LIKE @Email OR email IS NULL)
          and ( Affname like @AffiliateUserName OR AffName IS NULL)
		  and (
			case when AffID = @AffiliateID or @AffiliateID is null then 1 
			else 0 end
		 ) = 1
          and (
          case when @fromdate is null or @todate is null then 1
                when CreatedDate between @fromdate and @todate then 1
                else 0
          end     
		 )=1
  ) x
where x.TheCount between @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_EarningSelDaily]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_EarningSelDaily    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE Procedure [dbo].[Aff_EarningSelDaily]  
    @AffID int,    
    @ProductID tinyint = 0,
    @monthdate smalldatetime = null,
    @FromDate  smalldatetime = null,
    @ToDate  smalldatetime = null,
    @AffCurrency varchar(8) = 'UUS' OUTPUT
    
AS  
/*
    Created: 200900911@VinhTrinh 
    Task : [description of SP]  
    DB: DB052.Affiliate_MYM
    Revisions:          
          - Get data for daily report from table AffDaily instead of MemberDaily
          - 20100520@Johnny: apply StatusID in bettrans table
          - 20100930@Peter : Change the new formula for displayed winlost
                       Winlost on Aff site=Winlost-Odds Management - Marketing cost -  PSP
                       --The formula change since 1 Oct 2010--need to consider a new column MemWinlostFake on MemberDaily table if it is changed again
                       MemWinlostFake need to be updated on TaskMemberDaily
          - 20101228@Henry: change bettype to new range
    Param's Explanation:  
    • @custid: affliate Id  
    • @monthdate: Month date need to view.
    
      
*/  
SET NOCOUNT ON
DECLARE @CurrDate smalldatetime

select @AffCurrency=e.CurrencyCode
from AffInfo ai (nolock)
    inner join Currency e (nolock) on e.CurrencyID=ai.Currency
where ai.AffID=@AffID

-- Exec Aff_GetPrefixByAff @AffId = @AffId, @Prefix = @Prefix OUTPUT

SET @CurrDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)
If (@monthdate is not null and (@FromDate is null or @ToDate is null))
Begin
    select @monthdate = dateadd(d, datediff(d, 0, @monthdate), 0)
    Select @fromdate = DATEADD(mm, DATEDIFF(m,0,@monthdate),0)
    Select @todate = case when @monthdate >= @CurrDate then @CurrDate else @monthdate end
End


SELECT 
    d.winlostdate,                     
    sum(d.MemDeposit_aff) as Deposit,
    sum(d.MemWithdrawal_aff) as Withdrawal,
    sum(d.MemWinlost_aff) as MemberWinlost,
    sum(d.MemWinlostFake_aff) as MemWinlostFake,
    sum(d.MemBonus_aff) as Bonus,
    sum(d.MemAdjustment_aff) as Adjustment,
    sum(d.MemTurnover_aff) as Turnover,
    sum(d.MemPSP_aff) as PSP
FROM AffDailySummary d with(nolock)             
WHERE AffID = @AffID        
    AND d.winlostdate between @fromdate and @todate
    and (case when @ProductID = 0 then 1 when @ProductID = ProductID then 1 else 0 end) = 1
    --and (isnull(MemTurnOver,0) <>0 or isnull(MemWinlost,0)<>0 or isnull(MemBonus,0)<>0 or isnull(MemAdjustment,0)<>0 or isnull(MemPSP,0)<>0 or isnull(MemMarketing,0)<>0 or isnull(MemDeposit,0)<>0 or isnull(MemWithdrawal,0)<>0)            
group by d.winlostdate
order by d.winlostdate
GO
/****** Object:  StoredProcedure [dbo].[Aff_GetSystemCurrency]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_GetSystemCurrency    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE Procedure [dbo].[Aff_GetSystemCurrency]
    @SystemCurrency smallint = 0 OUTPUT
AS

Select @SystemCurrency = e.ExchangeId
From SystemSettings as s with(nolock)
    inner join Exchange e with(nolock) on s.SValue = e.Code
where s.SName = 'SystemCurrency' and s.Type = 'Meta'
GO
/****** Object:  StoredProcedure [dbo].[Aff_HotNewsDetail_New]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HotNewsDetail_New    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE Procedure [dbo].[Aff_HotNewsDetail_New]
    @MsgID int=null
AS
/*
Created: 20090310@TrangLe
Task : Select affiliate hot news by message id or latest messageid
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090317@DungTong: allow to get latest message id
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
Param's Explanation:
• @MsgID : >0 message id selected
           null: select the latest message

*/
SET NOCOUNT ON
if(coalesce(@MsgID,-1)=-1) -- get the latest message
  begin
        select  @MsgID=max(MsgID) 
        from News with (nolock)     
  end
    
declare @ID varchar(10)
set @ID = cast(@MsgID as varchar(50))


/*
    SELECT r.LanguageCode
            ,r.ResourceValue as Value
          ,n.[creator]
          ,[posteddate]
          ,[msgid]
          ,[important]
          ,c.username as creatorname
      FROM News n with (nolock)
            INNER JOIN RefResources r WITH (NOLOCK) ON r.RefID = 'News'  AND r.ResourceKey = @ID
            LEFT JOIN AdminUser c WITH (NOLOCK) ON c.custid=n.[creator]
      WHERE 
            msgid=@MsgID
*/

DECLARE @Query VARCHAR(8000)  

DECLARE @Names VARCHAR(8000)  
/*SELECT  COALESCE(@Names + '], [', '') + LanguageID FROM Language (nolock)
 where ResourceKey = @ID    */       
  set @Names =  stuff(
    (
    select cast(',' as varchar(max)) + '[' + l1.LanguageID +']'
    from Language l1 (nolock)   
    for xml path('')
    ), 1, 1, '')  
  
    
SET @Query = '
select n.[creator]
      ,[posteddate]
      ,[msgid]
      ,[important]
      ,c.username as creatorname
      ,temp.*
      FROM News n with (nolock)
      LEFT JOIN AdminUser c WITH (NOLOCK) ON c.custid=n.[creator]
      INNER JOIN (
            select * from (select ResourceKey,ResourceValue,LanguageCode from RefResources r (nolock) 
            WHERE r.ResourceKey = ''' + @ID +''') a
            PIVOT
            (MIN(ResourceValue) FOR LanguageCode IN (' + @Names+ ')) pvt
     ) temp ON temp.ResourceKey = ''' + @ID + '''
     WHERE n.msgid = ' + convert(varchar(10),@MsgID)
--select @Query
exec (@Query)
GO
/****** Object:  StoredProcedure [dbo].[Aff_HotNewsDetail]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HotNewsDetail    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_HotNewsDetail]
    @MsgID int=null
AS
/*
Created: 20090310@TrangLe
Task : Select affiliate hot news by message id or latest messageid
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090317@DungTong: allow to get latest message id
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
Param's Explanation:
• @MsgID : >0 message id selected
           null: select the latest message

*/
SET NOCOUNT ON
if(coalesce(@MsgID,-1)=-1) -- get the latest message
  begin
        select  @MsgID=max(msgid) 
        from News with (nolock)     
  end
    
    SELECT [message_en]
          ,[message_cn]
          ,[message_tw]
          ,[message_es]
          ,[message_th]
          ,[message_vi]
          ,[message_id]
          ,n.[creator]
          ,[posteddate]
          ,[msgid]
          ,[important]
          ,c.username as creatorname
      FROM News n with (nolock)
            LEFT JOIN AdminUser c WITH (NOLOCK) ON c.custid=n.[creator]
      WHERE 
            msgid=@MsgID
GO
/****** Object:  StoredProcedure [dbo].[Aff_ExchangeSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ExchangeSel    Script Date: 7/29/2013 1:41:24 AM ******/

CREATE Procedure [dbo].[Aff_ExchangeSel]
    @Time smalldatetime=NULL
  
AS

/*
    Created: 
    Task : SELECT exchange rate
    DB: DB052.Affiliate_MYM
    Revisions:
        - 20110223@Peter: Revise
        - 20130219@Joseph: select column Exchange.Code

*/
SET NOCOUNT ON
Select @Time=coalesce(@Time,current_timestamp)
select @Time = dbo.Date_Only(@Time)

if(datediff(d,current_timestamp,@Time)=0)
Begin
    Select c.MultipliedBy,Exchange.* from Exchange (nolock)
    inner join Currency c (nolock) on Exchange.ExchangeID = c.CurrencyID
     order by Code
End
else
begin

    SELECT ed.*, e.Prefix,c.MultipliedBy
    FROM ExchangeDaily ed with(nolock)
        inner join Currency c (nolock) on ed.ExchangeID = c.CurrencyID     
        left join Exchange e with (nolock) on e.ExchangeID=ed.ExchangeID
    where [Date]=@Time
    order by ed.Code

end
GO
/****** Object:  StoredProcedure [dbo].[Aff_HotNewsSel_New]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HotNewsSel_New    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_HotNewsSel_New]
    @fromdate smalldatetime=null,
    @todate smalldatetime=null,
    @Important bit=null,
    @language    varchar(11) = null,
    @PageSize int=50,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20090317@DungTong
Task : Search message hot news and paging
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language

Param's Explanation:
• @fromdate : <> null: from postdate
                null: select all
• @todate : <> null: to postdate
                null: select all
• @Important : select message is important or not
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows
                

*/
SET NOCOUNT ON

DECLARE @RowStart int, @RowEnd int,@AffiliateID int

select @Nrows=count(1)
from News with (nolock)
where important=coalesce(@Important,important)
      and (
          case when @fromdate is null or @todate is null then 1
                when posteddate between @fromdate and @todate then 1
                else 0
          end     
      )=1
      
 if(isnull(@NRows,0)=0)
   return    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
       
if(@language is null)--select all column
begin
   
    select [message_en]        
          ,[creator]
          ,[posteddate]
          ,[msgid]
          ,[important]
          ,[creatorname]
          ,[updatename]
          ,[updateddate]
    from (
     SELECT [message_en]          
          ,n.[creator]
          ,[posteddate]
          ,[msgid]
          ,[important]
          ,C.username as creatorname
          ,u.username as updatename
          ,[updateddate]
          ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount
      FROM News n with (nolock)
            LEFT JOIN AdminUser C  WITH (NOLOCK) ON C.CUSTID=n.[creator]
            LEFT JOIN AdminUser u  WITH (NOLOCK) ON u.CUSTID=n.[updatedby]
      WHERE important=coalesce(@Important,important)
           and (case when @fromdate is null or @todate is null then 1
                    when posteddate between @fromdate and @todate then 1
                     else 0
               end     
            )=1
     ) x
     where x.TheCount between @RowStart and @RowEnd
end
else --select for specific language
 begin
  
     select message          
          ,[posteddate]
          ,[msgid]    
          ,[important]        
    from (
     SELECT  coalesce(r.ResourceValue,News.message_en) as [message]
            ,[posteddate]
            ,[msgid]
            ,[important]
            ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount          
      FROM News with (nolock)        
      INNER JOIN RefResources r with (nolock) ON 
        r.RefID = 'News' and r.LanguageCode = @language and News.MsgID = cast(r.ResourceKey as int)
      WHERE important=coalesce(@Important,important)
           and (case when @fromdate is null or @todate is null then 1
                    when posteddate between @fromdate and @todate then 1
                     else 0
               end     
            )=1
     ) x
     where x.TheCount between @RowStart and @RowEnd
 end
GO
/****** Object:  StoredProcedure [dbo].[Aff_HotNewsSel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HotNewsSel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE PROCEDURE [dbo].[Aff_HotNewsSel]
    @fromdate smalldatetime=null,
    @todate smalldatetime=null,
    @Important bit=null,
    @language    varchar(11) = null,
    @PageSize int=50,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20090317@DungTong
Task : Search message hot news and paging
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language

Param's Explanation:
• @fromdate : <> null: from postdate
                null: select all
• @todate : <> null: to postdate
                null: select all
• @Important : select message is important or not
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows
                

*/
SET NOCOUNT ON

DECLARE @RowStart int, @RowEnd int,@AffiliateID int

select @Nrows=count(1)
from News with (nolock)
where important=coalesce(@Important,important)
      and (
          case when @fromdate is null or @todate is null then 1
                when posteddate between @fromdate and @todate then 1
                else 0
          end     
      )=1
      
 if(isnull(@NRows,0)=0)
   return    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
       
if(@language is null)--select all column
begin
   
    select [message_en]
          ,[message_cn]
          ,[message_tw]
          ,[message_es]
          ,[message_th]
          ,[message_vi]
          ,[message_id]
          ,[creator]
          ,[posteddate]
          ,[msgid]
          ,[important]
          ,[creatorname]
          ,[updatename]
          ,[updateddate]
    from (
     SELECT [message_en]
          ,[message_cn]
          ,[message_tw]
          ,[message_es]
          ,[message_th]
          ,[message_vi]
          ,[message_id]
          ,n.[creator]
          ,[posteddate]
          ,[msgid]
          ,[important]
          ,C.username as creatorname
          ,u.username as updatename
          ,[updateddate]
          ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount
      FROM News n with (nolock)
            LEFT JOIN AdminUser C  WITH (NOLOCK) ON C.CUSTID=n.[creator]
            LEFT JOIN AdminUser u  WITH (NOLOCK) ON u.CUSTID=n.[updatedby]
      WHERE important=coalesce(@Important,important)
           and (case when @fromdate is null or @todate is null then 1
                    when posteddate between @fromdate and @todate then 1
                     else 0
               end     
            )=1
     ) x
     where x.TheCount between @RowStart and @RowEnd
end
else --select for specific language
 begin
  
     select message          
          ,[posteddate]
          ,[msgid]    
          ,[important]        
    from (
     SELECT  case @language
                    when 'en_US' then message_en    
                    when 'zh-TW' then coalesce(message_tw,message_en)
                    when 'zh-CN' then coalesce(message_cn,message_en)
                    when 'es-ES' then coalesce(message_es,message_en)
                    when 'th-TH' then coalesce(message_th,message_en)
                    when 'vi-VN' then coalesce(message_vi,message_en)
                    when 'id-ID' then coalesce(message_id,message_en)
                    else message_en                
                    end as [message]
            ,[posteddate]
            ,[msgid]
            ,[important]
            ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount          
      FROM News with (nolock)            
      WHERE important=coalesce(@Important,important)
           and (case when @fromdate is null or @todate is null then 1
                    when posteddate between @fromdate and @todate then 1
                     else 0
               end     
            )=1
     ) x
     where x.TheCount between @RowStart and @RowEnd
 end
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageSelByID]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_LanguageSelByID    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_LanguageSelByID]    
    @ID VARCHAR(8)
AS
/*
Created: 20110221@Peter
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From Language (nolock)
where LanguageID=@ID
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageSelAll]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_LanguageSelAll    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_LanguageSelAll]        
    @Name varchar(255) = NULL,    
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
--count nrows
select @NRows=count(1)
FROM Language N WITH (NOLOCK)    
where LanguageName like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
    
SELECT LanguageID, LanguageName,CountryID,au.Username AS Creator,CreatedDate,CountryName
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY LanguageName asc) AS TheCount,
        L.*, C.CountryName
    FROM [Language] L WITH (NOLOCK)        
    left join Country C on C.CountryID = L.CountryID
    where LanguageName like @Name
    ) x
LEFT JOIN dbo.AdminUser au on x.Creator = au.custid

where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageSel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_LanguageSel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_LanguageSel]
    
AS
-- DB052.Affiliate_12Bet
    

SELECT * 
FROM Language
Order by [Order]
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberDomainSel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberDomainSel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_MemberDomainSel]
    
AS
    Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate
    From [MemberDomain] a with(nolock)
        inner join AdminUser b with (nolock) on a.Creator = b.CustId
    order by a.DomainName
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberSel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberSel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_MemberSel]
    @username varchar(30)
AS
/*
    Created: 20090701@Jacob    
    DB: DB052.Affiliate_MYM

*/
SET NOCOUNT ON;
SELECT UserName
      ,[IBCCustID]
      ,[AffID]
      ,[UserName]
      ,[IBCUserName]
      ,[CreatedDate]
      ,[RegisteredDate]
      ,[IsRemoved]
      ,[DepositCustID]
      ,[FirstName]
      ,[LastName]
      ,[Currency]
      ,[Email]
      ,[Recommend]
FROM [MemberInfo]
WHERE [username]= @UserName
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberListSel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberListSel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_MemberListSel]
    @AffUsername nvarchar(50) = null,
    @Username nvarchar(30) = null,    
    @AffType int = 0,    
    @PageSize int=50,
    @PageIndex int=1 OUTPUT,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
    Created: 20090701@VinhTrinh    
    DB: DB05.Affiliate_MYM

    Revisions:        
               -20100112@Peter :     Shorting the page by CreatedDate . Request from Fan    
*/
SET NOCOUNT ON
declare @AffID int, @CurrDate smalldatetime

If @AffUsername is not null
Begin
    select @AffID = AffId from AffInfo with (nolock) where Username = @AffUsername and (@AffType = 0 or AffType = @AffType)
    if @AffID is null 
        return
End


select @CurrDate = dateadd(d, 0, (datediff(d, 0, current_timestamp)))

select @Username = '%' + isnull(@Username, '') + '%'

select @NRows = count(1)
from MemberInfo m with (nolock)
    inner join AffInfo a with(nolock) on m.AffID = a.AffID
where (case 
            when @AffID is null then 1 
            else 
                case when @AffID = a.AffID then 1 else 0 end
            end
        ) = 1
    and m.Username like @Username
    and (@AffType = 0 or a.AffType = @AffType)
    and m.IsRemoved=0
    
if(isnull(@NRows,0)=0) return    
   
DECLARE @RowStart int, @RowEnd int

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex=(case when @PageIndex > @TotalPages then @TotalPages else @PageIndex end),
       @RowStart = @PageSize * (@PageIndex-1) + 1, @RowEnd = @RowStart + @PageSize - 1
         

select m.UserName,  e.Code as Currency, m.FirstName, m.LastName, 
    m.CreatedDate,m.RegisteredDate, m.AffID, m.AffUserName as AffUserName,
    m.AffTypeName
from
    (select ROW_NUMBER() OVER(ORDER BY m.CreatedDate desc) AS TheCount,
         m.UserName, m.Currency as Currency, m.FirstName, m.LastName, m.CreatedDate,m.RegisteredDate,
          m.AffID, af.UserName as AffUserName,at.Name as AffTypeName
    from MemberInfo m with (nolock)
        INNER JOIN AffInfo af with (nolock) on m.AffID = af.AffId
        left join AffType at with (nolock) on af.AffType = at.TypeID
    where (case 
            when @AffID is null then 1 
            else 
                case when @AffID = af.AffID then 1 else 0 end
            end
            ) = 1
        and m.Username like @Username
        and (@AffType = 0 or af.AffType = @AffType)
        and m.IsRemoved = 0
    )m
  inner join Exchange e (nolock) on e.ExchangeID=m.Currency
where m.TheCount between @RowStart and @RowEnd
order by m.RegisteredDate desc, m.UserName asc
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberInfoGetMissingCreatedDate]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberInfoGetMissingCreatedDate    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_MemberInfoGetMissingCreatedDate]    
--Affiliate DB
AS    

SELECT UserName 
FROM dbo.MemberInfo (nolock)
WHERE CreatedDate IS NULL
GO
/****** Object:  StoredProcedure [dbo].[Aff_PlayersCurrenciesSel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PlayersCurrenciesSel    Script Date: 7/29/2013 1:41:11 AM ******/
-- =============================================
-- Author:        Peter
-- Create date: 30-05-2013
-- Description:    Get Affiliate Player Currencies Information
-- =============================================
CREATE Procedure [dbo].[Aff_PlayersCurrenciesSel]
        
AS
BEGIN
    
    SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AFF_PlayerCurrencies' and Type ='Meta')
    -- Insert statements for procedure here
    select CurrencyCode ,CurrencyID from Currency (nolock)
    where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_PaymentRequestSelDetail]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PaymentRequestSelDetail    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_PaymentRequestSelDetail]  
    @TransID bigint  
   
AS  
/*  
 Task : Get All Affiliate for a specific page  
DB: DB052.Affiliate_MYM  
Original: [Aff_PaymentRequestSelDetail]  
Revisions:     
 - Get Username2 from customer table.  
Param's Explanation:  
• @TransID : Payment Request's Transaction.  
 */  
SET NOCOUNT ON  
  
declare @SystemName varchar(50)  
  
Select @SystemName=SValue  
from SystemSettings with (nolock)  
where SName = 'SystemName' and Type='Meta'  
  
SELECT   
    b.Transid,  
    --smith  
    e.Code as AffCurrency,  
    b.AffId,  
    b.Transdate,  
    b.CompletedDate,  
    b.refId,  
    b.Status,  
    b.Description as transdesc,    
    p.username as UserName2,   
    ai.username as AffUserName,  
    af.PreferredPayment,  
    af.PreferredLanguage,  
    abs(p.Amount) as amt,  
    abs(p.AffPayout) as AffPayout,  
    p.AdminDesc,  
    p.AffDesc,  
    p.AffPayout as TransferAmount,  
    p.IBCUserName,  
    ai.email,  
    ai.firstname,  
    ai.lastname,  
 case when b.Status in ('Pending','Cancelled') and b.TransType=202 then ai.UserName  
                 when b.TransType=201  then 'System'        
         else admin.username  
   end  as  adminname,  
 p.RefID as RefID,  
 p.MemberCurrency as PlayerCurrency,   
 @SystemName as SystemName,  
 p.MemberCurrency as Currency,  
 (Select top(1) SValue from SystemSettings with (nolock)  
    where SName ='AFF_BalPlayer'+  e1.Code and Type='Meta') as BalanceUserName,  
    e1.Code as PlayerCurrencyCode  
FROM AffTrans b with(nolock)  
    inner join AffPayout p with (nolock) on b.RefId = p.RefId  
    inner join AffInfo ai with (nolock) on ai.AffID = b.AffID  
    inner join AffDetail af with (nolock) on ai.AffID = af.AffID            
    inner join Exchange e with (nolock) on b.AffCurrency = e.ExchangeID  
    inner join Exchange e1 with (nolock) on p.MemberCurrency = e1.ExchangeID  
    left join AdminUser admin with(nolock) on admin.custid=b.creator    
    
WHERE   
    b.Transtype = 202 and b.transid = @transid
GO
/****** Object:  StoredProcedure [dbo].[Aff_PaymentRequestSelList]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PaymentRequestSelList    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE PROCEDURE [dbo].[Aff_PaymentRequestSelList]
    @Username			NVARCHAR(30)  = NULL,
    @Status				NVARCHAR(10)  = NULL,   
    @GetAll				bit = 0,
    @Currency			int = NULL,
    @Fromdate			DATETIME  = NULL,
    @Todate				DATETIME  = NULL,
	@PageSize			int=50,
	@PageIndex			int=1,
	@TotalPages			int=0 OUTPUT,
	@NRows				int=0 OUTPUT
AS 

/*
 Task : Get All Affiliate for a specific page
DB: 
Original: [Aff_BettransSelRequestPaymentList]
Revisions:   
	- 20130812@Joseph uncomment currency filters
Param's Explanation:
• @Username: Affiliate username need to search
• @Status : pending,Approved,disapproved
• @GetAll : Get all paymentrequest if @GetAll = 1
• @Fromdate :  default value=null :search all
• @Todate :  default value=null :search all
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search
• @NRows OUTPUT,--total of rows
 */
 SET NOCOUNT ON
DECLARE @RowStart int, @TransType int

select @TransType = 202 --payment request

select @Username= '%' + Coalesce(@Username, '') + '%' 

IF @GetAll = 1-- Search by Username or Search All
BEGIN
	Select @NRows=Count(1) 
	FROM     AffTrans b WITH (nolock)
		INNER JOIN AffInfo c WITH (nolock) ON b.AffId = c.AffId
	WHERE   TransType = @TransType
		AND c.Username like @Username
		and ISNULL(@Currency, c.Currency) = c.Currency
	
    if (isnull(@NRows,0)=0)
          return     
    select 	@TotalPages=ceiling (convert(float,@NRows,0)/@PageSize)
    select @RowStart=((@PageIndex-1)*@PageSize)

	Select Top(@PageSize) * 
	from
		(SELECT   
			RowID=ROW_NUMBER() OVER 
				(order by  CASE b.status
							WHEN 'Pending' THEN 1
							WHEN 'Approved' THEN 2
							WHEN 'Rejected' THEN 3
							ELSE 4
						END,transid desc),
			b.Transid,
			b.Transdate,
			b.AffId,
			b.Status,
			b.refId,             
			a.Username,
			e.Code as Currency,			
			abs(Amount) as amt,
			b.Completeddate,
			case when b.Status in ('Pending','Cancelled') and TransType=202 then a.UserName
                 when b.TransType=201  then 'System'				  
				  else admin.username
			end  as Creator
		FROM AffTrans b WITH (nolock)
			INNER JOIN AffInfo a WITH (nolock) ON b.AffId = a.AffId
			INNER join Exchange e with(nolock) on a.Currency = e.ExchangeID
			LEFT Join AdminUser admin on b.creator = admin.CustId
		WHERE TransType = @TransType--Payment request
			AND a.Username like @Username       
			and ISNULL(@Currency, a.Currency) = a.Currency              			 
		) A
	Where A.RowId > @RowStart
END
ELSE
BEGIN         
	Select @NRows=Count(1) 
    FROM     AffTrans b WITH (nolock)          
    WHERE    TransType = @TransType                         
             AND b.status = Coalesce(@Status,b.status)
			 AND b.TransDate between @fromdate and @todate

    select 	@TotalPages=ceiling (convert(float,isnull(@NRows,0))/@PageSize)
    if  (@TotalPages=0)
         return

	select @RowStart=((@PageIndex-1)*@PageSize)
		 
	Select Top(@PageSize) * 
	from
		(SELECT   
			RowID=ROW_NUMBER() OVER 
				(order by CASE b.status
							WHEN 'Pending' THEN 1
							WHEN 'Approved' THEN 2
							WHEN 'Rejected' THEN 3
							ELSE 4
						END, transid desc),
			b.transid,
			b.transdate,
			b.AffId,
			b.status,
			b.refId,             
			a.username,
			e.Code as Currency,			
			abs(Amount) as amt,
			b.completeddate,
			case when b.Status in ('Pending','Cancelled') and TransType=202 then a.UserName
                 when b.TransType=201  then 'System'				  
			      else admin.username
			end  as Creator
		FROM     AffTrans b WITH (nolock)
				 INNER JOIN AffInfo a WITH (nolock) ON b.AffId = a.AffId	 
				 inner join Exchange e with(nolock) on a.Currency = e.ExchangeID
				 LEFT JOIN AdminUser admin with (nolock) on admin.custid=b.creator
		WHERE    TransType = @TransType                         
				 AND b.status = Coalesce(@Status,b.status)
				 AND b.TransDate between @fromdate and @todate
		) A
	Where A.RowId > @RowStart
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_OnUserSelNetSessionID]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_OnUserSelNetSessionID    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_OnUserSelNetSessionID]  
 @On_UserID int,     
 @NetSessionID varchar(30) OUTPUT 
AS  
/*
Created: 20090316@Ken
Task : Get NetSessionID from table On_User
DB: DB052.Affiliate_MYM

Revisions:    
*/
SET NOCOUNT ON
SELECT @NetSessionID = ''

SELECT @NetSessionID = NetSessionID
FROM On_User WITH(NOLOCK) 
WHERE On_UserID = @On_UserID
GO
/****** Object:  StoredProcedure [dbo].[Aff_MinAmountSel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MinAmountSel    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_MinAmountSel]  
    @currencyName varchar(5)= 'US$',  
    @AFF_MinWire MONEY OUTPUT,  
    @AFF_MinNeteller MONEY OUTPUT,  
    @AFF_MinCheque MONEY OUTPUT,  
    @AFF_MinMoneybookers MONEY OUTPUT,  
    @AFF_MinPlayer MONEY = 0 OUTPUT  
AS  
/*
    Created: 20090922@VinhTrinh
    Task : Select minimum amount for payment request.
    DB: DB052.Affiliate_MYM
*/
SET NOCOUNT ON
  
Select @AFF_MinWire = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinWire'+@currencyName  
Select @AFF_MinNeteller = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinNeteller'+@currencyName  
Select @AFF_MinCheque = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinCheque'+@currencyName   
Select @AFF_MinMoneybookers = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinMoneybookers'+@currencyName  
Select @AFF_MinPlayer = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinPlayer'+@currencyName
GO
/****** Object:  StoredProcedure [dbo].[Aff_WriteLog_UserLog_RunSP]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_WriteLog_UserLog_RunSP    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_WriteLog_UserLog_RunSP]
    @Creator INT,
    @AffID INT = 0,
    @SPName VARCHAR(50)=NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER
    @Details VARCHAR(4000) = NULL, --
    @IsAdmin bit = 0,    
    @IP varchar(25)=NULL
AS
/* Created:
    Task: Write Log function before run SP
    DB: DB052.Affiliate_MYM

    Revisions:            
    
    Param's Explaination:        
    - @UserID: UserId perform this action
    - @CustID: CustId is called
    - @SPName Store name
    - @Doing: Action on store
    - @IsAdmin: 0(Affiliate), 1(Admin Affiliate)
    - @IP 
*/
SET NOCOUNT ON;   

INSERT INTO dbo.UserLog_RunSP(    
    [AffID]
    ,[Creator]
    ,[SPName]
    ,[Details]
    ,[LoggedDate]
    ,[IsAdmin]
    ,[IP])
VALUES (
    @AffID
    ,@Creator 
    ,@SPName
    ,@Details
    ,getdate()
    ,@IsAdmin
    ,@IP)
GO
/****** Object:  StoredProcedure [dbo].[Aff_WriteLog_IISErr]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_WriteLog_IISErr    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_WriteLog_IISErr]
    @LoggedDate smalldatetime,
    @Page varchar(50) = '',
    @Function varchar(100) = '',
    @ErrMessage nvarchar(4000) = '',
    @ErrCode int = 0 Output,
    @ErrMsg nvarchar(400) = '' Output
AS

SET NOCOUNT ON

Insert into UserLog_IISErr([LoggedDate], [Page], [Function], [ErrMessage])
Values(@LoggedDate, @Page, @Function, @ErrMessage)

If @@Error <> 0
Begin
    select @ErrCode = 10050, @ErrMsg = 'Error when inserting log.'
End
GO
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupSelListNormal]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupSelListNormal    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupSelListNormal]    
    @AffID int=-1,
    @Currency varchar(5)=null,        
    @GroupID int=-1 output
AS

/*
Created: 20090719@DungTong
Task : Get Commission Group List (groupid<1000) for dropdown list
DB: DB052.Affiliate_MYM
Original:

Params Explaination:
   if AffID<> -1: need to check whether this private group is already assigned to this Aff
   output : Change AffID=0 if existed
Revisions:
*/
SET NOCOUNT ON
if(@AffID<>-1)
begin
    select @GroupID=GroupID,@Currency=Currency from AffInfo (nolock) where AffId=@AffID
end

select 
    GroupId,    
    GroupName    
from CommGroup with (nolock)     
where GroupID <1000 and IsDeleted=0 and  currency=coalesce(@Currency,currency)
GO
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupSelDetail]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupSelDetail    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupSelDetail]    
    @GroupId int = null,        
    @AffID int = null
AS
/*
Created: 20090719@DungTong
Task : Get Group Setting for Editing an existing Group
DB: DB052.Affiliate_MYM
Original:

Revisions:
*/
SET NOCOUNT ON

if @AffID is not null 
begin
    select @GroupId = groupid from affinfo with(nolock) where affid = @AffID
end

select GroupID,GroupName,g.CreatedDate,g.Creator,Description,e.ExchangeID,e.Code as Currency,QualifiedAmount,
        (case when Exists(select top(1) 1 from AffCommission(nolock) where GroupID=g.GroupID) 
                    or Exists(select top(1) 1 from AffInfo ai (nolock) where ai.GroupID=g.GroupID)  then 0 else 1 end) as IsCurrencyEditable
from CommGroup g (nolock)
inner join dbo.Exchange e on g.Currency = e.ExchangeID
where GroupID=@GroupID

select g.GroupID,g.ProductID,g.TierID,g.MinAmount,g.MaxAmount,g.MinQM,g.MaxQM,g.Commission
from GroupSetting g (nolock)     
where g.GroupID=@GroupID 

Select DeductionID, DeductedPercentage
from DeductionSetting (nolock)
where GroupID=@GroupID

Select top(1000) ProductID,ProductName
    from Product (nolock)
    
Select top(100)  DTypeID,ProductID,DTypeName,DTypeDesc,DeductedPercentage 
from DeductionType (nolock)

Select SValue as SupportedBaseCurrencies from SystemSettings (nolock) where Type='meta' and SName='SupportedBaseCurrencies'
GO
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupSelCommonSetting]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupSelCommonSetting    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupSelCommonSetting]    
AS
/*
Created: 20090719@DungTong
Task : Get Common Setting for Adding or Editing new Group
DB: DB052.Affiliate_MYM
Original:

Revisions:
*/
SET NOCOUNT ON
    Select top(1000) ProductID,ProductName
    from Product (nolock)
    
    Select top(100)  DTypeID,ProductID,DTypeName,DTypeDesc,DeductedPercentage 
    from DeductionType (nolock)
GO
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupSel]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupSel    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupSel]
    @GroupName nvarchar(100) = '',
    @Currency varchar(5)='',
    @FromDate datetime =null,
    @Todate datetime=null,
    @TotalNoneGroup int=0 OUTPUT,
    @PageSize int=50,
    @PageIndex int=1 OUTPUT,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS

/*
Created: 20090719@DungTong
Task : Search a Commission Group (paging)
DB: DB052.Affiliate_MYM
Original:

Revisions:
*/
SET NOCOUNT ON
select @Currency='%' + Coalesce(@Currency, '') + '%'     
if (isnull(@GroupName,'')='' or lower(@GroupName)='[none]')
begin
    select @TotalNoneGroup=count(1)
    from AffInfo a with (nolock)
         inner join CommGroup c with (nolock) on c.GroupID=a.GroupID
    where c.GroupID>1000 and c.IsDeleted=0  and c.Currency like @Currency  
end 
if(lower(@GroupName)='[none]')
begin  
   return
end

select @GroupName = '%' + @GroupName + '%'
---CommGroup Detail va SportName se duoc cache tren web server dung co che notification
DECLARE @RowStart int, @RowEnd int,@AffiliateID int



select @Nrows=count(1)
from CommGroup with (nolock)
where GroupID between 101 and 1000 and GroupName like @GroupName and IsDeleted = 0 and Currency like @Currency 
      and (
          case when @FromDate is null or @ToDate is null then 1
                when CreatedDate between @FromDate and @ToDate then 1
                else 0
          end     
      )=1
      
 if(isnull(@NRows,0)=0 or (@NRows>@PageSize and @PageSize>5000) or @PageIndex<0 or @PageSize<0)
   return    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end
if(@PageIndex>@TotalPages)
  select @PageIndex=@TotalPages
select @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1          

declare @Group table(GroupID int primary key,GroupName nvarchar(100),
                        Description nvarchar(100),Creator int,CreatedDate datetime,
                        ExchangeID smallint,Currency varchar(5),QualifiedAmount money,NoAff int)

insert into @Group(GroupID,GroupName,Description,Creator,CreatedDate,ExchangeID,Currency,QualifiedAmount)
 select GroupID,GroupName,Description,Creator,CreatedDate,ExchangeID,Currency,QualifiedAmount
     from (
             SELECT GroupID,GroupName,Description,CommGroup.Creator,CommGroup.CreatedDate,ExchangeID,e.Code as Currency,QualifiedAmount          
                  ,ROW_NUMBER() OVER(ORDER BY GroupID) AS TheCount
              from CommGroup with (nolock)                   
              inner join dbo.Exchange e on CommGroup.Currency = e.ExchangeID
               where GroupID between 101 and 1000 and  GroupName like @GroupName and IsDeleted = 0 and CommGroup.Currency like @Currency
              and (
                  case when @FromDate is null or @ToDate is null then 1
                        when CommGroup.CreatedDate between @FromDate and @ToDate then 1
                        else 0
                  end     
                  ) = 1
         ) x
     where x.TheCount between @RowStart and @RowEnd 
 Update t
 set t.NoAff=(select sum(1) from AffInfo i with (nolock) where i.GroupID=t.GroupID)
 from @Group t
 
 Select top(100)  DTypeID,ProductID,DTypeName,DTypeDesc,DeductedPercentage 
    from DeductionType (nolock)
    
Select DeductionID,GroupID,DeductedPercentage 
from DeductionSetting (nolock)
where GroupID in (select GroupID from @Group)    
 
 select g.GroupID,g.GroupName,g.Description,isnull(i.username,'System') as Creator,g.CreatedDate,isnull(g.NoAff,0) as NoOfAffiliate,
        g.Currency,g.QualifiedAmount
        ,(case when Exists(select top(1) 1 from AffCommission(nolock) where GroupID=g.GroupID) 
                    or Exists(select top(1) 1 from AffInfo ai (nolock) where ai.GroupID=g.GroupID)  then 0 else 1 end) as IsAllowedToDelete    
 from @Group g 
      left join AdminUser i with (nolock) on i.custid=g.Creator
 

select 
    g.GroupId,    
    g.ProductID,
    s.ProductName,
    g.TierID,
    g.MinAmount,
    g.MaxAmount,
    g.MinQM,
    g.MaxQM,
    g.Commission    
from GroupSetting g with (nolock)
     inner join Product s with (nolock) on s.ProductID=g.ProductID
where g.GroupID in (
     select GroupID from @Group
   )
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminSupportedLanguagesSel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminSupportedLanguagesSel    Script Date: 7/29/2013 1:41:12 AM ******/
-- =============================================
-- Author:        Peter
-- Create date: 30-05-2013
-- Description:    Get Admin Supported Languages Information
-- =============================================
CREATE Procedure [dbo].[Aff_AdminSupportedLanguagesSel]
        
AS
BEGIN
    
    SET NOCOUNT ON;

    declare @Languages varchar(max)
    select @Languages=(select SValue from SystemSettings where SName = 'AFF_AdminSupportedLanguages' and Type ='Meta')
    -- Insert statements for procedure here
    select LanguageID , LanguageName from Language (nolock)
    where LanguageID in (select val from [dbo].[strSplit] ( @Languages, ',' ) )
    Order by [Order]



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerUpdateStatistic]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerUpdateStatistic    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_BannerUpdateStatistic]
    @BannerID int
    
AS
/*
    Task : Get all information of existing member
    DB : DB054.Affiliate_MYM
        - Joseph@20130403: 
*/

update Banners set TotalRequest = COALESCE(TotalRequest,0) + 1, LastRequest = CURRENT_TIMESTAMP
where bannerid = @BannerID;
GO
/****** Object:  StoredProcedure [dbo].[Aff_BaseCurrenciesSel]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BaseCurrenciesSel    Script Date: 7/29/2013 1:41:12 AM ******/

-- =============================================
-- Author:        Peter
-- Create date: 22-01-2013
-- Description:    Get Base Currencies Information
-- =============================================
CREATE PROCEDURE [dbo].[Aff_BaseCurrenciesSel]
        
AS
BEGIN
    
    SET NOCOUNT ON;

    declare @SupportedBaseCurrencies varchar(max)
    select @SupportedBaseCurrencies=(select SValue from SystemSettings where SName = 'SupportedBaseCurrencies')
    -- Insert statements for procedure here
    select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID,MultipliedBy from Currency (nolock)
    where CurrencyCode in (select val from [dbo].[strSplit] ( @SupportedBaseCurrencies, ',' ) )



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoSelParent]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoSelParent    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_Con_FuncInfoSelParent]
AS
/*DB03.BODB02 --> DB052.Affiliate_MYM*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
SET NOCOUNT ON
    Select FuncId, FuncName
    from AffFunctionInfo
    where FuncId = ParentId AND System = 'AFFILIATE'
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoSelByFuncID]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoSelByFuncID    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_Con_FuncInfoSelByFuncID]
    @FuncId int
AS
/*DB03.BODB02--> Affiliate_MYM*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
SET NOCOUNT ON
select FuncId, FuncName, FuncDesc, FileNames, (select count(funcid) from AffFunctionInfo acc1 with (nolock) where acc1.parentid = acc.funcid and acc1.parentid <> acc1.funcid) as SubFuncCount
from AffFunctionInfo acc with (nolock)
where FuncId = @FuncId
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoSel]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoSel    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_Con_FuncInfoSel]
    
AS
/*DB03.BODB02--> DB052.Affiliate_MYM */
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
SET NOCOUNT ON

select acc.FuncId, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames, acc.parentid, count(acc1.funcID) as SubFuncCount,acc.System
from 
    AffFunctionInfo acc with (nolock)
    left join AffFunctionInfo acc1 with (nolock) on acc.funcID = acc1.ParentID and acc1.parentid <> acc1.funcid
where acc.[system] = 'AFFILIATE'
group by acc.FuncId, acc.parentid, acc.FuncName, acc.DisplayOrder, acc.FuncDesc, acc.FileNames,acc.System
order by acc.System,acc.parentid, SubFuncCount desc, acc.DisplayOrder
    --acc.FuncId
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffSelDetail]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffSelDetail    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_AffSelDetail]
    @AffID int
AS
SET NOCOUNT ON

select * from AffDetail where AffID = @AffID
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeSelByID]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffTypeSelByID    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_AffTypeSelByID]    
    @ID VARCHAR(8)
AS
/*
Created: 20110221@Peter
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From AffType (nolock)
where TypeID=@ID
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeSelAll]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffTypeSelAll    Script Date: 7/29/2013 1:41:13 AM ******/
/*
Created: 20130208@Joseph
Task : 
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
CREATE Procedure [dbo].[Aff_AffTypeSelAll]
    @Name varchar(100) = NULL,
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
--count nrows
select @NRows=count(1)
FROM AffType N WITH (NOLOCK)    
where Name like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
    
SELECT TypeID, Name,Description,au.Username AS Creator,CreatedDate
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY Name asc) AS TheCount,
        C.*
    FROM [AffType] C WITH (NOLOCK)        
    where Name like @Name
    ) x
LEFT JOIN dbo.AdminUser au on x.Creator = au.custid
where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeSel]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffTypeSel    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_AffTypeSel]
    
AS


SELECT TypeID ,Name
FROM dbo.AffType
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerSelType_1]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerSelType_1    Script Date: 7/29/2013 1:41:13 AM ******/
/****** Object:  Stored Procedure dbo.Aff_BannerSelType_1_xpre    Script Date: 4/3/2012 3:07:12 AM ******/
/****** Object:  Stored Procedure dbo.Aff_BannerSelType_1    Script Date: 2/24/2012 10:17:35 AM ******/

/****** Object:  Stored Procedure dbo.Aff_BannerSelType    Script Date: 10/29/2009 5:13:35 PM ******/
CREATE Procedure [dbo].[Aff_BannerSelType_1]
    @TypeName varchar(50)=NULL
AS
-- DB052.Affiliate_12Bet

declare @BannerTypes table(Type varchar(50),value nvarchar(100), DisplayOrder int IDENTITY(1,1))
insert into @BannerTypes(Type,value)
select 'Size' as Type,Value
from (
       select top(1000) value,
      (select top(1) val from dbo.strSplit(value,'x') where rank=1) width,
      (select top(1) val from dbo.strSplit(value,'x') where rank=2) height,
       len((select top(1) val from dbo.strSplit(value,'x') where rank=1)) as lw,
       len((select top(1) val from dbo.strSplit(value,'x') where rank=2)) as lh
        from BannerTypes with (nolock)
        where type='size'
        order by lw,width,lh,height
     )  t 
insert into @BannerTypes(Type,value)
      select Type,Value
      from  BannerTypes with (nolock)
      where type<>'size'
      order by Type,Value

SELECT DisplayOrder AS id, Value,type
FROM @BannerTypes 
WHERE Type=isnull(@TypeName,Type)
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerSelType]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerSelType    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_BannerSelType]
    @TypeName varchar(50)=NULL,
    @Language varchar(8) ='en-US',
    @ParentType smallint=NULL    
AS

if @TypeName='Size'
begin   
select TypeID,Value,ParentID,0 as HasSubCategory
 from (
       select top(1000) TypeID,value,ParentID,
      (select top(1) val from dbo.strSplit(value,'x') where rank=1) width,
      (select top(1) val from dbo.strSplit(value,'x') where rank=2) height,
       len((select top(1) val from dbo.strSplit(value,'x') where rank=1)) as lw,
       len((select top(1) val from dbo.strSplit(value,'x') where rank=2)) as lh
        from BannerTypes (nolock) where Type='Size'         
        order by lw,width,lh,height
     )  t 
 
  
end
else if @Language='en-US'
begin
   Select top(1000) bt.TypeID,bt.value,bt.ParentID,
        (select count(1) from BannerTypes bt1 (nolock) where bt1.ParentID=bt.TypeID) as HasSubCategory
   from BannerTypes bt (nolock)  

  where bt.Type=@TypeName and  (@ParentType is null or bt.ParentID=@ParentType)
           
   order by bt.DisplayOrder
end
else
begin
   select top(1000) bt.TypeID, isnull(r.ResourceValue,bt.Value) as Value, bt.ParentID,
        (select count(1) from BannerTypes bt1 (nolock) where bt1.ParentID=bt.TypeID) as HasSubCategory
   from BannerTypes bt (nolock)
   left join RefResources r with (nolock) on r.ResourceKey=bt.Value and r.RefID='Resource' and r.LanguageCode=@Language
   where  bt.Type=@TypeName
           and  (@ParentType is null or @ParentType = 0 or bt.ParentID=@ParentType)
   
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerSelInfo]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerSelInfo    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_BannerSelInfo]
    @BannerID int
AS

/*Created: 20130303@Joseph
Task : Get Specific baner information, used to display and refresh banner
DB:  DB052.Affiliate_MYM

Revisions:        
              
Param's Explanation:
• @BannerID : ID of banner 
*/

SET NOCOUNT ON
  
SELECT BannerID, Content, ImageType, bt.Value As [Size],Version
FROM Banners b with (nolock)
left join BannerTypes bt (nolock) on bt.TypeID=b.Size and bt.Type = 'Size'
WHERE BannerID=@BannerID
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerSelDetail]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerSelDetail    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_BannerSelDetail]
    @BannerID int
AS

/*Created: 20090328@DungTong
Task : Get Specific baner information
DB:  DB052.Affiliate_MYM

Revisions:        
              
Param's Explanation:
• @BannerID : ID of banner 
*/

SET NOCOUNT ON
  
SELECT BannerID, Content, Category,bt.parentID as ParentID,
            [Language], ImageType, [Size],Lastupdate,Currency,b.Type,Version,TotalRequest,LastRequest
FROM Banners b with (nolock)
inner join BannerTypes bt (nolock) on bt.TypeID=b.Category
WHERE BannerID=@BannerID
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerSel]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerSel    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_BannerSel]    
    @Category smallint=NULL,
    @Language varchar(8)=NULL,
    @ImageType smallint=NULL,
    @Size smallint=NULL,
    @Currency smallint=NULL,
    @Type tinyint=0,
    @PageSize int=50,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS

/*Created: 20090328@DungTong
Task : Search all Aff Banner Paging
DB:  DB052.Affiliate_12BET

Revisions:    
    - 20130207@Johnny: Filter by Type(1: normal banner; 2: media banners)
              
Param's Explanation:
• @Category : Search by Category value=null :search all
• @Language : Search by Language value=null :search all
• @ImageType : Search by ImageType value=null :search all
• @Size : Search by Size value=null :search all
• @Currency : Search by Currency value=null :search all
• @Type: type of banners(1: normal banner; 2: media banners)
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows

*/

SET NOCOUNT ON
 declare @SubCategory table(id int)
 
if isnull(@Category,0)<>0
begin
 insert into @SubCategory(id)
 select typeid from BannerTypes where  parentid= @Category
 union 
 select @Category
end 


--count nrows
select @NRows=count(1)
FROM Banners with (nolock)
WHERE (@Category is null or Category in (select id from @SubCategory))
      and (@Language is null or  Language=@Language)
       and (@ImageType is null or ImageType =@ImageType)
        and (@Size is null or size =@Size)
       and (@Currency is null or Currency =@Currency)      
       and (@Type is null or Type=@Type)
      

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT     BannerID, [Content], Category,
    [Language],LanguageCode, ImageType, [Size],Lastupdate,Currency,Type,Version,TotalRequest,LastRequest
FROM(       
SELECT TOP(@RowEnd) 
            ROW_NUMBER() OVER(ORDER BY bannerid DESC) AS TheCount,
                BannerID, [Content],btc.Value as Category,l.LanguageID as LanguageCode,
                l.LanguageName as [Language],bti.Value as ImageType, bts.Value as [Size],
                Lastupdate,c.CurrencyName as Currency,b.Type,Version,TotalRequest,LastRequest
FROM Banners b with (nolock)
left Join BannerTypes bts on bts.TypeID = b.Size
left Join BannerTypes bti on bti.TypeID = b.ImageType
inner Join BannerTypes btc on btc.TypeID = b.Category
inner join Language l on l.LanguageID=b.Language
inner join Currency c on c.CurrencyID=b.Currency

WHERE (@Category is null or b.Category in (select id from @SubCategory))
      and (@Language is null or  b.Language=@Language)
       and (@ImageType is null or b.ImageType =@ImageType)
        and (@Size is null or b.size =@Size)
       and (@Currency is null or b.Currency =@Currency)      
       and (@Type is null or b.Type=@Type)
      
      
    
   ) x
 where x.TheCount between @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_CheckNickname]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CheckNickname    Script Date: 7/29/2013 1:41:13 AM ******/
/****** Object:  Stored Procedure dbo.Aff_AffiliateIns    Script Date: 11/3/2009 5:46:27 PM ******/
CREATE Procedure [dbo].[Aff_CheckNickname]    
    @Nickname nvarchar(30),
    @IsAvailable bit = 0 OUTPUT
AS
/*    
Created:   
Task : Check Nickname
DB: DB052.Affiliate_MYM
Original: [Aff_CheckNickname]  
Revisions:    

Param's Explanation:    
• @ErrCode:    
    = 0: Create agent successfully.    
    > 0: Specific Error.    
      
• @ErrMsg: Error description.    
*/   
SET NOCOUNT ON

if Not exists(select 1 from AffInfo with (nolock) where Username2 = @Nickname)
    select @IsAvailable = 1
GO
/****** Object:  StoredProcedure [dbo].[Aff_CheckMemberExist]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CheckMemberExist    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_CheckMemberExist]
    @MemberName varchar(30),
    @AffName varchar(30),    
    @AffID int = null OUTPUT,
    @AffStatus varchar(20) = null OUTPUT,
    @IsMemberExist bit = 0 OUTPUT
    
AS
begin

SET NOCOUNT ON

    select @AffID = AffID,@AffStatus = [Status] from AffInfo where UserName = @AffName
    
    if(@AffID = null)
        return
    if @AffStatus = 'approved'
    begin 
        if (exists (Select 1 from AffInfo(nolock) where UserName=@AffName and IsClosed =1 ))
            set @AffStatus = 'closed'
    end
    
    select @IsMemberExist = count(1) from MemberInfo where UserName = @MemberName and IsRemoved != 1

end
GO
/****** Object:  StoredProcedure [dbo].[Aff_CheckIn]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CheckIn    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_CheckIn]
    @CustID int,
    @NetSessionID varchar(30),
    @ServerID int,
    @On_UserID int OUTPUT,
    @IP nvarchar(15) = '',
    @SubAccID int = 0
AS

/*
    Task: CheckIN
    DB: DB052.Affiliate_MYM
    Original SP:LoginDownline_OnUser
    
    Revisions:
        - 20100812@Jamie:Grant permision for Thai site 
    
    Param's Explanation: 
    @Thien: to allow internal admin login without interfere with real agent
            --    pass @SubAccID = - CustID of Admin
    
    Note : @SubSystem to indicate which of admin site connected from
    1 : ASP admin
    2 : VN.NET RBS
    3 : VN.NET Account Site
    4 : TW.NET Admin
    5 : TW.NET Admin call to ASP Admin
    6 : Affiliate Admin Site


*/

--Use kick-out method, so comment the below lines
/*
declare @ErrMsg varchar(100)
if exists (select 1 from on_user with (nolock) where custid = @custid and subaccid=@subaccid and serverid<>0 group by custid having count(1)>=1 )
BEGIN
    Select @ErrMsg = 'Sorry, system does not allow multiple login.'
    RaisError (@ErrMsg, 16, 1)
    return
END
*/
--EXEC dbo.On_UserIns @CustID = @CustID, @On_SessionID = @SessionID, @ServerID = @ServerID, @On_UserID = @On_UserID OUTPUT, @IP = @IP, @subaccid = @subaccid
if @@servername <> '5WRHH1S'--Vinh: not kickout at local server for testing
    update on_user with (ROWLOCK) set IsKickedout=1, ServerID=0 where CustID = @CustID and SubAccID = @SubAccID

--if @SubAccID < 0 --One admin can just log in one Agent/master/Super only
--    update on_user with (ROWLOCK) set IsKickedout=1, ServerID=0 where SubAccID = @SubAccID
    
insert into on_user
    (custid, NetSessionID, on_sessionid, ServerID, IsKickedout, IP, SubAccID,reload_time)
values
    (@custid, @NetSessionid,0, @ServerID, 0, @IP, @SubAccID,current_timestamp)

Select @On_UserID = SCOPE_IDENTITY()
GO
/****** Object:  StoredProcedure [dbo].[Aff_CheckDateMonthTransfer]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CheckDateMonthTransfer    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_CheckDateMonthTransfer]    
    @date datetime,
    @result bit OUTPUT
AS

declare @maxdate datetime 
set @maxdate = (select max(WinlostDate) from dbo.AffCommission)
set @result = 0
if datediff(dd, @maxdate, @date)>0
begin
    set @result = 1
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_GetCurrenciesNotInExchange]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_GetCurrenciesNotInExchange    Script Date: 7/29/2013 1:41:14 AM ******/
-- =============================================
-- Author:        Joseph
-- Create date: 22-01-2013
-- Description:    
-- =============================================
CREATE Procedure [dbo].[Aff_GetCurrenciesNotInExchange]
        
AS
BEGIN
    
    SET NOCOUNT ON;

    select CurrencyID,CurrencyCode, CurrencyName from Currency c
    where c.CurrencyCode Not IN (select Code from Exchange)



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_GenUsername]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_GenUsername    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_GenUsername]
    @AffPrefix varchar(20) = 'AFF',
    @username varchar(50) = '' OUTPUT
AS
/*    
Created:   
Task : Generate username with the prefix for new Aff
DB: DB052.Affiliate_MYM
Original: [Aff_AffiliateIns]  
Revisions:    

Param's Explanation:    
    @AffPrefix: Aff or Media
    @username: Return the @AffPrefix + sequence number of prefix
*/
declare @LenMax int, @LenPrefix int

select @LenPrefix = len(@AffPrefix)  

select @LenMax = max(len(username))  
from AffInfo with (nolock)  
where username like @AffPrefix + '%'
  
Select @username=max(username)  
from AffInfo with (nolock)
where len(username)= @LenMax
    and username like @AffPrefix + '%'
    
if(@LenMax is null or @username is null)
BEGIN
    set @username = @AffPrefix + '1001'  
    return
END     

  
select @username = isnull(SUBSTRING(@username, @LenPrefix + 1, len(@username) - @LenPrefix), '0') 
select @username = convert(varchar(20), convert(int, @username) + 1)  

if len(@username)<5  
BEGIN  
    select @Username = right('100' + @username, 4)  
END  
    select @username = @AffPrefix + @username
GO
/****** Object:  StoredProcedure [dbo].[Aff_FavoriteIns]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_FavoriteIns    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_FavoriteIns]  
 @AdminId int,  
 @AffId int,  
    @Language varchar(5)= 'en-US', 
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
--DB052.Affiliate_ZZun  
SET NOCOUNT ON  
/*--Favorite is no need to check permission  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@AdminId,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
*/  
if exists(select 1 from AdminFavorite with (nolock) where AdminID = @AdminID and AffID = @AffID)  
begin  
 select @ErrCode = 10021  
 select @ErrMsg = case @Language 
                    when 'en-US' then 'This affiliate has been added before.' 
                    when 'zh-CN' then N'這個工作夥伴之前已經新增了'
                    when 'zh-TW' then N'这个工作伙伴之前已经新增了'
                    else N'This affiliate has been added before.' 
                end
 return  
end  
  
insert into AdminFavorite(AdminID, AffID)  
values (@AdminID, @AffID)  
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error! Add favorite unsuccessfully!' 
                    when 'zh-CN' then N'錯誤!新增最愛不成功!'
                    when 'zh-TW' then N'错误！新增最爱不成功！'
                    else N'Error! Add favorite unsuccessfully!' 
                end, @ErrCode = 10020  
 return  
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_FavoriteDel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_FavoriteDel    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_FavoriteDel]  
 @AdminId int,  
 @AffId int,  
    @Language varchar(5)= 'en-US', 
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
--DB052.Affiliate_ZZun  
SET NOCOUNT ON  
/*--Favorite is no need to check permission  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@AdminId,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
*/    
if Not exists(select 1 from AdminFavorite with (nolock) where AdminID = @AdminID and AffID = @AffID)  
begin  
 select @ErrCode = 10021  
 select @ErrMsg = case @Language 
                    when 'en-US' then 'This affiliate does not exists.' 
                    when 'zh-CN' then N'這個工作夥伴不存在'
                    when 'zh-TW' then N'这个工作伙伴不存在'
                    else N'This affiliate does not exists.' 
                end
 return  
end  
  
delete AdminFavorite  
where AdminID = @AdminID and AffID = @AffID  
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error! Delete favorite unsuccessfully!' 
                    when 'zh-CN' then N'這個工作夥伴不存在'
                    when 'zh-TW' then N'这个工作伙伴不存在'
                    else N'Error! Delete favorite unsuccessfully!' 
                end, @ErrCode = 10020  
 return  
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainControlSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainControlSel    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_DomainControlSel]
    @CountryID nvarchar(10) = null
AS
/*
Created: 20121115@Johnny.Trinh
Task : Select Domain Control
DB: DB052.Affiliate_12BET
*/

select a.Id,
    d.CountryID,
    d.CountryName,
    b.DomainId as AffDomainId,
    b.DomainName as AffDomain,
    c.DomainId as RedirectDomainId,
    c.DomainName as RedirectDomain,
    a.CreateDate,
    e.Username as Creator,
    a.[Status]
from AffDomainControl a with (nolock)
    inner join AffDomain b with (nolock) on a.AffDomainId = b.DomainId
    inner join MemberDomain c with (nolock) on a.MemberDomainID = c.DomainID
    inner join Country d with (nolock) on a.CountryID = d.CountryID
    inner join AdminUser e with (nolock) on a.Creator = e.CustId
where ISNULL(@CountryID, a.CountryID) = a.CountryID
order by a.[Status] desc, b.DomainName
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainAffSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainAffSel    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_DomainAffSel]
    
AS
    Select a.DomainID, a.DomainName, b.Username as Creator, a.CreateDate
    From AffDomain a with(nolock)
        inner join AdminUser b with (nolock) on a.Creator = b.CustId
    order by a.DomainName
GO
/****** Object:  StoredProcedure [dbo].[Aff_CustomerSelOnline]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CustomerSelOnline    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_CustomerSelOnline]
    @custid int
AS
/*
Created: 20090122@Peter
Task : Select customer online list
DB: DB052.Affiliate_MYM
Original:

Param's Explanation:
• @userid: customer id
*/

SET NOCOUNT ON

SELECT * FROM on_user (nolock)
WHERE custid = @custid
ORDER BY on_userid
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainAffClientSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainAffClientSel    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE PROCEDURE [dbo].[Aff_DomainAffClientSel]
    @AffID int 
AS
    Select DISTINCT a.DomainName as DomainId, a.DomainName
    From AffDomain a with(nolock)
        inner join AffDomainControl b with(nolock) on a.DomainID = b.AffDomainID    
        inner join AffDetail d with(nolock) on (b.CountryID = d.CountryId  or b.CountryID='-')
    where b.Status = 1  and d.AffID=@AffID
GO
/****** Object:  StoredProcedure [dbo].[Aff_DeductedPercentSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DeductedPercentSel    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_DeductedPercentSel]
    @AffID [int],
    @DeductionName [nvarchar](50) = 'Marketing',
    @monthdate [smalldatetime],
    @Percent [float] = 0 OUTPUT
WITH EXECUTE AS CALLER
AS
/*
    Created: 200900911@VinhTrinh 
    Task: Get percentage depend on deduction type and AffId
    DB: DB052.Affiliate_MYM
    Revisions:          
          
    Param's Explanation:  
    • @AffID affliate Id  
    • @DeductionName Deduction type name 
*/  
SET NOCOUNT ON

Declare @DeductionId int

select @DeductionId = DTypeID from DeductionType nolock where DTypeName = @DeductionName

If @DeductionId is null
Begin
    select @Percent = 0
    return
End

If Datediff(m, @monthdate, Current_timestamp) = 0
Begin
    select @Percent = isnull(DeductedPercentage, 0)
    From DeductionSetting d with(nolock)
        inner join AffInfo a with(nolock) on d.GroupId = a.GroupId and a.AffId = @AffId
    Where DeductionId = @DeductionId
End
Else
Begin
    select @Percent = isnull(DeductedPercentage, 0)
    From DeductionSettingHistory d with(nolock)
        inner join AffInfo a with(nolock) on d.GroupId = a.GroupId and a.AffId = @AffId
    Where DeductionId = @DeductionId
        and d.MonthDate = @monthdate
End

select @Percent = isnull(@Percent, 0)
GO
/****** Object:  StoredProcedure [dbo].[Aff_DailyUpdatePlayerList]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DailyUpdatePlayerList    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_DailyUpdatePlayerList]
    @XmlData XML,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(2000) = '' OUTPUT
AS

SELECT @ErrMsg = '', @ErrCode = 0

DECLARE @TempTrans TABLE(AffId int, UserName varchar(30), CreatedDate datetime, Currency varchar(5))--Convert XML to data table

insert into @TempTrans--Convert xml to table
select      
    AffId,
    UserName,
    CreatedDate,
    Currency
from
    (Select
        [Table].[Column].value('./@AffID', 'int') as AffId,
        [Table].[Column].value('./@UserName', 'varchar(30)') as UserName,
        [Table].[Column].value('./@CreatedDate', 'datetime') as CreatedDate,
        [Table].[Column].value('./@Currency', 'varchar(5)') as Currency
    from @XmlData.nodes('/root/trans') as [Table]([Column])
    ) as tmp

-- If UserName is exists, omit this record
DELETE @TempTrans
WHERE UserName IN (SELECT UserName From MemberInfo)

BEGIN TRANSACTION
INSERT INTO MemberInfo (UserName, AffID, CreatedDate, Currency)
SELECT UserName, AffID, CreatedDate, Currency
FROM @TempTrans

IF @@Error <> 0 
    begin
        SELECT @ErrMsg = 'There was an error when updating data.', @ErrCode = 1008
        ROLLBACK TRANSACTION
        return
    end

COMMIT TRANSACTION
GO
/****** Object:  StoredProcedure [dbo].[Aff_CustomerSelAffUsename]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CustomerSelAffUsename    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_CustomerSelAffUsename]
    @AffUserName [nvarchar](30)
WITH EXECUTE AS CALLER
AS
/*Created: 20090317@VinhTrinh
Task : Select affiliate info for left panel
DB: DB052.Affiliate_MYM
Original: [Aff_CustomerSelAffInfo]
Revisions:
Param's Explanation:
• @Username : Affiliate username
*/

select Username
from AffInfo with(nolock)  
where UserName like '%' + @AffUserName + '%'
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountrySelByID]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CountrySelByID    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_CountrySelByID]    
    @ID VARCHAR(6)
AS
/*
Created: 20110221@Peter
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From Country (nolock)
where CountryID=@ID
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountrySelAll]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CountrySelAll    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_CountrySelAll]        
    @Name varchar(255) = NULL,    
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
--count nrows
select @NRows=count(1)
FROM Country N WITH (NOLOCK)    
where CountryName like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
    
SELECT CountryID, CountryName,Description,Icon,DisplayOrder,IsEnabled
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY CountryName asc) AS TheCount,
        C.*
    FROM Country C WITH (NOLOCK)        
    where CountryName like @Name
    ) x
where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountrySel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CountrySel    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_CountrySel]
    
AS
    Select CountryID, CountryName
    From Country (nolock) 
    order by CountryName
GO
/****** Object:  StoredProcedure [dbo].[Aff_CurrentDate]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CurrentDate    Script Date: 7/29/2013 1:41:15 AM ******/
-- =============================================
-- Author:        <Author,,Name>
-- Create date: <Create Date,,>
-- Description:    <Description,,>
-- =============================================
CREATE Procedure [dbo].[Aff_CurrentDate]
    -- Add the parameters for the stored procedure here
    
AS
BEGIN
    select dbo.Date_Only(getdate()),getdate()
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_CurrencyPrefixSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CurrencyPrefixSel    Script Date: 7/29/2013 1:41:15 AM ******/
-- =============================================
-- Author:        <Author,,Name>
-- Create date: <Create Date,,>
-- Description:    <Description,,>
-- =============================================
CREATE Procedure [dbo].[Aff_CurrencyPrefixSel]
    -- Add the parameters for the stored procedure here
    
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    select Prefix, ExchangeID from Exchange
    where Currency = (select SValue from SystemSettings where SName = 'SystemCurrency')
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_CurrencyListSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CurrencyListSel    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_CurrencyListSel]
    
  
AS

/*
    Created: 
    Task : 
    DB: DB052.Affiliate_MYM
    Revisions:
        

*/
SET NOCOUNT ON
Select ExchangeID,Code from Exchange
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountCurrenciesNotInExchange]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CountCurrenciesNotInExchange    Script Date: 7/29/2013 1:41:16 AM ******/
-- =============================================
-- Author:        Joseph
-- Create date: 21-02-2013
-- Description:    
-- =============================================
CREATE Procedure [dbo].[Aff_CountCurrenciesNotInExchange]
        
AS
BEGIN
    
    SET NOCOUNT ON;

    select Count(1) as Count from Currency c
    where c.CurrencyCode Not IN (select Code from Exchange)



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminSelByCustID]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminSelByCustID    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_Con_AdminSelByCustID]
    @CustID int
AS
/*
Task : Get user info
DB: DB03.bodb02 --> DB052.Affiliate_MYM
Original: [Aff_Con_AdminSelByCustID]
Revisions:
    - VinhTrinh@20100507: Get closed field from AdminUser instead of CustInfo 
    -- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON
SELECT ac.custid,ac.username,ac.firstname,ac.lastname,ac.groupid, ac.roleid, ac.closed,ac.userpwd
FROM AdminUser ac with(nolock)    
WHERE    ac.custid=@custid
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminNoteSel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminNoteSel    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_AdminNoteSel]    
    @AffID int,
    @NoteId int = null,
    @PageSize int = 50,
    @PageIndex int = 1,
    @TotalPages int = 0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: 20090122@TrangLe
Task : List Notes for Affiliate
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):
. @NoteId ID of note
. @AffID Affiliate ID
*/
SET NOCOUNT ON

--count nrows
select @NRows=count(1)
FROM AdminNotes N WITH (NOLOCK)    
where AffID = @AffID and
    (@NoteId is null or NoteId = @NoteId)

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
    
SELECT [Noteid], [Note], [UpdatedDate], AffID, [Updatedby], UpdateName
from (
    SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY Updateddate desc) AS TheCount,
        [Noteid], [Note], [UpdatedDate], N.AffID, [Updatedby], U.username as UpdateName
    FROM AdminNotes N WITH (NOLOCK)
        INNER JOIN AdminUser U WITH (NOLOCK) ON U.CUSTID=N.UPDATEDBY
    WHERE AffID = @AffID and
        (@NoteId is null or NoteId = @NoteId)
    ) x
where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_AddTranslation]    Script Date: 07/30/2013 04:21:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AddTranslation    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_AddTranslation]    
    @LanguageCode varchar(8), 
    @ResourceKey varchar(100), 
    @ResourceValue nvarchar(max),    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS

SET NOCOUNT ON
if exists (select 1 from [RefResources] with (updlock,serializable) where 
    RefID = 'Resource' ANd LanguageCode = @LanguageCode AND ResourceKey = @ResourceKey)
begin
   update [Affiliate_MYM].[dbo].[RefResources] set 
    ResourceValue = @ResourceValue
   where RefID = 'Resource' ANd LanguageCode = @LanguageCode AND ResourceKey = @ResourceKey
end
else
begin
   
INSERT INTO [Affiliate_MYM].[dbo].[RefResources]
           ([ResourceID]
           ,[RefID]
           ,[LanguageCode]
           ,[ResourceKey]
           ,[ResourceValue]
           )
     VALUES
           (newid()
           ,'Resource'
           ,@LanguageCode
           ,@ResourceKey
           ,@ResourceValue
           )

end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateCurrenciesSel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateCurrenciesSel    Script Date: 7/29/2013 1:41:16 AM ******/

-- =============================================
-- Author:        Peter
-- Create date: 19-02-2013
-- Description:    Get Affiliate Currencies Information
-- =============================================
CREATE Procedure [dbo].[Aff_AffiliateCurrenciesSel]
        
AS
BEGIN
    
    SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AffiliateCurrencies' and Type ='Meta')
    -- Insert statements for procedure here
    select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID,MultipliedBy from Currency (nolock)
    where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateInfoSel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateInfoSel    Script Date: 7/29/2013 1:41:16 AM ******/
-- =============================================
-- Author:        Smith
-- Create date: 2011/05/11
-- Description:    Get affiliate info
-- =============================================
CREATE Procedure [dbo].[Aff_AffiliateInfoSel]
    -- Add the parameters for the stored procedure here
    @affId int
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    -- Insert statements for procedure here
    SELECT * from AffInfo
    where AffID = @affId
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateInsClickStatistics]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateInsClickStatistics    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics]    
    @AffiliateID int,  
    @AffDomain nvarchar(256) = '',--Url is showed in affiliate site
    @PageCode varchar(50)='sports',    
    @LanguageCode varchar(6)='en-US',  
    @IP varchar(20) = '',  
    @Browser nvarchar(50) = '',  
    @URLReferrer nvarchar(300)=NULL, 
    @DomainReferrer nvarchar(300)=null,
    @OS nvarchar(50) = '',  
    @Device nvarchar(50) = '',  
    @BrowserVersion nvarchar(16) = '',  
    @BrowserResolution  nvarchar(16) = '',  
    @BrowserLanguage nvarchar(8) = '',  
    @UserAgent nvarchar(256) = '',  
    @Country nvarchar(256) = '',  
    @RedirectPage nvarchar(256)=NULL OUTPUT,
    @ClickID bigint = 0 OUTPUT,     
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,  
    @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
/*  Created: 20111005@Johnny  
Task : record clicking Banner action with a specific tracking code  
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
    - 20111228: Get RedirectURL follow affiliate
    - 20121120: Redirect to the main domain (except list affiliates with pagecode 12betcasino still redirect to 12betcasino.com)
	- 20130830@Don: Change way to get country code by using function [GetCountryIDFromIP] instead of retrieving from table IP
*/  

SET NOCOUNT ON  

Declare @AffUsername nvarchar(30), @CountryId varchar(11), @Default12Betdomain nvarchar(100), @IsCasino bit, @LicenseeId nvarchar(20), @LangcodeMemSite nvarchar(5), @ActualPageCode varchar(100)

select @ActualPageCode=SName from SystemSettings (nolock) where SValue=@PageCode and [Type]='CustomerPage'

select @ActualPageCode=coalesce(@ActualPageCode,'sports')


select @URLReferrer = coalesce(@URLReferrer, 'none')
select @LicenseeId = SValue from SystemSettings nolock where SName = 'LicenseeID'
select @LangcodeMemSite = Svalue from SystemSettings nolock where SName = @LanguageCode and [Type] = 'LangMapping'

select @AffUsername = ai.Username, @CountryId = CountryId
from AffDetail ad with(nolock)
    inner join AffInfo ai with(nolock) on ai.AffId = ad.AffId
where ai.AffId = @AffiliateID
    and status='Approved'

--check Affiliate ID  
if (@AffUsername is null)
begin  
    select @ErrCode=101,@ErrMsg='This affiliate does not exists. Please contact administrator!'                                            
    return                            
end 
  
 --Checking Input member IP
IF COALESCE(@IP, '') = ''  
begin  
    select @ErrCode=102, @ErrMsg='The IP is required. Please check!'   
    return               
end  
  
--Get redirect link
 
Declare @AffDomainId int, @AffDomainName nvarchar(255)

Select @AffDomainId = DomainID, @AffDomainName = DomainName
From AffDomain nolock 
where @AffDomain like '%' + DomainName + '%'

select @Default12Betdomain = b.DomainName--If redirect page is null => redirect to this default domain
From AffDomainControl a with (nolock)
    inner join MemberDomain b with (nolock) on a.MemberDomainID = b.DomainID
where a.AffDomainId = @AffDomainId 
    and a.CountryId = '-'
    and [status] = 1


Select @RedirectPage = b.DomainName
from AffDomainControl a with (nolock)
    inner join MemberDomain b with (nolock) on a.MemberDomainID = b.DomainID
where a.CountryID = @CountryId and a.AffDomainId = @AffDomainId and [status] = 1

--Replace Aff Domain by 12bet domain to redirect to 12bet site
Select @RedirectPage = 'http://' + ltrim(rtrim(isnull(@RedirectPage, @Default12Betdomain))) + '?btag=' + @LicenseeId + '_' + cast(@AffiliateID as varchar(15)) + '_{clickid}&lang=' + @LangcodeMemSite + '&act=' + @ActualPageCode


Declare @CountryCode varchar(5), @CurrentDate smalldatetime, @CurrentTime smalldatetime
Set @CountryCode = dbo.GetCountryIDFromIP(@IP)
select @CurrentTime = CURRENT_TIMESTAMP, @CurrentDate = CONVERT(varchar(10), CURRENT_TIMESTAMP, 120)

select top 1 @ClickId = ClickId--, @RedirectPage = RedirectURL
from [ClickStatistics] nolock 
where IP = @IP 
    and [Date] = @CurrentDate
    and [URLReferrer] = @URLReferrer
    and SportCode = @PageCode
    and LanguageCode = @LanguageCode
    and AffId = @AffiliateID
    and Browser = @Browser

if (@ClickId <> 0)
Begin
    Update [ClickStatistics] with(rowlock, updlock)
    set ClickCount = ClickCount + 1
        , [UpdatedTime] = @CurrentTime
    where ClickId = @ClickId

    Select @RedirectPage = replace(@RedirectPage, '{clickid}', @ClickID)
End
Else
Begin
    INSERT INTO [ClickStatistics]  
               ([AffID]
               ,[UpdatedTime]  
               ,[IP]  
               ,[Date]  
               ,[Browser]  
               ,[URLReferrer]
               ,[DomainReferrer]  
               ,[OS]  
               ,[Device]  
               ,[BrowserVersion]  
               ,[BrowserResolution]  
               ,[BrowserLanguage]  
               ,[UserAgent]  
               ,[Country]  
               ,[LanguageCode] 
               ,[SportCode] 
               ,[RedirectURL]
               ,[Status]
               ,[ClickCount])  
    VALUES  
               (@AffiliateID 
               ,@CurrentTime 
               ,@IP  
               ,@CurrentDate 
               ,@Browser  
               ,coalesce(@URLReferrer, 'none')  
               ,coalesce(@DomainReferrer, 'none')
               ,@OS  
               ,@Device  
               ,@BrowserVersion  
               ,@BrowserResolution  
               ,@BrowserLanguage  
               ,@UserAgent  
               ,coalesce(@CountryCode,'(not set)',@Country)  
               ,@LanguageCode--Only store vn for vietnamese
               ,@PageCode
               ,@RedirectPage--if not Casino aff => redirect to main domain
               ,0
               ,1
               )     
    
    select @ClickID = SCOPE_IDENTITY()

    select @RedirectPage = replace(@RedirectPage, '{clickid}', @ClickID)

    update [ClickStatistics] with (rowlock, updlock)
    set [RedirectURL] = @RedirectPage
    where clickId = @ClickID
End
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateLinkDomainSel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateLinkDomainSel    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateLinkDomainSel]      
    @AffID int,
    @DomainList nvarchar(max) ='http://link.spondemo.com'  OUTPUT
AS    
  
/*  
Task : Get All Domain Link for Affiliate
DB: DB052.Affiliate_MYM 
Original:
Revisions:        
 
Param's Explanation:    
    
*/    
SET NOCOUNT ON  
  declare @DefaultLinkDomain varchar(50)
  set @DefaultLinkDomain='http://link.spondemo.com'
  
  select @DomainList= (Select top (1) isnull(s.SValue,@DefaultLinkDomain)
  from  AffDetail a (nolock)
        left join SystemSettings s (nolock) on s.SName=a.CountryID         
  where a.AffID=@AffID and Type='AffiliateLinkDomainList')
  Select @DomainList=isnull(@DomainList,@DefaultLinkDomain)
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSupportedLanguagesSel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSupportedLanguagesSel    Script Date: 7/29/2013 1:41:16 AM ******/
-- =============================================
-- Author:        Peter
-- Create date: 30-05-2013
-- Description:    Get Affiliate Supported Languages Information
-- =============================================
CREATE Procedure [dbo].[Aff_AffiliateSupportedLanguagesSel]
 @Environment varchar(50) = 'Production' 
AS
BEGIN
 
 SET NOCOUNT ON;

    declare @Languages varchar(max)
    select @Languages=(select top(1) SValue from SystemSettings where SName = 'AFF_AffiliateSupportedLanguages' and Type ='Meta' and 
    ((@Environment = 'Production' and coalesce(Environment,'')='') or Environment = @Environment))
 -- Insert statements for procedure here
 select LanguageID , LanguageName from Language (nolock)
 where LanguageID in (select val from [dbo].[strSplit] ( @Languages, ',' ) ) 
 Order by [Order]



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelTrackingCode]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelTrackingCode    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateSelTrackingCode]
  @AffID int  
  as
  /*  
Created: 20090504@Peter
Task : Get List of Tracking Code for Affiliate
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
.@AffID: id of affiliate in the system,
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON  
begin
   select TrackingCode
   from TrackingCode (nolock)
   where AffID =  @AffID
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelMemberList]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelMemberList    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateSelMemberList]        
    @AffiliateID  int,
    @FromDate datetime=null,
    @ToDate datetime=null,
    @MemberType smallint=0,
    @PageSize int=50,    
    @PageIndex int=1,    
    @TotalPages int=0 OUTPUT,    
    @NRows int=0 OUTPUT  
AS
/*
    Created: 20100812@Peter    
    Task : Get list of member for Affiliate
    DB:  DB052.Affiliate_MYM for Testing
    Revisions:
        
        
    Param's Explanation:        
           @MemberType=1 : None-Deposited members only
           @MemberType=2 : Deposited members only.
           @MemberType=0 : All members.
           @FromDate=@ToDate : Get all members for all registerdate

*/
SET NOCOUNT ON

select @FromDate=dbo.Aff_GetStartDate(@FromDate)
select @ToDate=dbo.Aff_GetEndDate(@ToDate)

--count nrows    
select @NRows=count(1)    
 
 from MemberInfo c with (nolock)      
 where AffID=@AffiliateID
    and (case when @MemberType=0 then 1
              when @MemberType=1 and CreatedDate is null then 1
              when @MemberType=2 and CreatedDate is not null then 1
              else 0 
          end) = 1
          
   and (case when @FromDate is null and @ToDate is null then 1
             when RegisteredDate between @FromDate and @ToDate then 1
             else 0
         end)=1    
             
  
if(isnull(@NRows,0)=0)    
   return    
  
DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
       
       
 select firstname,lastname,username,email,currency,RegisteredDate,IsRemoved,Description
 from
 (
 
 select ROW_NUMBER() OVER(ORDER BY IsRemoved,RegisteredDate desc,username ) AS TheCount,  firstname,lastname,username,email,e.code as currency,RegisteredDate,IsRemoved, (case when IsRemoved=1 then (select 'Member is removed since ' + CAST(RemovedDate as varchar(50)) from MemberRemoval mr (nolock) where mr.username=c.username ) else '' end) as Description
 from MemberInfo c with (nolock)         
 inner join Exchange e with (nolock) on e.ExchangeID=c.Currency
 where AffID=@AffiliateID
    and (case when @MemberType=0 then 1
              when @MemberType=1 and c.CreatedDate is null then 1
              when @MemberType=2 and c.CreatedDate is not null then 1
              else 0 
          end) = 1
          
   and (case when @FromDate is null and @ToDate is null then 1
             when RegisteredDate between @FromDate and @ToDate then 1
             else 0
         end)=1    
     ) t
  where TheCount between @RowStart  and  @RowEnd
  order by IsRemoved,RegisteredDate desc,username
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelLogType]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelLogType    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateSelLogType]
    
AS
/*
    Created: 20100423@Jacob
    Task : Get all log type
    DB: DB052.Affiliate_MYM
    Revisions:
        - 20100423@Jacob initialize
        
    Param's Explanation:

*/
SET NOCOUNT ON;
    
SELECT [TypeID]
      ,[TypeName]
      ,[Description]
  FROM [LogType]
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateReportDetail]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateReportDetail    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateReportDetail]  
 @AffUsername varchar(50),  
 @AffId int = 0 OUTPUT,  
 @AffCurrency varchar(5) = 'MYR' OUTPUT,  
 @Fromdate datetime,  
 @Todate datetime,  
 @IsGetAll bit = 0  
AS  
/*  
 DB052.Affiliate_ZZun  
*/  
  
if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN  
  
select @AffId = AffId,  
 @AffCurrency = e.Code  
from AffInfo ai with(nolock)   
 inner join Exchange e with(nolock) on ai.Currency = e.ExchangeID  
where Username = @AffUsername  
  
if @AffId = 0 --Invalid AffUsername  
 return  
   
Declare @CurrDate datetime, @TmpToDate datetime  
  
select @CurrDate =  dbo.Aff_GetEndDate(current_timestamp),  
  @Fromdate = dbo.Aff_GetStartDate(@Fromdate),  
  @Todate = dbo.Aff_GetEndDate(@Todate)  
    
  
if @IsGetAll = 1  
Begin  
 select @FromDate = min(WinlostDate) from AffDailySummary with (nolock)  
 select @ToDate = dbo.Aff_GetEndDate(current_timestamp)  
   
 select @TmpToDate =@CurrDate--To date for new way calculate winlost  
End  
Else  
Begin  
 select @TmpToDate = case when @ToDate >= @CurrDate then @CurrDate else @ToDate end  
End  
  
  
select WinlostDate,  
 b.AffExRate,  
 e.Code as Currency,  
 Sum(b.Deposit) as Deposit,  
 Sum(b.Withdrawal) as Withdrawal,  
 Sum(b.Turnover) as Turnover,  
 Sum(b.Winlost) as Winlost,  
 Sum(b.Bonus) as Bonus,  
 Sum(b.PSP) as PSP,  
 Sum(b.Adjustment) as Adjustment,  
 Sum(b.AffAdjustment) as AffAdjustment,  
 Sum(b.AffWithdrawal) as AffWithdrawal,  
 Sum(b.AffBF) as AffBF  
From   
 (   
  Select WinlostDate,--Calculate winlost member below Aff in MemberDaily and AffCommission table  
   MemCurrency as Currency,  
   AffExRate as AffExRate,--convert exchange rate from member to system currency  
   Sum(MemDeposit) as Deposit,  
   Sum(MemWithdrawal) as Withdrawal,  
   Sum(MemTurnover) as Turnover,  
   Sum(MemWinlost) as Winlost,  
   Sum(MemBonus) as Bonus,  
   Sum(MemPSP) as PSP,  
   Sum(MemAdjustment) as Adjustment,  
   0 as AffAdjustment,  
   0 as AffWithdrawal,  
   sum(AffNetWinlost) as AffBF  
  From AffDaily with(nolock)  
  Where WinlostDate Between @FromDate and @TmpToDate  
   and AffId = @AffId  
  Group by WinlostDate, MemCurrency, AffExRate    
    
  Union All  
    
  select dateadd(d, datediff(d, 0, a.TransDate), 0) as WinlostDate,--Get Aff Adjusment and Aff Widthrawal  
   a.AffCurrency as Currency,--Currency of aff  
   1 as AffExRate,--convert exchange rate from affiliate to system currency  
   0 as Deposit,  
   0 as Withdrawal,  
   0 as Turnover,  
   0 as Winlost,  
   0 as Bonus,  
   0 as PSP,  
   0 as Adjustment,  
   Sum(case when Transtype = 203 then Amount else 0 end) as AffAdjustment,  
   Sum(case when Transtype = 202 then Amount else 0 end) as AffWithdrawal,  
   0 as AffBF  
  From AffTrans a with (nolock)  
  where (@IsGetAll = 1 or TransDate between @FromDate and @ToDate)  
   and Transtype in (202, 203)  
   and status in ('Pending', 'Approved', 'Completed')  
   and a.AffId = @AffId  
  Group by dateadd(d, datediff(d, 0, a.TransDate), 0), a.AffCurrency, SysExRate  
 ) b   
   inner join Exchange e (nolock) on e.ExchangeID=b.Currency  
Group by WinlostDate, b.AffExRate,e.Code   
order by WinlostDate
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateReport]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateReport    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateReport]  
 @PreferredLanguage varchar(11) = null,  
 @Fromdate datetime,  
 @Todate datetime,  
 @Currency smallint = 0,  
 @IsGetAll bit,  
 @AffType tinyint = 0  
AS  
/*  
Created: @VinhTrinh  
Task : Get report by date for each affiliate.  
DB: DB052.Affiliate_MYM  
Original: [Aff_AffiliateReport]  
Revisions:  
      
Param's Explanation:  
 • @Fromdate Time search From  
 • @Todate Time search To,  
 • @IsGetAll if getall = 1 => get data in all date,  
*/  
Set Nocount On  
Select @FromDate = dbo.Date_Only(@FromDate), @ToDate = dbo.Date_Only(@ToDate)  
Declare @CurrDate datetime, @TmpToDate datetime  
  
if(@Fromdate > @Todate or @Fromdate > current_timestamp) RETURN  
  
select @CurrDate =  dbo.Aff_GetEndDate(current_timestamp),  
  @Fromdate = dbo.Aff_GetStartDate(@Fromdate),  
  @Todate = dbo.Aff_GetEndDate(@Todate)  
   
if @IsGetAll = 1  
Begin  
 select @FromDate = min(WinlostDate) from AffDailySummary with (nolock)  
 select @ToDate = @CurrDate  
   
 select @TmpToDate = @CurrDate--To date for new way calculate winlost  
End  
Else  
Begin  
 select @TmpToDate = case when @ToDate >= @CurrDate then @CurrDate else @ToDate end   
End  
  
 --select @FromDate as FromDate, @ToDate as ToDate , @TmpFromDate as TmpFromDate, @TmpToDate as TmpToDate, @TmpOldWayDate as TmpOldWayDate  
   
Create table #AffTemp(AffID int PRIMARY KEY,UserName varchar(100),Currency varchar(10),Prefix varchar(10),  
Deposit money,  
 Withdrawal money,  
 Turnover money,  
 Winlost money,  
 Bonus money,  
 PSP money,  
 Adjustment money,  
 AffAdjustment money,  
 AffWithdrawal money,  
 AffBF money  
)  
  
insert into #AffTemp(AffID ,UserName,Currency,Prefix)  
Select ai.AffId, ai.Username, e.Code, e.Prefix  
From AffDetail ad with (nolock)  
 inner join AffInfo ai with(nolock) on ad.AffId = ai.AffId    
 inner join Exchange e with(nolock) on ai.Currency = e.ExchangeID  
where (@AffType=0 or ai.AffType = @AffType)  
  and (@PreferredLanguage is null or @PreferredLanguage= PreferredLanguage)  
  and (@Currency=0 or @Currency= ai.Currency)  
/*  
update at  
set at.Deposit=Sum(b.Deposit),  
    at.Withdrawal=Sum(b.Withdrawal),  
    at.Turnover=Sum(b.Turnover)   
from #AffTemp at  
    inner join AffDailySummary ad with(nolock) on ad.AffID=at.AffID  
Where ad.WinlostDate Between @FromDate and @TmpToDate  
group by ad.affid*/  
  
select t.AffId,  
 at.Username,  
 at.Currency,  
 at.Prefix,  
 Sum(t.Deposit) as Deposit,  
 Sum(t.Withdrawal) as Withdrawal,  
 Sum(t.Turnover) as Turnover,  
 Sum(t.Winlost) as Winlost,  
 Sum(t.Bonus) as Bonus,  
 Sum(t.PSP) as PSP,  
 Sum(t.Adjustment) as Adjustment,  
 Sum(t.AffAdjustment) as AffAdjustment,  
 Sum(t.AffWithdrawal) as AffWithdrawal,  
 Sum(t.AffBF) as AffBF,  
 aft.Name as AffTypeName  
From   
 (  
   
  Select a.AffId,--Calculate winlost member below Aff in MemberDaily  
   Sum(MemDeposit_aff) as Deposit,  
   Sum(MemWithdrawal_aff) as Withdrawal,  
   Sum(MemTurnover_aff) as Turnover,  
   Sum(MemWinlost_aff) as Winlost,  
   Sum(MemBonus_aff) as Bonus,  
   Sum(MemPSP_aff) as PSP,  
   Sum(MemAdjustment_aff) as Adjustment,  
   0 as AffAdjustment,  
   0 as AffWithdrawal,  
   sum(AffNetWinlost_aff) as AffBF     
  From AffDailySummary ad with(nolock)  
             inner join #AffTemp a on  a.AffID=ad.AffID             
  Where WinlostDate Between @FromDate and @TmpToDate  
  Group by a.AffID    
  Union All    
  select a.AffId,--Get Aff Adjusment and Aff Widthrawal  
   0 as Deposit,  
   0 as Withdrawal,  
   0 as Turnover,  
   0 as Winlost,  
   0 as Bonus,  
   0 as PSP,  
   0 as Adjustment,  
   Sum(case when Transtype = 203 then Amount else 0 end) as AffAdjustment,  
   Sum(case when Transtype = 202 then abs(Amount)  else 0 end) as AffWithdrawal,  
   0 as AffBF  
  From AffTrans a with (nolock)  
    inner join #AffTemp a1 on  a1.AffID=a.AffID  
  where (@IsGetAll = 1 or TransDate between @FromDate and @ToDate)  
   and Transtype in (202, 203)  
   and status in ('Pending', 'Approved', 'Completed')  
  Group by a.AffId  
 ) t  
inner join #AffTemp at on at.affid=t.affid  
inner join AffInfo ai with(nolock) on at.AffID = ai.AffID  
left join AffType aft with(nolock) on ai.AffType = aft.TypeID  
  
Group by t.AffId, at.Username, at.Currency, at.Prefix,aft.Name  
Order by t.AffId  
  
drop table #AffTemp
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelEditInfo]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelEditInfo    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateSelEditInfo]
    @AffId int,
    @GetBalance bit = 0,
    @AFF_MinWire  MONEY = 0 OUTPUT,
    @Aff_MinNeteller MONEY = 0 OUTPUT,
    @AFF_MinCheque MONEY = 0 OUTPUT,
    @AFF_MinMoneybookers MONEY = 0 OUTPUT,
    @AFF_MinPlayer MONEY = 0 OUTPUT
AS
-- DB052.Affiliate_MYM
SET NOCOUNT ON
Declare @currencyName varchar(5)

Select @currencyName = Currency
from AffInfo with (nolock)
where AffId = @AffId

Select    @AFF_MinWire = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinWire'+@currencyName
Select    @Aff_MinNeteller = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinNeteller'+@currencyName
Select    @AFF_MinCheque = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinCheque'+@currencyName 
Select    @AFF_MinMoneybookers = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinMoneybookers'+@currencyName
Select    @AFF_MinPlayer = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinPlayer'+@currencyName

SELECT     
    ai.AffId, 
    ai.username,    
    ai.username2,
    ad.gender,
    ai.firstname,
    ai.lastname,
    ai.Status,
    ai.email,
    ad.phone,
    ad.mobilephone,
    ad.address,
    ad.city,
    ad.state,
    ad.postal,
    ad.countryID,    
    ad.SiteURL ,
    ad.MoreSiteURLs,
    ad.PreferredPayment, --Player, Neteller, Moneybookers, Wire, Cheque
    ad.PreferredLanguage,
    ai.Currency,
    ad.Player_Username,
    ad.Neteller_AccountID,
    ad.Moneybookers_Email,
    ad.Wire_BankName,
    ad.Wire_BankAddress,
    ad.Wire_SwiftCode,
    ad.Wire_AccountName,    
    ad.Wire_AccountNo,
    ad.Cheque_FullName,
    ad.Cheque_Address,
    ad.Cheque_City,
    ad.Cheque_State,
    ad.Cheque_Postal,
    ad.Cheque_Country,
    ad.question,
    ad.answer,
    ad.mailoption,
    --Do not allow edit when status is approved    
    (case when ai.Status in ('pending','disapproved') then 1 else 0 end) as IsCurrencyEditable
    --(case when ai.Status in ('pending','disapproved') or not exists (select top(1)  1 from Memberdaily (nolock) where AffID = ai.AffID ) then 1 else 0 end) as IsCurrencyEditable        
FROM 
    AffInfo ai with (nolock) 
    inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE 
    ai.AffId=@AffID
ORDER BY ai.username
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelAffInfo]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelAffInfo    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateSelAffInfo]
AS
--DB052.Affiliate_MYM

Select AffId, Username
From AffInfo with (nolock)
--Where Status = 'Approved'
order by Username
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_CheckPermissionRead]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_CheckPermissionRead    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_CheckPermissionRead]
    @CustID int, 
    @FuncID int=null,
    @FuncName nvarchar(50)='',
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20100904@Johnny
    Task : Check permission for access Customer Page in aff amdin
    DB: DB003.bodb02 --> DB052.Affiliate_ZZun

    Revisions:
        -- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
    Param's Explanation:
    • @CustID : Aff Admin CustID 
    • @FuncID : Function ID
    • @FuncName : Function Name
        
    -- Permission: bitwise(OR) permission of the group that user belong to and permission of this user
    -- IsAllow: 1:Readonly, 2:Host, 3:All
    -- Just check permission for admin, ignore when roleid < 5
*/
    IF @FuncID is null
        Select @FuncID=funcid from AffFunctionInfo with(nolock) where System = 'Affiliate' and FuncName=@Funcname
    
     
    Declare @roleid tinyint,@IsAllow tinyint
    Select @roleid = roleid From customer with(nolock) where custid=@custid
    IF @RoleID Between 5 and 10
    BEGIN 
        SELECT @IsAllow=(isnull(mp.policy,0)|isnull(gp.policy,0)) & isnull(fi.FuncRender,0)
        FROM AdminUser ac with(nolock) 
            Left JOIN AffFunctionInfo fi with(nolock) on fi.funcid=@funcid
            LEFT JOIN AffMemberPolicy mp with(nolock) on mp.custid=ac.custid and mp.funcid=@funcid
            LEFT JOIN AffGroupPolicy gp with(nolock) on gp.groupid=ac.groupid and gp.funcid=@funcid
        WHERE ac.Custid=@Custid and ac.closed=0
        SELECT @IsAllow = isnull(@IsAllow,0)
    END
    ELSE IF @Roleid > 1
    BEGIN
        SELECT @IsAllow=2
    END 
    ELSE
        SELECT @IsAllow=0
        
    IF @IsAllow < 1
    BEGIN
        SELECT @ErrMsg =  case @Language
                            when 'en-US' then N'You are not authorized on this function'
                            when 'zh-CN' then N'You are not authorized on this function'
                            when 'J' then N'You are not authorized on this function'
                            else N'You are not authorized on this function'
                            --else N'You are not authorized to create/edit this information'
                        end, @ErrCode = 500
        RETURN 
    END
    ELSE
        SET @ErrCode=0
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_CheckPermission]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_CheckPermission    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_CheckPermission]
    @CustID int, 
    @FuncID int=null,
    @FuncName nvarchar(50)='',
    @System nvarchar(50) = 'AFFILIATE',
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created by: []
    Task: Check permission by CustID and Function 
    DB: DB03.BODB02 --> DB052.Affiliate_ZZun
    
    Revisions:
        - 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
        - 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
*/
    SET NOCOUNT ON 
    IF @FuncID is null
        Select @FuncID=funcid from AffFunctionInfo with(nolock) where System = @System and FuncName=@Funcname
    
    -- Permission: bitwise(OR) permission of the group that user belong to and permission of this user
    -- IsAllow: 1:Readonly, 2:Host, 3:All
    
    Declare @roleid tinyint,@IsAllow tinyint
    
    IF exists(select 1 from AdminUser (nolock) where custid=@CustID)
    BEGIN 
        
            SELECT @IsAllow=(isnull(mp.policy,0)|isnull(gp.policy,0)) & isnull(fi.FuncRender,0)
            FROM AdminUser ac with(nolock) 
                --inner join custinfo ci with(nolock) on ac.custid=ci.custid
                Left JOIN AffFunctionInfo fi with(nolock) on fi.funcid=@funcid
                LEFT JOIN AffMemberPolicy mp with(nolock) on mp.custid=ac.custid and mp.funcid=@funcid
                LEFT JOIN AffGroupPolicy gp with(nolock) on gp.groupid=ac.groupid and gp.funcid=@funcid
            WHERE ac.Custid=@Custid and ac.closed=0
            SELECT @IsAllow = isnull(@IsAllow,0)
        
    END
    ELSE IF exists(select 1 from AffInfo (nolock) where AffID=@CustID)
    BEGIN
        SELECT @IsAllow=2
    END 
    ELSE
        SELECT @IsAllow=0
        
    IF @IsAllow <2
    BEGIN
        SELECT @ErrMsg =  case @Language
                            when 'en-US' then N'You are not authorized on this function'
                            when 'zh-CN' then N'You are not authorized on this function'
                            when 'J' then N'You are not authorized on this function'
                            else N'You are not authorized on this function'
                            --else N'You are not authorized to create/edit this information'
                        end, @ErrCode = 500
        RETURN 
    END
    ELSE
        SET @ErrCode=0
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_Batch_AdminPolicySel]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_Batch_AdminPolicySel    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_Con_Batch_AdminPolicySel]
    @CustIDs nvarchar(4000),
    @GroupID int = NULL OUTPUT    
AS
--DB03.bodb02 --> DB052.Affiliate_MYM
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM

SET NOCOUNT ON
Select top 1 @GroupID = GroupID From AdminUser with(nolock) where Custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
Declare @Tmp table(funcid int, funcname varchar(50), funcdesc varchar(50), policy int, gpolicy int, parentid int, SubFuncCount int, DisplayOrder int)

insert into @Tmp
SELECT fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy as gpolicy,fi.parentid ,count(fip.funcID) as SubFuncCount, fi.DisplayOrder
FROM AffFunctionInfo fi with(nolock) 
    INNER JOIN  
        (SELECT funcid,min(policy) as policy,ac.groupid as groupid
        FROM AffMemberPolicy mp with(nolock) inner join AdminUser ac with(nolock) on ac.custid=mp.custid
        WHERE mp.custid in (SELECT val FROM dbo.strSplit_Key(@CustIDs,','))
        GROUP BY mp.funcid,ac.groupid) f on fi.funcid=f.funcid
    INNER JOIN AffGroupPolicy gp with(nolock)    on gp.groupid=f.groupid and gp.funcID=f.funcID
    left join AffFunctionInfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
group by fi.funcid,fi.funcname, fi.funcdesc,f.policy ,gp.policy,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid, count(fip.funcID) DESC, fi.DisplayOrder

Declare @GroupIT varchar(50)

select @GroupIT = [dbo].[Aff_Con_GetGroupItID]()

if(@GroupID <> @GroupIT)
Begin
    delete @Tmp
    where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelGeneralInfo]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelGeneralInfo    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateSelGeneralInfo]
    @Username nvarchar(30)    
AS
/*
    Created: 20090730@Peter
    Task : Select affiliate info for left panel
    DB: DB052.Affiliate_MYM

    Revisions:
      .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_MYM
                        Remove the theory of pending commission and CurrCommEarning   
                        Get PreferredPayment to check approve 
    Param's Explanation:
    • @Username : Affiliate username
*/
SET NOCOUNT ON
Declare @affID int
Select @affID = affID from AffInfo with(nolock) where username = @Username

if @affID is null
Begin
    Select @affID = affID from AffInfo with(nolock) where username2 = @Username
    if @affID is null return
End


    
SELECT     --Get affiliate info
    IsClosed as closed,
    IsLocked,     
    a.Username,        
    a.AffID,
    firstname,
    lastname,
    '' as Prefix,
    gender,
    email,
    phone,
    mobilephone,
    siteurl,
    lastLoginDate,
    lastLoginIP as lastloginip,    
    PreferredLanguage,
    PreferredPayment,
    Player_Username,
    status,
    MailOption,--Johnny Add to send relevant email format.
    isnull(c.groupname,'') as groupname,    
    isnull(c.groupid,-1) as groupid,
    isnull(dbo.Aff_GetAffBalance(@AffId), 0) as BalBroughtForward,
    AffType,
    e.CurrencyCode as currency
FROM AffInfo a with(nolock)     
    inner join AffDetail d on a.AffID = d.AffID
    inner join Currency e with(nolock) on a.Currency = e.CurrencyID
    left join CommGroup c (nolock)  on c.groupid=a.groupid
WHERE a.AffID=@AffID     

SELECT * FROM on_user (nolock)
WHERE custid = @AffID
ORDER BY on_userid
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelFavorite]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelFavorite    Script Date: 7/29/2013 1:41:18 AM ******/
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelFavorite    Script Date: 5/3/2013 10:57:05 AM ******/
CREATE PROCEDURE [dbo].[Aff_AffiliateSelFavorite]  
	@UserId int=-1,
	@GroupID int=-1,
	@Currency smallint=0,
	@GroupName nvarchar(100)=NULL Output,
	@Status varchar(30),  
	@AffID int=-1,
	@UserName nvarchar(50)=NULL,  
	@Email nvarchar(50)=NULL,  
	@IsClosed bit = NULL,  
	@IsLocked bit = NULL,
	@AffType tinyint = 0,
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT  
AS    
/*
Task : Get All Favorite Affiliate for a specific page  
DB: 
Original:[Aff_CustomerSelAffiliate]  
Revisions:      
 - 20100208@Johnny: show one more column PreferredLanguage
 - 20130806@Joseph: show one more column IsLocked
 
                
Param's Explanation:  
. @GroupID : if @GroupID<>-1 : only search by GroupID and this function is linked from Commission Group Page
. @GroupName : Search by GroupName
• @Status : pending,Approved,disapproved  
• @UserName : Affiliate name you want to default value=null :search all  
• @Email : Email you want to search - default value=null :search all  
• @PageSize : Number of rows should be returned per each page  
• @PageIndex : Current page   
• @TotalPages OUTPUT : total of pages for this search  
  
• @NRows OUTPUT,--total of rows  
  
*/  
SET NOCOUNT ON
select @UserName= '%' + Coalesce(@UserName, '') + '%'     
select @Email= '%' + Coalesce(@Email, '') + '%'  
select @Status= Coalesce(@Status, '')  

declare @GroupIDList table(GroupID int)

if(isnull(@GroupName,'')<>'' )
 begin   
    if(lower(@GroupName)='[none]')
    begin
		insert into @GroupIDList(GroupID)    
		select GroupID 
		from CommGroup (nolock)
		where GroupID>1000 and  (@Currency  =0 or Currency = @Currency ) 
    end
    else
    begin
		declare @grName nvarchar(100)
		select @grName= '%' + Coalesce(@GroupName, '') + '%'   
		insert into @GroupIDList(GroupID)    
		select GroupID 
		from CommGroup (nolock)
		where GroupName like @grName and  (@Currency  =0 or Currency = @Currency )  
    end
	if(@@ROWCOUNT=0)
	begin
	   return	
	end   
 end
  
  
--count nrows    
select @NRows=count(1)    
FROM     
	AffInfo ai with (nolock)  
	inner join AdminFavorite f with (nolock) on ai.AffId = f.AffId 
WHERE f.AdminId = @UserId  
    and (case when @AffID = -1 then 1   
                  when ai.AffId=@AffID then 1  
                  else 0  
              end) =1   
    and (  
		case  
			when @Status='' then 1    
			when @Status='approved' and  Status=@Status and  
				(  
				case when @Isclosed is null and Isclosed=0 and @IsLocked is null and IsLocked=0 then 1  
					when @IsClosed is not null and IsClosed=@Isclosed then 1  
					when @IsLocked is not null and IsLocked=@IsLocked then 1  
					else 0  
				end     
				)=1 then 1  
			when @Status<>'approved' and Status=@Status then 1  
		else 0  
		end  
	)=1    
	and Username like @UserName
	and Email like @Email
	and  (@Currency  =0 or Currency = @Currency )
	and (case when @GroupID > 0 and GroupID<1000 and GroupID=@GroupID then 1
	          when @GroupID =0 and GroupID>1000 then 1
              when @GroupID=-1 and  isnull(@GroupName,'')='' then 1
	          when exists(select 1 from @GroupIDList) and GroupID in (Select GroupID from @GroupIDList) then 1
	          else 0
          end 
	    )=1	
	and (@AffType=0 or AffType = @AffType)
    
if(isnull(@NRows,0)=0)    
   return    
       
DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
 
 
DECLARE @TempMember TABLE(AffId int PRIMARY KEY, UserName nvarchar(30), 
			FirstName nvarchar(50), LastName nvarchar(50), PreferredLanguage varchar(11),
			 IsClosed bit,IsLocked bit, ApprovedDate smalldatetime, GroupId int, 
			 Currency tinyint,Status varchar(30),AffTypeName varchar(50) )

insert into @TempMember(AffId, UserName, FirstName, LastName, PreferredLanguage, 
IsClosed,IsLocked, ApprovedDate, GroupId,currency,Status,AffTypeName) 
select m.AffId, m.username, m.firstname, m.lastname, m.PreferredLanguage,
 m.IsClosed,m.IsLocked, m.ApprovedDate, m.GroupId ,m.currency,m.Status,m.AffTypeName
from
	(select ROW_NUMBER() OVER(ORDER BY IsClosed, ai.Username) AS TheCount,
		ai.AffID, ai.UserName, ai.FirstName, ai.LastName, ad.PreferredLanguage,
		 ai.IsClosed,ai.IsLocked, ai.ApprovedDate, ai.GroupId,ai.currency,ai.Status,at.Name as AffTypeName
	from AffInfo ai with (nolock)		
		inner join AffDetail ad with(nolock) on ai.AffId = ad.AffId
		inner join AdminFavorite f with (nolock) on ai.AffId = f.AffId   
		left join AffType at with(nolock) on ai.AffType = at.TypeID
	where f.AdminId = @UserId
		and (case when @AffID = -1 then 1   
                  when ai.AffId=@AffID then 1  
                  else 0  
              end) =1   
    and (  
		case  
			when @Status='' then 1    
			when @Status='approved' and  Status=@Status and  
				(  
				case when @Isclosed is null and Isclosed=0 and @IsLocked is null and IsLocked=0 then 1  
					when @IsClosed is not null and IsClosed=@Isclosed then 1  
					when @IsLocked is not null and IsLocked=@IsLocked then 1  
					else 0  
				end     
				)=1 then 1  
			when @Status<>'approved' and Status=@Status then 1  
		else 0  
		end  
	)=1  
	and ai.Username like @UserName
	and ai.Email like @Email
	and  (@Currency  =0 or Currency = @Currency )
	and (case when @GroupID > 0 and GroupID<1000 and GroupID=@GroupID then 1
	          when @GroupID =0 and GroupID>1000 then 1
              when @GroupID=-1 and  isnull(@GroupName,'')='' then 1
	          when exists(select 1 from @GroupIDList) and GroupID in (Select GroupID from @GroupIDList) then 1
	          else 0
          end 
	    )=1	
	and (@AffType=0 or AffType = @AffType)
	)m
where m.TheCount between @RowStart and @RowEnd 
        
if(@GroupID>0)
begin
  select @GroupName=GroupName
  from CommGroup with (nolock)
  where @GroupID=GroupID
end

if(@GroupID=0)
  select @GroupName='[None]'
  
select x.AffId, x.username, x.firstname, x.lastname, x.PreferredLanguage, x.IsClosed,x.IsLocked, isnull(cg.GroupName, '[None]') as GroupName,   
	isnull(dbo.Aff_CountMember(x.AffID),0) as NoOfMember, 
	isnull(dbo.Aff_GetAffBalance(x.AffID),0) as BalanceBF, ApprovedDate,
	 isnull(x.Affid, 0) as Favorite,x.GroupId,e.CurrencyCode as currency,'' as Prefix,x.Status,x.AffTypeName
from @TempMember x  	
	left join CommGroup cg with (nolock) on x.GroupId = cg.GroupId  
	left join Currency e with (nolock) on e.CurrencyId=cg.Currency	
ORDER BY IsClosed, Username
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSel    Script Date: 7/29/2013 1:41:18 AM ******/
/****** Object:  Stored Procedure dbo.Aff_AffiliateSel    Script Date: 5/3/2013 10:57:05 AM ******/
CREATE PROCEDURE [dbo].[Aff_AffiliateSel]    
    @UserId int=-1,    
    @GroupID int=-1,    
    @Currency int=0,  
    @GroupName nvarchar(100)=NULL Output,    
    @Status varchar(30),      
    @AffID int=-1,    
    @UserName nvarchar(50)=NULL,      
    @Email nvarchar(50)=NULL,   
    @IsClosed bit = NULL,  
    @IsLocked bit = NULL,  
    @AffType tinyint = 0,  
    @PageSize int=50,      
    @PageIndex int=1,      
    @TotalPages int=0 OUTPUT,      
    @NRows int=0 OUTPUT      
AS      
    
/*    
Task : Get All Affiliate for a specific page      
DB:    
Original:[Aff_CustomerSelAffiliate]      
Revisions:          
 - 20100208@Johnny: show one more column PreferredLanguage  
                    
Param's Explanation:      
. @GroupID : if @GroupID<>-1 : only search by GroupID and this function is linked from Commission Group Page    
. @GroupName : Search by GroupName    
• @Status : pending,Approved,disapproved      
• @UserName : Affiliate name you want to default value=null :search all      
• @Email : Email you want to search - default value=null :search all      
• @PageSize : Number of rows should be returned per each page      
• @PageIndex : Current page       
• @TotalPages OUTPUT : total of pages for this search          
• @NRows OUTPUT,--total of rows      
      
*/      
SET NOCOUNT ON    
select @UserName= '%' + Coalesce(@UserName, '') + '%'       
select @Email= '%' + Coalesce(@Email, '') + '%'    
  
select @Status= Coalesce(@Status, '')   
    
declare @GroupIDList table(GroupID int)    
    
if(isnull(@GroupName,'')<>'' )    
begin       
    if(lower(@GroupName)='[none]')    
    begin    
        insert into @GroupIDList(GroupID)        
        select GroupID     
        from CommGroup (nolock)    
        where GroupID>1000 and  (@Currency  =0 or Currency = @Currency )   
    end    
    else    
        begin    
        declare @grName nvarchar(100)    
        select @grName= '%' + rtrim(ltrim(Coalesce(@GroupName, ''))) + '%'   
            
        insert into @GroupIDList(GroupID)        
        select GroupID     
        from CommGroup (nolock)    
        where GroupName like @grName and (@Currency  =0 or Currency = @Currency )    
    end   
     
    if(@@ROWCOUNT=0)    
    begin    
        return     
    end       
end    
    
    
--count nrows      
select @NRows=count(1)      
FROM       
 AffInfo ai with (nolock)    
WHERE       
    (case when @AffID = -1 then 1       
                  when ai.AffId=@AffID then 1      
                  else 0      
              end) =1       
    and (  
        case  
            when @Status='' then 1    
            when @Status='approved' and  Status=@Status and  
                (  
                case when @IsClosed is null and IsClosed=0 and @IsLocked is null and IsLocked =0 then 1  
                    when @IsClosed is not null and IsClosed=@IsClosed then 1  
                    when @IsLocked is not null and IsLocked=@IsLocked then 1  
                    else 0  
                end     
                )=1 then 1  
            when @Status<>'approved' and Status=@Status then 1  
        else 0  
        end  
    )=1    
    and (case when @GroupID > 0 and GroupID<1000 and GroupID=@GroupID then 1    

                when @GroupID =0 and GroupID>1000 then 1    
                    when @GroupID=-1 and  isnull(@GroupName,'')='' then 1    
                when @GroupID=-1 and exists(select 1 from @GroupIDList) and GroupID in (Select GroupID from @GroupIDList) then 1    
                else 0    
                end     
            ) = 1    
    and ai.Username like @UserName    
    and Email like @Email    
    and  (@Currency  =0 or Currency = @Currency )
    and (@AffType=0 or AffType = @AffType)  
  
  
if(isnull(@NRows,0)=0)      
   return      
    
DECLARE @RowStart int, @RowEnd int       
      
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,      
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1         
          
DECLARE @TempMember TABLE(AffId int PRIMARY KEY, UserName nvarchar(30), 
        FirstName nvarchar(50), LastName nvarchar(50), 
        PreferredLanguage varchar(11), IsClosed bit, ApprovedDate smalldatetime, GroupId int,
         RegisteredDate smalldatetime,Currency tinyint,Status nvarchar(50), 
         IsLocked bit,AffTypeName varchar(50))    
    
insert into @TempMember(AffId, UserName, FirstName, LastName, 
    PreferredLanguage, IsClosed, ApprovedDate, GroupId, 
    RegisteredDate,Currency,Status,IsLocked,AffTypeName)    
select m.AffId, m.username, m.firstname, m.lastname,
     m.PreferredLanguage, m.IsClosed, m.ApprovedDate, m.GroupId, 
     m.RegisteredDate,m.currency,m.Status,m.IsLocked,m.AffTypeName
from    
    (
    select ROW_NUMBER() OVER(ORDER BY ai.AffId) AS TheCount,    
            ai.AffID, ai.UserName, ai.FirstName, ai.LastName, ad.PreferredLanguage, 
            ai.IsClosed, ai.ApprovedDate, ai.GroupId, ai.RegisteredDate,ai.Currency,
            ai.Status,ai.IsLocked,at.Name as AffTypeName    
    from AffInfo ai with (nolock)    
        left join AffDetail ad with(nolock) on ai.AffId = ad.AffId  
        left join AffType at with(nolock) on ai.AffType = at.TypeID
    where (case when @AffID = -1 then 1       
                when ai.AffId=@AffID then 1      
            else 0      
            end) =1       
        and (   
            case  
                when @Status='' then 1    
                when @Status='approved' and   Status=@Status and  
                    (  
                        case when @IsClosed is null and IsClosed=0 and @IsLocked is null and IsLocked=0 then 1  
                            when @IsClosed is not null and IsClosed=@IsClosed then 1  
                            when @IsLocked is not null and IsLocked=@IsLocked then 1  
                        else 0  
                        end     
                    )=1 then 1  
                when @Status<>'approved' and Status=@Status then 1  
                else 0  
            end
            ) = 1  
        and ai.Username like @UserName    
        and ai.Email like @Email    
        and  (@Currency  =0 or Currency = @Currency )  
        and (case when @GroupID > 0 and GroupID<1000 and GroupID=@GroupID then 1    

                when @GroupID =0 and GroupID>1000 then 1    
                when @GroupID=-1 and  isnull(@GroupName,'')='' then 1    
                when @GroupID=-1 and exists(select 1 from @GroupIDList) and GroupID in (Select GroupID from @GroupIDList) then 1    
                else 0    
                end     
            ) = 1    
        and (@AffType=0 or AffType = @AffType)  
    )m    
where m.TheCount between @RowStart and @RowEnd          
    
if(@GroupID>0)    
begin    
  select @GroupName=GroupName    
  from CommGroup with (nolock)    
  where @GroupID=GroupID    
end    
  
if(@GroupID=0)    
  select @GroupName=''    


select x.AffId, x.username, x.firstname, x.lastname, x.PreferredLanguage, x.IsClosed, isnull(cg.GroupName, @GroupName) as GroupName, x.registereddate,
e.CurrencyCode as Currency,     
 isnull(dbo.Aff_CountMember(x.AffID),0) as NoOfMember,
  isnull(dbo.Aff_GetAffBalance(x.AffID),0) as BalanceBF, ApprovedDate, isnull(f.Affid, 0) as Favorite,
  x.GroupId,'' as Prefix,x.Status,x.IsLocked,x.AffTypeName
from @TempMember x    
  left join CommGroup cg with (nolock) on x.GroupId = cg.GroupId    
  left join AdminFavorite f with (nolock) on x.AffId = f.AffId and f.AdminId = @UserId    
  left join Currency e with (nolock) on e.CurrencyID=x.Currency  
ORDER BY x.AffId
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupInfoSel]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupInfoSel    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_Con_GroupInfoSel]
    @GroupID int=null,
    @IsIT bit = 0
AS 
/*
    DB03.bodb02-->DB052.Affiliate_MYM : Search department list
    -- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON  

Declare @GroupIT int
Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()

IF @groupid is null
BEGIN    
    declare @temp table(groupid int,groupname nvarchar(300),groupdesc nvarchar(300),nouser int,displayorder int)
    insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
    SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
        from AffGroupInfo  gi with(nolock)
            LEFT JOIN AdminUser ac with(nolock) on ac.groupid=gi.groupid
        where system = 'Affiliate' 
                and gi.groupname <> 'none'
        GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
        ORDER BY gi.groupname
    insert into @temp (groupid ,groupname,groupdesc,nouser,displayorder)
    SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
        from AffGroupInfo  gi with(nolock)
            LEFT JOIN AdminUser ac with(nolock) on ac.groupid=gi.groupid
        where system = 'Affiliate' 
                and gi.groupname= 'none'
        GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
        
    select * 
    from @temp
    where (case when @IsIT = 1 then 1 
                when GroupID = @GroupIt then 0
                else 1 end) = 1
    
END
ELSE
BEGIN
    SELECT gi.groupid,gi.groupname,gi.groupdesc,count(ac.custid) as nouser ,gi.displayorder
    from AffGroupInfo  gi with(nolock)
        LEFT JOIN AdminUser ac with(nolock) on gi.groupid=ac.groupid    
    WHERE gi.groupid=@groupid 
        and (case when @IsIT = 1 then 1 
                when gi.GroupID = @GroupIt then 0
                else 1 end) = 1
    GROUP BY gi.groupid,gi.groupname,gi.groupdesc,gi.displayorder
    ORDER BY gi.displayorder ,gi.groupname
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupPolicySel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupPolicySel    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_Con_GroupPolicySel]
    @Groupid int
AS 
/*DB03.BODB02 --> DB052.Affiliate_MYM*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
SET NOCOUNT ON

declare @GroupIT int
Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()

Declare @Tmp table(createdate smalldatetime, modifydate smalldatetime, policy int, groupid int
                    , funcid int, groupname nvarchar(50), funcname nvarchar(50), funcdesc nvarchar(50)
                    , parentid int, subfuncCount int, DisplayOrder int
                    )

Insert into @Tmp
SELECT gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.funcid,gi.groupname,fi.funcname
    ,fi.funcdesc,fi.parentid ,count(fip.funcID) as SubFuncCount,fi.DisplayOrder
FROM AffGroupPolicy gp with(nolock) 
    INNER JOIN AffGroupInfo gi with(nolock) on gp.groupid=gi.groupid  
    INNER JOIN AffFunctionInfo fi with(nolock) on gp.funcid=fi.funcid 
    left join AffFunctionInfo fip with (nolock) on fi.funcID = fip.ParentID and fip.parentid <> fip.funcid
WHERE gp.groupid=@Groupid
group by gp.createdate,gp.modifydate,gp.policy,gp.groupid,fi.funcid,gi.groupname,fi.funcname
    ,fi.funcdesc,fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid,count(fip.funcID) DESC, fi.DisplayOrder

If (@Groupid <> @GroupIT)
Begin
    delete @Tmp
    where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp
GO
/****** Object:  StoredProcedure [dbo].[Aff_CustomerSelBalBF]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CustomerSelBalBF    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_CustomerSelBalBF]
    @AffID int,
    @BalBroughtForward money OUTPUT    
AS
/*
    Created: 20090905@Peter
    Task : Select Balance Brought Forward info.
    DB: DB052.Affiliate_MYM
    Original: [Aff_CustomerSelBalBF]
    Revisions:
    Param's Explanation:
        • @custid : Affiliate custid
        • @BalBroughtForward: Commission has transferred and has been approved already.
*/
SET NOCOUNT ON


select @BalBroughtForward = dbo.Aff_GetAffBalance(@AffID)
GO
/****** Object:  StoredProcedure [dbo].[Aff_CheckPermissionReadOnAff]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CheckPermissionReadOnAff    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_CheckPermissionReadOnAff]
    @CustId int,
    @Username varchar(50) = '',
    @AffId int = 0,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20090730@Peter
    Task : Select affiliate info for left panel
    DB: DB052.Affiliate_MYM

    Revisions:
      .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_MYM
                        Remove the theory of pending commission and CurrCommEarning   
                        Get PreferredPayment to check approve 
    Param's Explanation:
    • @Username : Affiliate username
*/
SET NOCOUNT ON

Declare @AffType tinyint

if @AffId != 0
Begin
    select @AffType = AffType
    From AffInfo with (nolock)
    where AffId = @AffId
End
else
Begin
    select @AffType = AffType
    From AffInfo with (nolock)
    where Username = @Username
End

if @AffType is null
Begin
    SELECT @ErrMsg = 'You are not authorized on this function', @ErrCode = 500
    RETURN 
End

If @AffType = 2
Begin
    EXEC Aff_Con_CheckPermissionRead 
        @custid=@CustId,
        @funcname='[MediaAffiliate]',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output
    
End
Else
Begin
    EXEC Aff_Con_CheckPermissionRead 
        @custid=@CustId,@funcname='[Affiliate]',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
End
GO
/****** Object:  StoredProcedure [dbo].[Aff_CheckPermissionOnAff]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CheckPermissionOnAff    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_CheckPermissionOnAff]
    @CustId int,
    @Username varchar(50) = '',
    @AffId int = 0,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20090730@Peter
    Task : Select affiliate info for left panel
    DB: DB052.Affiliate_MYM

    Revisions:
      .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_MYM
                        Remove the theory of pending commission and CurrCommEarning   
                        Get PreferredPayment to check approve 
                        
    Param's Explanation:
    • @Username : Affiliate username
*/
SET NOCOUNT ON

Declare @AffType tinyint

if @AffId != 0
Begin
    select @AffType = AffType
    From AffInfo with (nolock)
    where AffId = @AffId
End
else
Begin
    select @AffType = AffType
    From AffInfo with (nolock)
    where Username = @Username
End

select @AffId, @Username, @AffType

if @AffType is null
Begin
    SELECT @ErrMsg = 'You are not authorized on this function', @ErrCode = 500
    RETURN 
End

If @AffType = 2
Begin
    EXEC [dbo].[Aff_Con_CheckPermission] 
        @custid=@CustId,
        @funcname='[MediaAffiliate]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output
    
End
Else
Begin
    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@CustId,@funcname='[Affiliate]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
End
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminPolicySelByCustID]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminPolicySelByCustID    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_Con_AdminPolicySelByCustID]
               @CustID  INT,
               @GroupID INT  = NULL OUTPUT
AS
/*
    DB03.bodb02--> DB052.Affiliate_MYM
    -- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON

Declare @Tmp table(username varchar(50), funcname varchar(50), funcdesc nvarchar(50), funcid int, policy tinyint
    , gpolicy tinyint, actual_policy tinyint, parentid int, subfunccount int, displayorder int)

insert into @Tmp
SELECT   ac.username,
       fi.funcname,
       fi.funcdesc,
       mp.funcid,
       mp.policy,
       gp.policy AS gpolicy,
       (Isnull(mp.policy,0) | Isnull(gp.policy,0)) & Isnull(fi.funcrender,0) AS actual_policy,
       fi.parentid,
       COUNT(fip.funcid) AS subfunccount,
       fi.displayorder
FROM     AffMemberPolicy mp WITH (nolock)
       INNER JOIN AdminUser ac WITH (nolock)  ON ac.custid = mp.custid
       INNER JOIN AffFunctionInfo fi WITH (nolock) ON mp.funcid = fi.funcid        
       INNER JOIN AffGroupPolicy gp WITH (nolock) ON gp.groupid = ac.groupid AND gp.funcid = mp.funcid
       LEFT JOIN AffFunctionInfo fip WITH (nolock) ON fi.funcid = fip.parentid AND fip.parentid <> fip.funcid
WHERE    mp.custid = @CustID
GROUP BY ac.username,fi.funcname,fi.funcdesc,mp.funcid,
       mp.policy,fi.displayorder,gp.policy,fi.funcrender,
       fi.parentid
ORDER BY fi.parentid,
       COUNT(fip.funcid) DESC,
       fi.displayorder

SELECT @GroupID = groupid
FROM   AdminUser with (nolock) where custid=@CustID


Declare @GroupIT varchar(50)

select @GroupIT = [dbo].[Aff_Con_GetGroupItID]()

if(@GroupID <> @GroupIT)
Begin
    --update @Tmp
    --set policy = 0, gpolicy = 0, actual_policy = 0
    --where funcname in ('[Resources]', '[SystemSettings]')
    delete @Tmp
    where funcname in ('[Resources]', '[SystemSettings]', '[Domain]', '[Country]')
End

Select * from @Tmp
GO
/****** Object:  StoredProcedure [dbo].[Aff_HomeGeneralInfo]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HomeGeneralInfo    Script Date: 7/29/2013 1:41:18 AM ******/
  
CREATE PROCEDURE [dbo].[Aff_HomeGeneralInfo]    
AS  
/*Created: 20090828@Bryan  
Task : Gather overview statistic information of aff-admin site  
DB: DB052.Affiliate_ZZun  
  
Revisions:  
 - 20090829@Bryan initialize  
 - 20100520@Johnny: apply StatusID in bettrans table  
 - 20100729@Johnny: Apply Media affiliate statistics  
Param's Explanation:  
  
*/  
BEGIN  
 Declare   
  @MemInProAllNum int,  
  @MemInProMonthNum int  
    
 --Variables for Normal Affiliate  
 Declare @PaymentReqNum int ,  
  @AffInProAllNum int ,  
  @PendingAllNum int ,  
  @ApprovedAllNum int ,  
  @DisapprovedAllNum int ,  
  @ClosedAllNum int,  
  @DepositMemAllNum int ,   
  @DepositAll MONEY ,  
  @WinlostAll MONEY ,  
  @BonusAll MONEY ,  
  @PSPFeeAll MONEY ,  
  @AdjustmentAll MONEY ,  
  @NetWinlostAll MONEY ,  
   
     @NonDepositMemMonthNum int ,   
  @AffInProMonthNum int ,  
  @PendingMonthNum int ,  
  @ApprovedMonthNum int ,  
  @DisapprovedMonthNum int ,  
  @ClosedMonthNum int,  
  @DepositMemMonthNum int ,  
  @DepositMonth MONEY ,  
  @WinlostMonth MONEY ,  
  @BonusMonth MONEY ,  
  @PSPFeeMonth MONEY ,  
  @AdjustmentMonth MONEY ,  
  @NetWinlostMonth MONEY ,  
  @LockedAllNum int ,  
  @LockedMonthNum int  
  
    
 Declare @TransType int  
 declare @CurrentDate smalldatetime  
  
 SET NOCOUNT ON;   
   
 select @CurrentDate=convert(varchar(10),current_timestamp,120)  
   
   
 select @TransType = 202 -- payment request  
   
 SELECT @PaymentReqNum = sum(1)   
 FROM AffTrans af with(nolock)  
 WHERE af.TransType = @TransType   
  AND af.Status='Pending'  
    
 -- all affiliate statc    
 SELECT   
  @PendingAllNum = sum(case when status='Pending' then 1 else 0 end),  
  @ApprovedAllNum  = sum(case when status='Approved' and IsClosed = 0 and IsLocked=0 then 1 else 0 end),  
  @DisapprovedAllNum = sum(case when status='Disapproved' then 1 else 0 end),  
  @ClosedAllNum = sum(case when status='Approved' and IsClosed = 1 then 1 else 0 end),  
  @LockedAllNum = sum(case when status='Approved' and IsLocked = 1 then 1 else 0 end),  
  @AffInProAllNum =sum(1),  
  @AffInProMonthNum = sum(case when datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),  
  @PendingMonthNum = sum(case when Status='pending' and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),  
  @ApprovedMonthNum = sum(case when Status='Approved' and IsClosed = 0 and IsLocked=0 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),  
  @DisapprovedMonthNum= sum(case when Status='Disapproved' and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),  
  @ClosedMonthNum= sum(case when status='Approved' and IsClosed = 1 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end),  
  @LockedMonthNum= sum(case when status='Approved' and IsLocked = 1 and datediff(mm, RegisteredDate, @CurrentDate)=0 then 1 else 0 end)  
 FROM AffInfo ai with(nolock)  
      
 --Get statistics of all affiliate types  
 Exec Aff_GetMemberStatistics  
  @AffType = 0,  
  @DepositAll = @DepositAll Output,  
  @DepositMonth = @DepositMonth Output,  
  @PSPFeeAll = @PSPFeeAll Output,  
  @PSPFeeMonth = @PSPFeeMonth Output,  
  @WinlostAll = @WinlostAll Output,  
  @WinlostMonth= @WinlostMonth Output,  
  @BonusAll = @BonusAll Output,  
  @BonusMonth = @BonusMonth Output,  
  @AdjustmentAll = @AdjustmentAll Output,  
  @AdjustmentMonth = @AdjustmentMonth Output,  
  @NetWinlostAll = @NetWinlostAll Output,  
  @NetWinlostMonth = @NetWinlostMonth Output  
   
   
       
 select @DepositMemAllNum = sum(case when CreatedDate is not null then 1 else 0 end),  
     @DepositMemMonthNum = sum(case when datediff(m, CreatedDate, @CurrentDate) = 0 then 1 else 0 end),  
     @MemInProAllNum = count(1),  
     @MemInProMonthNum =sum(case when datediff(m, RegisteredDate, @CurrentDate) = 0 then 1 else 0 end),  
     @NonDepositMemMonthNum= sum(case when datediff(m, RegisteredDate, @CurrentDate) = 0 and CreatedDate is null then 1 else 0 end)  
 from MemberInfo with(nolock) where IsRemoved=0  
   
    
    
  --final result here  
  select isnull(@PaymentReqNum,0) as  PaymentReqNum ,  
 isnull(@AffInProAllNum,0) as AffInProAllNum,  
 isnull(@PendingAllNum,0) as PendingAllNum,  
 isnull(@ApprovedAllNum,0)  as ApprovedAllNum,  
 isnull(@DisapprovedAllNum,0) as DisapprovedAllNum,  
 isnull(@DepositMemAllNum,0) as DepositMemAllNum,   
 isnull(@ClosedAllNum, 0) as ClosedAllNum,  
 isnull(@DepositAll,0) as DepositAll,  
 isnull(@WinlostAll,0) as WinlostAll,  
 isnull(@BonusAll,0) as BonusAll,  
 isnull(@PSPFeeAll,0) as PSPFeeAll,  
 isnull(@PSPFeeAll,0) as PSPFeeAll,  
 isnull(@AdjustmentAll,0) as AdjustmentAll,  
 isnull(@NetWinlostAll,0) as NetWinlostAll,  
   
 isnull(@AffInProMonthNum,0) as AffInProMonthNum,  
 isnull(@PendingMonthNum,0) as PendingMonthNum,  
 isnull(@ApprovedMonthNum,0) as ApprovedMonthNum,  
 isnull(@DisapprovedMonthNum,0) as DisapprovedMonthNum,  
   
 isnull(@ClosedMonthNum, 0) as ClosedMonthNum,  
 isnull(@DepositMemMonthNum,0)as DepositMemMonthNum,  
 isnull(@NonDepositMemMonthNum,0) as NonDepositMemMonthNum,  
  
 isnull(@DepositMonth,0) as DepositMonth,  
 isnull(@WinlostMonth,0) as WinlostMonth,  
 isnull(@BonusMonth,0) as BonusMonth,  
 isnull(@PSPFeeMonth,0) as PSPFeeMonth ,  
 isnull(@AdjustmentMonth,0) as AdjustmentMonth,  
 isnull(@NetWinlostMonth,0) as NetWinlostMonth,  
   
 isnull(@MemInProAllNum,0) as MemInProAllNum,  
 isnull(@MemInProMonthNum,0) as MemInProMonthNum,  
 isnull(@LockedAllNum,0) as  LockedAllNum,  
 isnull(@LockedMonthNum,0) as LockedMonthNum  
  
    
 -- //all banner statc  
 SELECT   
     at.TypeID as TypeID,   
     at.Name as TypeName,  
  sum(case when bt.Value in ('Image','Flash') then 1 else 0 end) as BannerNum,  
  sum(case when bt.Value='Image'  then 1 else 0 end) as ImageBannerNum,  
  sum(case when bt.Value='Flash' then 1 else 0 end) as FlashBannerNum    
 FROM Banners b with(nolock)  
 inner join BannerTypes bt with (nolock) on b.ImageType=bt.TypeID  
 inner join AffType at (nolock) on at.TypeID=b.Type  
 where bt.Type='ImageType'  
 group by at.TypeID,at.Name  
    
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_PaymentRequestSelInfoByAff]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PaymentRequestSelInfoByAff    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_PaymentRequestSelInfoByAff]
    @AffID int,
    @PreferredPayment varchar(20) OUTPUT,
    @BalBroughtForward money OUTPUT,    
    @MinAmount money output
AS
/*Created: 20090914@Peter
Task : Getting Payment request history information for Affiliate
DB: DB052.Affiliate_MYM 
Original: [Aff_BettransSelTransfer]
Revisions:
    
Param's Explanation:
• @custid : Affiliate custid
• @BalBroughtForward: Sum(Winlost is transfered and approved to affiliate)
• @PreferredPayment: Preferred Payment method for this affiliate
• @MinAmount
*/        
SET NOCOUNT ON            
Declare @currencyName varchar(5)
Select @PreferredPayment=PreferredPayment
from AffDetail with (nolock)
where AffID=@AffID

SELECT @currencyName = C.currencycode
from AffInfo A with (nolock) inner join currency C with(nolock) on A.currency = c. currencyid
where A.AffID=@AffID    
--Get MinAmount value

SELECT @MinAmount = SValue from SystemSettings with(nolock) 
WHERE SName = 'AFF_Min'+ @PreferredPayment + @currencyName

--Get Balance Brought Forward
Select @BalBroughtForward=dbo.Aff_GetAffBalance(@AffID)

--Get list payment request
Select t.TransID,p.RefID, p.TransDate, p.CompletedDate,p.Status,abs(p.Amount) as Amount,p.AffDesc
from AffPayout p with (nolock)
 inner join AffTrans t with (nolock) on t.RefID=p.RefID
where p.AffID=@AffID
order by RefID desc
GO
/****** Object:  StoredProcedure [dbo].[Aff_PlayerPayoutInfoSel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PlayerPayoutInfoSel    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_PlayerPayoutInfoSel]
    @AffId int,
    @PlayerUsername varchar(30) OUTPUT,
    @SystemName varchar(30) OUTPUT,
    @DummyBalAcc varchar(30) OUTPUT,
    @AffCurrency varchar(6) OUTPUT
AS
/*
    Task : Get all information of existing member
    DB : DB054.Affiliate_MYM
        - Johnny@2013Mar25: Return test account (UUS balance account)
*/


select @PlayerUsername = Player_Username from AffDetail nolock where AffId = @AffId

select @SystemName = SValue From SystemSettings nolock where SName = 'SystemName' and Type = 'Meta'

Declare @Player_Currency varchar(50)

Select @Player_Currency = dbo.[Aff_PlayerCurrencyByAffId] (@AffId)

Select @AffCurrency = e.code from affinfo a 
inner join exchange e on e.ExchangeID = a.Currency 
where a.affid = @AffId
--For Real Currency
Select @DummyBalAcc = SValue
From SystemSettings nolock
where SName like 'AFF_BalPlayer' + @Player_Currency
    and Type = 'Meta'
GO
/****** Object:  StoredProcedure [dbo].[Aff_ExchangeRateSel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ExchangeRateSel    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_ExchangeRateSel]
    @FromCurrency smallint,
    @ToCurrency smallint
 
AS
/*
    Query ExchangeRate from @FromCurrency to a Base Currency @ToCurrency
*/
BEGIN
    
    set nocount on;
     
    declare @sql nvarchar(max);    

    select 
        @sql = N'select top(1) ' + dbo.Aff_GetCurrencyCode(@ToCurrency) + ' from Exchange (nolock) where ExchangeID=' + cast(@FromCurrency as varchar(10))

    exec (@sql);

    set nocount off;
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminSelByGroupID]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminSelByGroupID    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_Con_AdminSelByGroupID]
    @Groupid int=null,
    @Username varchar(30)='%',
    @FirstChar nvarchar(6)='%',
    @IsIT bit = 0
--Search username: '%username%'
--Search first char:
--A: 'A%'
--B: 'B%'
--0-9: '[0-9]%'

AS 
/*
    DB03.BODB02 --> DB052.Affiliate_MYM
    -- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON

Declare @GroupIT int
Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()

IF @Groupid is null
BEGIN
    SELECT gi.groupname,ac.groupid,ac.custid, ac.username, ac.firstname, ac.lastname,
        ac.closed,ac.createdate,ct.username as creator
    FROM AdminUser ac with (nolock) 
        INNER JOIN AffGroupInfo gi with(nolock) on ac.groupid=gi.groupid
        LEFT JOIN AdminUser ct with(nolock) on ac.creator=ct.custid
    WHERE ac.username like @Username 
            and ac.username like @FirstChar
            and (case when @IsIT = 1 then 1 
                when ac.GroupID = @GroupIt then 0
                else 1 end) = 1
    ORDER BY IsNull(ac.closed, 0), ac.username,ac.groupid
END
ELSE
BEGIN
    SELECT gi.groupname,ac.groupid,ac.custid, ac.username, ac.firstname, ac.lastname,
        ac.closed,ac.createdate,ct.username as creator
    FROM AdminUser ac with (nolock)         
        INNER JOIN AffGroupInfo gi with(nolock) on ac.groupid=gi.groupid
        LEFT JOIN AdminUser ct with(nolock) on ac.creator=ct.custid
    WHERE ac.groupid=@groupid 
        and ac.username like @Username 
        and ac.username like @FirstChar 
        and (case when @IsIT = 1 then 1 
                when ac.GroupID = @GroupIt then 0
                else 1 end) = 1
    ORDER BY IsNull(ac.closed, 0), ac.username,ac.groupid
END
GO
/****** Object:  StoredProcedure [dbo].[Task_aff_DailyImportExchange]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_aff_DailyImportExchange    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE PROCEDURE [dbo].[Task_aff_DailyImportExchange]
     @Date smalldatetime=null,
     @Xml xml = null
AS
/*
    Created: 20110223@Peter
    Task : Import s from IBC
    DB: DB052.Affiliate_ZZun
    Revisions:
        - 20110223@Peter: initialize SP
        
*/
SET NOCOUNT ON


SELECT @Date = coalesce(CONVERT(varchar(10), @Date, 120),CONVERT(varchar(10), CURRENT_TIMESTAMP, 120))

DECLARE @count int

DECLARE @TempTrans TABLE(
    ExchangeDate datetime,
    ExchangeID smallint,
    Code varchar(5),
    MYR float,
    USD float,
    EUR float,
    CNY float,
    SGD float,
    IDR float,
    AUD float,
    CHF float,
    GBP float,
    THB float,
    VND float
    )

insert into @TempTrans --Convert xml to table
Select    
        [Table].[Column].value('./@exchangedate', 'datetime') as ExchangeDate,    
        [Table].[Column].value('./@exchangeid', 'smallint') as ExchangeID,
        [Table].[Column].value('./@code', 'varchar(5)') as Code,
        [Table].[Column].value('./@myr', 'float') as MYR,        
        [Table].[Column].value('./@usd', 'float') as USD,                
        [Table].[Column].value('./@eur', 'float') as EUR,
        [Table].[Column].value('./@cny', 'float') as CNY,        
        [Table].[Column].value('./@sgd', 'float') as SGD,
        [Table].[Column].value('./@idr', 'float') as IDR,
        [Table].[Column].value('./@aud', 'float') as AUD,
        [Table].[Column].value('./@chf', 'float') as CHF,
        [Table].[Column].value('./@gbp', 'float') as GBP,
        [Table].[Column].value('./@thb', 'float') as THB,
        [Table].[Column].value('./@vnd', 'float') as VND

    from @Xml.nodes('/root/trans') as [Table]([Column])

update  @TempTrans

set  MYR=(case when code<>'MYR' then MYR/(select isnull(MultipliedBy,1) from Currency where currencycode='MYR') else MYR end)
      ,USD=(case when code<>'USD' then USD/(select isnull(MultipliedBy,1) from Currency where currencycode='USD') else USD end)
      ,EUR=(case when code<>'EUR' then EUR/(select isnull(MultipliedBy,1) from Currency where currencycode='EUR') else EUR end)
      ,CNY=(case when code<>'CNY' then CNY/(select isnull(MultipliedBy,1) from Currency where currencycode='CNY') else CNY end)
      ,IDR=(case when code<>'IDR' then IDR/(select isnull(MultipliedBy,1) from Currency where currencycode='IDR') else IDR end)
      ,AUD=(case when code<>'AUD' then AUD/(select isnull(MultipliedBy,1) from Currency where currencycode='AUD') else AUD end)
      ,CHF=(case when code<>'CHF' then CHF/(select isnull(MultipliedBy,1) from Currency where currencycode='CHF') else CHF end)
      ,GBP=(case when code<>'GBP' then GBP/(select isnull(MultipliedBy,1) from Currency where currencycode='GBP') else GBP end)
      ,SGD=(case when code<>'SGD' then SGD/(select isnull(MultipliedBy,1) from Currency where currencycode='SGD') else SGD end)
      ,THB=(case when code<>'THB' then THB/(select isnull(MultipliedBy,1) from Currency where currencycode='THB') else THB end)
      ,VND=(case when code<>'VND' then VND/(select isnull(MultipliedBy,1) from Currency where currencycode='VND') else VND end)


UPDATE ec
SET  USD = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.USD,ec.USD,0) ELSE ec.USD END)
    ,USD_Market = coalesce(ed.usd,ec.USD_Market,0)
    ,EUR = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.EUR,ec.EUR,0) ELSE ec.EUR END)
    ,EUR_Market = coalesce(ed.EUR,ec.EUR_Market,0)
    ,CNY = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.CNY,ec.CNY,0) ELSE ec.CNY END)
    ,CNY_Market = coalesce(ed.CNY,ec.CNY_Market,0)
    ,UUS = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.UUS END)
    ,UUS_Market = 2E-102
    ,MYR = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.MYR,ec.MYR,0) ELSE ec.MYR END)
    ,MYR_Market = coalesce(ed.MYR,ec.MYR_Market,0)
    ,SGD = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.SGD,ec.SGD,0) ELSE ec.SGD END)
    ,SGD_Market = coalesce(ed.SGD,ec.SGD_Market,0)
    ,IDR = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.IDR,ec.IDR,0) ELSE ec.IDR END)
    ,IDR_Market = coalesce(ed.IDR,ec.IDR_Market,0)
    ,AUD = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.AUD,ec.AUD,0) ELSE ec.AUD END)
    ,AUD_Market = coalesce(ed.AUD,ec.AUD_Market,0)
    ,CHF = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.CHF,ec.CHF,0) ELSE ec.CHF END)
    ,CHF_Market = coalesce(ed.CHF,ec.CHF_Market,0)
    ,GBP = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.GBP,ec.GBP,0) ELSE ec.GBP END)
    ,GBP_Market = coalesce(ed.GBP,ec.GBP_Market,0)
    ,THB = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.THB,ec.THB,0) ELSE ec.THB END)
    ,THB_Market = coalesce(ed.THB,ec.THB_Market,0)
    ,VND = (CASE WHEN IsAutoRefresh = 1 THEN coalesce(ed.VND,ec.VND,0) ELSE ec.VND END)
    ,VND_Market = coalesce(ed.VND,ec.VND_Market,0)
FROM Exchange ec with(rowlock, updlock)    
    INNER JOIN dbo.CurrencyConverter cc with(nolock) on ec.ExchangeID = cc.ExchangeID
    INNER JOIN @TempTrans as ed on ed.ExchangeID = cc.PartnerExchangeID
WHERE exchangedate = @date

-- update for UUS currency

UPDATE ec
SET  UUS=1
     ,UUS_Market=1    
    ,USD_Market = 2E-102
    ,USD = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.USD END)
    ,EUR = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.EUR END)
    ,EUR_Market =  2E-102
    ,CNY = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.CNY END)
    ,CNY_Market =  2E-102
    ,MYR = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.MYR END)
    ,MYR_Market =  2E-102
    ,SGD = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.SGD END)
    ,SGD_Market =  2E-102
    ,IDR = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.IDR END)
    ,IDR_Market =  2E-102
    ,AUD = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.AUD END)
    ,AUD_Market =  2E-102
    ,CHF = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.CHF END)
    ,CHF_Market = 2E-102
    ,GBP = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.GBP END)
    ,GBP_Market =  2E-102
    ,THB = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.THB END)
    ,THB_Market =  2E-102
    ,VND = (CASE WHEN IsAutoRefresh = 1 THEN 2E-102 ELSE ec.VND END)
    ,VND_Market =  2E-102
FROM Exchange ec with(rowlock, updlock)        
WHERE ExchangeID = 9999





if @@ROWCOUNT = 0  
 PRINT 'No data available for this day!'

DELETE ExchangeDaily
WHERE [Date] = @date

INSERT INTO ExchangeDaily (Date, ExchangeID,USD,USD_Market,EUR,EUR_Market,CNY,CNY_Market,UUS,UUS_Market,MYR,MYR_Market,SGD,SGD_Market,IDR,IDR_Market,AUD,AUD_Market,CHF,CHF_Market,GBP,GBP_Market,THB,THB_Market,VND,VND_Market,Code,DepositPercent,WithdrawalPercent,IsAutoRefresh)
SELECT @date,  ExchangeID,USD,USD_Market,EUR,EUR_Market,CNY,CNY_Market,UUS,UUS_Market,MYR,MYR_Market,SGD,SGD_Market,IDR,IDR_Market,AUD,AUD_Market,CHF,CHF_Market,GBP,GBP_Market,THB,THB_Market,VND,VND_Market,Code,DepositPercent,WithdrawalPercent,IsAutoRefresh
FROM Exchange with(nolock)

-- if the date < current_date and date > max(winlostdate from commission)
-- update all data for MemberDaily,MemberDailyRemoved, AffDaily,AffDailySummary

declare @TaskID int,@LogID int , @RunDate datetime, @Status varchar(50)

select @RunDate=getdate(), @Status='completed'

select @TaskID= TaskID from TaskManager(nolock) where TaskName='Import Exchange Daily'
exec [dbo].[Aff_TaskLogIns]
    @TaskID,
    @RunDate,
    @Status,
    @LogID OUTPUT
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_ClearLogin_Loop]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_ClearLogin_Loop    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Task_Aff_ClearLogin_Loop]  
AS  
/*
    Created:  20110221@Jamie
    Task: Clear Login
    DB: DB052.Affiliate_MYM
    Original SP:
    
    Revisions:
        
*/
SET NOCOUNT ON

EXEC Task_Aff_ClearLogin 


declare @TaskID int,@LogID int , @RunDate datetime, @Status varchar(50)

select @RunDate=getdate(), @Status='completed'

select @TaskID= TaskID from TaskManager(nolock) where TaskName='Clear Login'
exec [dbo].[Aff_TaskLogIns]
    @TaskID,
    @RunDate,
    @Status,
    @LogID OUTPUT


/*
 Declare @start datetime  
 SELECT @start = CURRENT_TIMESTAMP  
  
 WHILE (1=1) AND (DATEDIFF(minute,@start, CURRENT_TIMESTAMP) < 20)  
 BEGIN  
  EXEC Task_Aff_ClearLogin  
  WAITFOR DELAY '00:00:30'  
 END  
 
 */
GO
/****** Object:  StoredProcedure [dbo].[Aff_UserOnlineList]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_UserOnlineList    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Aff_UserOnlineList]   
 @PageSize int=50,    
 @PageIndex int=1,  
 @IsIt bit = 0,  
 @TotalPages int=0 OUTPUT,    
 @NRows int=0 OUTPUT  
AS  
/*Created: 20090828@Bryan  
Task : Select all affs and admins currently logging on affliate system  
DB: DB052.Affiliate_MYM  
  
Revisions:- 20090829@Bryan initialize  
   
Param's Explanation:  
 - PageSize: the selected page size on webpage  
 - PageIndex: the index of selected page in paging structure  
 - TotalPages: the number of pages with the pagesize returned from DB  
 - NRows: total records found  
*/  
BEGIN    
SET NOCOUNT ON  
declare @startNum int, @endNum int, @GroupIT int
declare @Table table([No] int IDENTITY(1,1), UserName varchar(50),LoggedIn datetime,LastRequest datetime,IP varchar(20),RoleName varchar(20))   

Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()
    
insert into @Table(UserName,LoggedIn,LastRequest,IP,RoleName)   
select UserName,LoggedIn,LastRequest,IP,RoleName  
from  
(  
    (select au.username as UserName, au.lastlogged as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Admin' as RoleName   
    from ON_USER o with(nolock)         
        inner join  dbo.AdminUser au with(nolock) on au.custid=o.custid   
    where o.subaccid = 6 and o.iskickedout=0
            and (case when @IsIT = 1 then 1 
                when GroupID = @GroupIt then 0
                else 1 end) = 1
    )      
    union all   
    (select aff.username as UserName, aff.lastlogindate as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Aff' as RoleName  
    from ON_USER o with(nolock)  
    inner join dbo.affdetail aff with(nolock) on aff.affid=o.custid  and o.iskickedout=0)  
) x      
--order by   
select @NRows=@@ROWCOUNT  
select @endNum = (@PageIndex)*@PageSize;  
select @startNum = @endNum - @PageSize + 1;  
select * from @table where [no] between @startNum and @endNum order by RoleName,LastRequest desc ,UserName   
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end  


END
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_GroupSettingBackup]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_GroupSettingBackup    Script Date: 7/29/2013 1:41:18 AM ******/
CREATE Procedure [dbo].[Task_Aff_GroupSettingBackup]
    @Month int, 
    @Year int    
AS
/*
Created: 20090812@DungTong
Task : Backup all group settings monthly on last day of selected month
DB: DB052.Affiliate_MYM
Original:

Revisions:                     

Param's Explanation:
• @Month: The month to transfer
• @Year :  The year to transfer     
*/
SET NOCOUNT ON

Declare @FirstDay smalldatetime,@LastDay smalldatetime


Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime),
       @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))
    

if datediff(d,Current_TimeStamp,@LastDay) > 0
BEGIN
    SELECT 'The month is not completed yet. So you cannot backup data!' Result
    SELECT @FirstDay as FirstDay,@LastDay as LastDay
    RETURN
END

--Check group History data is inserted
if(exists(select top(1) 1 from CommGroupHistory (nolock) where monthdate=@LastDay) 
   or exists(select top(1) 1 from GroupSettingHistory (nolock) where monthdate=@LastDay)
   or exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)
   or exists(select top(1) 1 from AffGroupHistory (nolock) where monthdate=@LastDay)
  )
 BEGIN
    delete     CommGroupHistory where monthdate=@LastDay
    delete GroupSettingHistory where monthdate=@LastDay
    delete DeductionSettingHistory where monthdate=@LastDay
    delete AffGroupHistory where monthdate=@LastDay
 END
 
 
INSERT INTO [CommGroupHistory]
           ([GroupID]
           ,[MonthDate]
           ,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description]
           ,[QualifiedAmount]
           ,[Currency])
select GroupID,@LastDay,[GroupName]
           ,[CreatedDate]
           ,[Creator]
           ,[IsDeleted]
           ,[Description]
           ,[QualifiedAmount]
           ,[Currency]
from CommGroup (nolock)

Insert Into GroupSettingHistory(
            [GroupID]
           ,[ProductID]
           ,[TierID]
           ,[MonthDate]
           ,[MinAmount]
           ,[MaxAmount]
           ,[MinQM]
           ,[MaxQM]
           ,[Commission]
         )
select GroupID,ProductID,TierID,@LastDay,MinAmount,MaxAmount,MinQM,MaxQM,Commission
from GroupSetting (nolock)
   
Insert Into DeductionSettingHistory(GroupID,MonthDate,DeductionID,DeductedPercentage)
select GroupID,@LastDay,DeductionID,DeductedPercentage
from DeductionSetting (nolock)

Insert Into AffGroupHistory(AffID,MonthDate,GroupID)
select AffID,@LastDay,GroupID
from AffInfo (nolock)
where GroupID is not null and GroupID>0

declare @TaskID int,@LogID int , @RunDate datetime, @Status varchar(50)

select @RunDate=getdate(), @Status='completed'

select @TaskID= TaskID from TaskManager(nolock) where TaskName='Backup Commission Group'
exec [dbo].[Aff_TaskLogIns]
    @TaskID,
    @RunDate,
    @Status,
    @LogID OUTPUT
GO
/****** Object:  StoredProcedure [dbo].[Aff_StatisticsSel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_StatisticsSel    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_StatisticsSel]  
    @AffID int,  
    @MonthDate smalldatetime,      
    @TotalActivePlayer int OUTPUT,  
    @TotalPlayerDepUp int OUTPUT,  
    @NewSignUpDep int OUTPUT,  
    @NewSignUp int OUTPUT,  
    @TotalPlayer int OUTPUT,   
    @BalBroughtforward money = 0 OUTPUT,  
    @TotalDeposit money OUTPUT,  
    @TotalDepositUp money OUTPUT,  
    @TotalTurnover money OUTPUT,  
    @TotalTurnoverUp money OUTPUT,  
    @TotalWinlostUp money OUTPUT,  
    @TotalWinlost money OUTPUT,  
    @TotalUniqueClicks int = 0 OUTPUT,  
    @TotalClicks int = 0 OUTPUT  
AS  
  
/*Created: 20090325@VinhTrinh  
Task : Get statistics for affiliate  
DB: DB052.Affiliate_MYM  
Original : [Aff_StatisticsSel]  
Revisions:  
    - 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).  
    - 20090827@DungTong: Convert to new DB version  
    - 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"  
Param's Explanation:  
    • @AffID : Affiliate custid  
    • @MonthDate : Date search(format:first day of the month).  
    • @TotalActivePlayer : Get Active player in Month  
    • @TotalPlayerDepUp int OUTPUT,--Get player deposited in our system  
    • @NewSignUpDep : Get new signups of the month  
    • @TotalDeposit : total deposit money for month search  
    • @TotalDepositUp money OUTPUT,--total deposit money up to now  
    • @TotalTurnover money OUTPUT,--total turnover money up to now  
*/  
  
SET NOCOUNT ON  
  
      
  
SELECT @NewSignUp = sum(case when DATEDIFF(MONTH,@MonthDate,RegisteredDate) = 0 then 1  else 0 end)  
    ,@NewSignUpDep = sum(case when CreatedDate is not null and datediff(m, CreatedDate, @MonthDate) = 0  then 1 else 0 end)  
    ,@TotalPlayerDepUp=sum(case when  CreatedDate is not null and IsRemoved=0 then 1 else 0 end)   
    ,@TotalPlayer=sum(case when IsRemoved=0 then 1 else 0 end)   
FROM MemberInfo WITH(NOLOCK)  
WHERE AffID = @AffID        
    and username not in (select username From MemberRemoval with(nolock) where datediff(m, RemovedDate, @MonthDate) = 0)   
  
create table #TblStatistics (username varchar(30), ProductID int, QualifiedMember int,ActivePlayer int, Turnover money, Deposit money, Winlost money, MonthDate smalldatetime)  

insert into #TblStatistics  
select '',  
    ProductID,   
    QualifiedMember,   
    ActivePlayer,  
    MemberTurnover_aff, --Turnover has been change to AffExRate  
    MemberDeposit_aff, --Deposit has been change to AffExRate  
    MemberWinlost_aff as MemberWinlost,--Winlost has been change to AffExRate  
    WinlostDate  
from AffCommission with (nolock)  
where AffId = @AffId   

declare @MaxTransDate datetime, @FromDate datetime, @CurrentDate datetime, @QMTurnover money  
  
select @QMTurnover=dbo.[Aff_GetQMTurnOver](@AffID,@MonthDate), @CurrentDate= current_timestamp
select @MaxTransDate = max(MonthDate) from #TblStatistics with(nolock)  
if @MaxTransDate is not null  
   select @FromDate = dateadd(d,1,@MaxTransDate)  
else 
      select @FromDate = MIN(WinlostDate) from AffDailySummary(nolock) 
   

insert into #TblStatistics  
  
select ci.username,  
    ProductID,  
    0 as QualifiedMember,  
    0 as ActivePlayer,  
    sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as Turnover,  
    sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit,      
    sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost,  
    dateadd(mm, DATEDIFF(m,0,b.WinlostDate), 0)  
from MemberDaily b with (nolock)   
    inner join MemberInfo ci with (nolock) on ci.username=b.username  
where ci.AffID=@AffID   
    and b.winlostdate between @FromDate and @CurrentDate--this condition use up index on winlostdate      
group by ci.username, ProductID,  
    dateadd(mm, DATEDIFF(m,0,b.winlostdate), 0)  


update #TblStatistics

set QualifiedMember=(case when Turnover>=@QMTurnover then 1 else 0 end)    

where username<>''


Select @TotalWinlostUp = Sum(a.Winlost)  
    , @TotalTurnoverUp = Sum(a.Turnover)  
    , @TotalDepositUp = Sum(a.Deposit)  
    ,@TotalWinlost = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Winlost else 0 end)  
    , @TotalTurnover = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Turnover else 0 end)  
    , @TotalDeposit = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Deposit else 0 end)  
    --,@TotalActivePlayer=sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0  then isnull(a.ActivePlayer,0) else 0 end)   
    
  
From #TblStatistics a with (nolock)  

declare @DateTemp datetime

set @DateTemp=dbo.Date_Only(dbo.Aff_GetLastDayOfMonth(@MonthDate))



if(exists(select top(1) 1 from AffCommission (nolock) where winlostdate=@DateTemp))
BEGIN
 select @TotalActivePlayer=max(ActivePlayer)
 From #TblStatistics a with (nolock)  
 where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and username=''
END
else
BEGIN
   select @TotalActivePlayer=count(distinct username)
  From #TblStatistics a with (nolock)  
  where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and username<>''
              and (a.Turnover>0 or a.Deposit>0) 
END



  
--Get Click Statistics  
  
select @TotalClicks= sum(TotalClick),  @TotalUniqueClicks=sum(UniqueClick)  
FROM  
(  
    select sum(TotalClick) as TotalClick,Sum(UniqueClick) as UniqueClick  
    from ClickStatisticsSum (nolock)  
    where AffID=@AffID              
        and datediff(mm,@MonthDate,[date])=0  
    
    union all  

    select sum(ClickCount) as TotalClick,count(distinct s.IP) as UniqueClick  
    from ClickStatistics s (nolock)   
    where datediff(mm,@MonthDate,s.date)=0 and s.AffID=@AffID  
    group by dbo.Date_Only(Date),DomainReferrer, SportCode, LanguageCode  
) t  
  
select @BalBroughtforward = isnull(dbo.Aff_GetAffBalance(@AffID), 0)     


if(DATEDIFF(m, current_timestamp, @MonthDate) >0 )
begin
          Select p.ProductID,p.ProductName as Product,0  as TotalQualifiedMembers 
          From Product p  with (nolock)  
          where  [dbo].[Aff_IsProductInGroupOfAff](@AffID,p.ProductID ,current_timestamp) >0   
          order by p.ProductID
end
else
begin
        Select p.ProductID,p.ProductName as Product,isnull(t.TotalQualifiedMembers,0)  as TotalQualifiedMembers 
         From Product p  with (nolock)  
        left join 
        (
           select a.ProductID, sum(a.QualifiedMember) as TotalQualifiedMembers
           from #TblStatistics a (nolock)  
           where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and [dbo].[Aff_IsProductInGroupOfAff](@AffID,a.ProductID ,@MonthDate) >0
           group by a.ProductID

        ) t on t.ProductID=p.ProductID
        where  [dbo].[Aff_IsProductInGroupOfAff](@AffID,p.ProductID ,@MonthDate) >0   
          order by p.ProductID

end




Drop table #TblStatistics
GO
/****** Object:  StoredProcedure [dbo].[Aff_ReportQMDetail]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ReportQMDetail    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_ReportQMDetail]
    @ProductID int=0,
    @AffID int,
    @Month int,
    @Year int,
    @AffCurrency varchar(8) = 'UUS' OUTPUT,
    @PageSize int=50,    
    @PageIndex int=1,    
    @TotalPages int=0 OUTPUT,    
    @NRows int=0 OUTPUT    
AS

/*
Created: 20091213@Peter
Task : Get List of Qualifying members report for one affiliate.
DB: DB052.Affiliate_MYM
Original: 
Revisions:
    
Param's Explanation:
    
*/
SET NOCOUNT ON

DECLARE @TblResult TABLE(mycount int IDENTITY(1,1), username varchar(30), Product varchar(50), TurnOver money)

Declare @FirstDay smalldatetime,@LastDay smalldatetime,@CurrDate smalldatetime, @QualifiedAmount Float

 
select @AffCurrency=e.Code,@QualifiedAmount=co.QualifiedAmount
from AffInfo ai (nolock)
inner join Exchange e (nolock) on e.ExchangeID=ai.Currency
inner join CommGroup co with (nolock) on ai.GroupId = co.GroupId

where ai.AffID=@AffID


 --Get First date and last date and current date in order to calculate turnover
Select @CurrDate =  dbo.Date_Only(current_timestamp),
    @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime),
    @LastDay = dbo.Aff_GetLastDayOfMonth(@FirstDay)
    
Select @LastDay = (case when @LastDay >= @CurrDate then @CurrDate else @LastDay end)

   insert into @TblResult(username, Product, TurnOver)
    Select username,p.ProductName,
        sum(TurnOver* AffExRate) as TurnOver        
    From MemberDaily m with (nolock)
          inner join Product p (nolock) on p.ProductID=m.ProductID
    where  (@ProductID=0 or @ProductID=m.ProductID) and Winlostdate  between @FirstDay and @LastDay and AffID=@AffID
    Group by username,p.ProductName
    order by sum(TurnOver* AffExRate) desc , username,p.ProductName
   
select @NRows=@@ROWCOUNT   

 

if(isnull(@NRows,0)=0)    
   return    
  
DECLARE @RowStart int, @RowEnd int  
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       

select tb.*, (case when tb.TurnOver>=@QualifiedAmount then 1 else 0 end) as IsQualifiedMember  from @TblResult tb where mycount between  @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_ReportQM]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ReportQM    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Aff_ReportQM]
    @ProductID int=0,
    @AffName varchar(50) = NULL,
    @AffType tinyint = 0,
    @PreferredLanguage varchar(11) = null,
    @Currency smallint = 0,
    @Month int,
    @Year int,
    @PageSize int=50,    
    @PageIndex int=1,    
    @TotalPages int=0 OUTPUT,    
    @NRows int=0 OUTPUT    
AS

/*
Created: 20091213@Peter
Task : Get Qualifying member report for all affiliates.
DB: DB052.Affiliate_MYM
Original: 
Revisions:
    
Param's Explanation:
    
*/
SET NOCOUNT ON

select @AffName= '%' + Coalesce(@AffName, '') + '%'

Declare @FirstDay smalldatetime,@LastDay smalldatetime, @MaxWinlostDate smalldatetime
        


Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
 --Get last day of inputted month
Select @LastDay = dbo.Aff_GetLastDayOfMonth(@FirstDay)
     
  
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30),QualifiedAmount float,AffTypeName varchar(50))
create table #report(TheCount int IDENTITY(1,1), AffId int ,Product varchar(50), UserName varchar(30), QualifiedMember int,AffTypeName varchar(50))
insert into @TempAff
select ai.AffID, ai.UserName,co.QualifiedAmount,at.Name as AffTypeName
    from AffInfo ai with (nolock)    
        inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
        inner join CommGroup co with(nolock) on ai.GroupId = co.GroupId
        left join AffType at with (nolock) on ai.AffType = at.TypeID
    WHERE ai.Status='Approved'    
    and (@AffType = 0 or ai.AffType = @AffType)
    and ai.Username like @AffName
    and (@PreferredLanguage is null or @PreferredLanguage=ad.PreferredLanguage)
    and (@Currency=0 or  @Currency= ai.Currency    )
    and ai.ApprovedDate<=@LastDay


select @MaxWinlostDate=max(WinlostDate) from AffCommission with (nolock)



if(@MaxWinlostDate is not null and @LastDay<=@MaxWinlostDate) --Get Data from AffCommission
BEGIN

 insert into #report(AffId ,Product, UserName, QualifiedMember,AffTypeName)
 select ac.AffID, a.UserName,p.ProductName as Product,ac.QualifiedMember,a.AffTypeName
            from AffCommission ac with (nolock)    
                inner join @TempAff a  on ac.AffID=a.AffID                
                inner join Product p with (nolock) on p.ProductID=ac.ProductID
            where ac.WinlostDate = dbo.Date_Only(@LastDay)   
                 and (@ProductID=0 or ac.ProductID=@ProductID)
                 and ac.MemberTurnover>0      
    order by ac.QualifiedMember desc,ac.AffID ,p.ProductName         
select @NRows=@@ROWCOUNT
         
END
else --Calculate data for uncalculated month
BEGIN
          
    Declare  @CurrDate smalldatetime
        
    select @CurrDate =  convert(varchar(10),current_timestamp,120),
        @LastDay = (case when @LastDay >= @CurrDate then @CurrDate else @LastDay end)

 insert into #report(AffId ,Product, UserName, QualifiedMember,AffTypeName)
  Select a1.AffID,t.Product as Product, t.AffName as UserName,
    sum(case when t.TurnOver>=a1.QualifiedAmount then 1 else 0 end) as QualifiedMember,
    a1.AffTypeName
      from  @TempAff a1
     inner join
     ( 
       select a.AffID,a.userName as AffName,m.USerName,p.ProductName as product,sum(TurnOver * AffExRate) as TurnOver
       from MemberDaily m (nolock)
            inner join @TempAff a on a.AffID=m.AffID   
            inner join Product p with (nolock) on p.ProductID=m.productID    
        where m.Winlostdate between  @FirstDay and @LastDay and m.Turnover>0
           and (@ProductID=0 or m.ProductID=@ProductID)
       group by a.AffID,a.userName,m.USerName,p.ProductName

     ) t on a1.AffID=t.AffID

     group by  a1.AffID,t.AffName, t.Product,a1.AffTypeName
     order by sum(case when t.TurnOver>=a1.QualifiedAmount then 1 else 0 end) desc,a1.AffID, t.Product         

    select @NRows=@@ROWCOUNT 
     
END


if(isnull(@NRows,0)=0)    
    return  

DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

select * from #report (nolock)

where TheCount between @RowStart and @RowEnd

drop table #report
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_DailySummaryClickRate]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_DailySummaryClickRate    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Task_Aff_DailySummaryClickRate]
    @date smalldatetime = null
AS
/*
  Task to summary Click Statistics daily
  Writer : Johnny
  Date : 2012/01/09
  DB: DB052.Affiliate_12BET
    
*/
 SET NOCOUNT ON


select @date = convert(varchar(10), ISNULL(@date, dateAdd(d, -30, current_timestamp)), 120)

if(exists (select 1 from ClickStatisticsSum (nolock) where datediff(d,@date,[Date])=0))
 begin
   return
 end 

/* 
--Store Total number of deposit user
Declare @TmpDeposit as table(AffId int, TotalDeposit int)
insert into @TmpDeposit(AffId, TotalDeposit)
Select AffId, Sum(1) as TotalDeposit
From MemberInfo nolock
where datediff(d, CreatedDate, @date) = 0
Group by AffId 
 */

 --Summary for Daily by Domain and Date
insert into ClickStatisticsSum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
select  c.AffID,
        DomainReferrer,
        @date as [Date],
        SportCode,
        LanguageCode,
        sum(ClickCount) as TotalClick,
        count(distinct IP) as UniqueClick,
        SUM(isnull(Signups, 0)) as Signups,
        SUM(isnull(FDM, 0)) as  FDM
from ClickStatistics c with (nolock)
    left join 
        (Select ClickId, 
            SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
            SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
        from MemberInfo m with (nolock)         
        group by ClickId
        ) as m on c.ClickId = m.ClickId
where datediff(d, @date, [date])=0
group by c.AffID, DomainReferrer, SportCode, LanguageCode


insert into ClickStatistics_bk
select * from ClickStatistics
where datediff(d, @date, [date])=0

delete ClickStatistics
where datediff(d, @date, [date])=0
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_MonthlyTransfer]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_MonthlyTransfer    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Task_Aff_MonthlyTransfer]
    @Month int, 
    @Year int    
    
AS
/*
Created: 20090812@DungTong
Task : Monthly transfer for all Affiliate
DB: DB052.Affiliate_MYM
Original:

Revisions:    
    - 200900217@Dung: 
            + Use Tier Commission to calculate monthly earning for each Affiliate based on Aff's member winlosts.
               To get commission value on what tier we do 3 phases:
                 .Calculate Number Of Qualified members on this month (member that have the turn over for this month is greater than or equal to 100$)
                 .Calculate winlost for each member on this month.
                 .Calculate Deductions (based on deduction setting from affiliate's Group)
                 .we have NetWinlost=WinLost-Deduction, TotalQMs
                 .For each Affiliate we get commission value by this way:
                      When TotalWinlost>0
                           Commission=Commission by Net Winlost
                      When TotalWinlost<=0                            
                        Commission=Min(Commission got by |NetWinlost| between MiAmount and MaxAmount, Commission got by TotalQMs between MinQM and MaxQMs)  
                 . Aff's Earning=NetWinlost * Commission
            + We have only one place to get Winlost and Other Data from MemberDaily. and the day excute this task must greater than the last day of selected month                
            + Qualifying member: Get Setting AFF_QMTurnOver from SystemSettings. Each member has  TurnOver>AFF_QMTurnOver --> qualified member
            + All the transactions have the status=completed
     - 20091203@Peter: Add Auto deduct transactions for Marketing fee
                        Deduction=Affiliate Net Earning * 20%
     - 20100115@Peter : Remove Auto deduct transactions for Marketing fee
                        http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&sid=58e8c31d51dac7ddbef907a7a258c6cf&p=14064#p14064
                        
     -20100211@Peter: #381 IRP - AffSite - Revise the calculations of the tier commission and PSP charge fee  
                      http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890      
                      
                     CNW=sum[(your total member's lost- your total member's won- bonus  - adjustment -  Marketing Fee)  * ExRate2].            
                     AComm= Min(commission get by |CNW|, commission get by TQM)
                     MF= |Total Member's Lost-Total Member's Won| *  5%
                     AE = CNW * Acomm
                     AFE = AE -  PSP * 50%
                     
                     Reupdate table AffDaily. 
                     
     -20100709@Peter:
                    http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&st=0&sk=t&sd=a&start=10
                    Change the way to calculation:

                    if CNW <0 then we must also use the condition of Qualifying Members ( old way does not have)
                     and the minimum commission in this case is 10%  if the qualifying members <5.
      -20100927@Peter:
                 http://ccs.sunplus.vn/viewtopic.php?f=4&t=3845&p=19236#p19236  
                 Change the way to calculation:
                   PSP=deposit * depositpercent + withdrawal * withdrawalpercent
                      For European Currencies: EURO,AUD,GBP, US$
                          + depositpercent=0.06
                          + withdrawalpercent=0.03
                      For Asian Currencies:
                          + depositpercent=0.02
                          + withdrawalpercent=0.02
                   PSP now follow tier commission
                   New Fee:  Odds Management Fee = 17 % MemberWinlost
                   CNW= MemberWinlost - Odds Management Fee - Marketing Fee - PSP Fee
                   From CNW => AComm
                   Affiliate Earning=(CNW - Bonus - Adjustement)* AComm                
                 

Param's Explanation:
• @Month: The month to transfer
• @Year :  The year to transfer     
*/
SET NOCOUNT ON

Declare @FirstDay smalldatetime,@LastDay smalldatetime,@TransType int, @MinimumNegativeCommission float

select @MinimumNegativeCommission = 0.1



Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0)),
    @TransType = 201

if @LastDay > Current_TimeStamp
BEGIN
    SELECT 'The month is not completed yet. So you cannot transfer!' Result
    SELECT @FirstDay as FirstDay,@LastDay as LastDay
    RETURN
END

--Check group History data is inserted
if(not exists(select top(1) 1 from CommGroupHistory (nolock) where monthdate=@LastDay) 
   or not exists(select top(1) 1 from GroupSettingHistory (nolock) where monthdate=@LastDay)
 --  or not exists(select top(1) 1 from DeductionSettingHistory (nolock) where monthdate=@LastDay)
   or  not exists(select top(1) 1 from AffGroupHistory (nolock) where monthdate=@LastDay)
  )
 BEGIN
    SELECT 'All group setting history data for selected month have not been updated yet. Please update data first by executing Task_Aff_GroupSettingBackup @Month,@Year!' Result
    SELECT @FirstDay as FirstDay,@LastDay as LastDay
    RETURN
 END
IF EXISTS (select top(1) 1 from AffCommission with(nolock)
            where WinlostDate=@LastDay)
BEGIN
    SELECT 'Please check the data. Transfers have been done for this month!' Result    
    SELECT @FirstDay as FirstDay,@LastDay as LastDay
    RETURN
END

--Get all Affiliates that is approved and IsClosed=false
declare @Status varchar(30)
select @Status='Approved'


--Check the currency is matched
if(exists(select 1
           from AffInfo ai with (nolock)
                inner join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and MonthDate=@LastDay
                inner join CommGroupHistory ch(nolock) on ch.groupid=gh.groupid
           where ai.currency <> ch.currency and ai.status=@Status ) ) 
begin
    SELECT 'The currency of Affiliate and his group does not match. Please check!' Result    
    SELECT @FirstDay as FirstDay,@LastDay as LastDay
    RETURN
end

--Create temp table to get summary data for each affiliate
CREATE TABLE #MemberSummary
(
    UserName varchar(100),
    AffID int,   
    ProductID int,

    MemWinlost money,
    MemBonus money,
    MemAdjustment money,
    MemPSP money,    
    MemDeposit money,
    MemTurnover money,    

    MemWinlost_aff money,
    MemBonus_aff money,
    MemAdjustment_aff money,
    MemPSP_aff money,    
    MemDeposit_aff money,
    MemTurnover_aff money
)

Insert into #MemberSummary( UserName ,
    AffID ,   
    ProductID,

    MemWinlost,
    MemBonus,
    MemAdjustment ,
    MemPSP,    
    MemDeposit,
    MemTurnover,    

    MemWinlost_aff,
    MemBonus_aff,
    MemAdjustment_aff,
    MemPSP_aff,    
    MemDeposit_aff,
    MemTurnover_aff
    )
 select username,AffID,ProductID
               ,sum(isnull(Winlost,0) * isnull(SysExRate,1)) as Winlost
               ,sum(isnull(Bonus,0) * isnull(SysExRate,1)) as Bonus
               ,sum(isnull(Adjustment,0) * isnull(SysExRate,1)) as Adjustment
               ,sum(isnull(PSP,0) * isnull(SysExRate,1)) as PSP              
               ,sum(isnull(Deposit,0) * isnull(SysExRate,1)) as Deposit
               ,sum(isnull(TurnOver,0) * isnull(SysExRate,1)) as TurnOver
               
                
                ,sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost_aff
               ,sum(isnull(Bonus,0) * isnull(AffExRate,1)) as Bonus_aff
               ,sum(isnull(Adjustment,0) * isnull(AffExRate,1)) as Adjustment_aff
               ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP_aff              
               ,sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit_aff
               ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver_aff
               
                
 from MemberDaily md  (nolock) 
 where WinlostDate between @FirstDay and @LastDay 
 group by username,ProductID,AffID

 
if(@@ROWCOUNT=0)
  begin
     Select 'There was no data for selected month to transfer!' as Result
     SELECT @FirstDay as FirstDay,@LastDay as LastDay  
     drop table #MemberSummary
     return
  end

--Create temp table to get summary data for each affiliate
CREATE TABLE #AffSummary
(
   /* [No] int IDENTITY(1,1),*/
    AffID int,
    Currency smallint,   
    GroupID int,
    ProductID int,

    MemWinlost money,
    MemBonus money,
    MemAdjustment money,
    MemPSP money,
    Marketing money,
    OddsFee money,
    MemDeposit money,
    MemTurnover money,
    NetWinlost money,

    MemWinlost_aff money,
    MemBonus_aff money,
    MemAdjustment_aff money,
    MemPSP_aff money,
    Marketing_aff money,
    OddsFee_aff money,
    MemDeposit_aff money,
    MemTurnover_aff money,
    NetWinlost_aff money,

    Commission decimal(9,8),
    TotalQM int, 
    TotalActivePlayer int, 
   
    HasBonus bit,
    HasMarketing bit,
    HasAdjustment bit,
    HasPSP bit,
    HasOddsFee bit,
    BonusPercent float,
    MarketingPercent float,
    AdjustmentPercent float,
    PSPPercent float,
    OddsFeePercent float
    
)

INSERT INTO #AffSummary
            (AffID,
             Currency,
             GroupID,
             ProductID,
             MemWinlost,
             MemBonus,
             MemAdjustment,
             MemPSP,            
             MemDeposit,
             MemTurnover,    
             MemWinlost_aff,
             MemBonus_aff,
             MemAdjustment_aff,
             MemPSP_aff,             
             MemDeposit_aff,
             MemTurnover_aff,
             TotalQM,            
             HasBonus,
             HasMarketing,
             HasAdjustment,
             HasPSP,
             HasOddsFee,
             BonusPercent,
             AdjustmentPercent,
             MarketingPercent,
             PSPPercent,
             OddsFeePercent)

Select ai.AffID as AffID
       ,ai.Currency as Currency
       ,gh.GroupID as GroupID
       ,r.ProductID as ProductID
       ,sum(isnull(r.MemWinlost,0)) as MemWinlost
       ,sum(isnull(r.MemBonus,0)) as MemBonus
       ,sum(isnull(r.MemAdjustment,0)) as MemAdjustment
       ,sum(isnull(r.MemPSP,0)) as MemPSP       
       ,sum(isnull(r.MemDeposit,0)) as MemDeposit
       ,sum(isnull(r.MemTurnover,0)) as MemTurnover

       ,sum(isnull(r.MemWinlost_aff,0)) as MemWinlost_aff
       ,sum(isnull(r.MemBonus_aff,0)) as MemBonus_aff
       ,sum(isnull(r.MemAdjustment_aff,0)) as MemAdjustment_aff
       ,sum(isnull(r.MemPSP_aff,0)) as MemPSP_aff       
       ,sum(isnull(r.MemDeposit_aff,0)) as MemDeposit_aff
       ,sum(isnull(r.MemTurnover_aff,0)) as MemTurnover_aff
           
       ,sum(case when isnull(r.MemTurnover,0)>=ch.QualifiedAmount then 1 else 0 end) as TotalQM      
       
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Bonus',@LastDay) as HasBonus
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Marketing',@LastDay) as HasMarketing 
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Adjustment',@LastDay) as HasAdjustment       
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'PSP',@LastDay) as HasPSP
       ,dbo.Aff_HasDeduction(gh.GroupID,r.ProductID,'Odds Fee',@LastDay) as HasOddsFee
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Bonus',@LastDay) as BonusPercent
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Adjustment',@LastDay) as AdjustmentPercent
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Marketing',@LastDay) as MarketingPercent
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'PSP',@LastDay) as PercentPSP
       ,dbo.Aff_GetDeductionPercent(ai.AffID,r.ProductID,'Odds Fee',@LastDay) as OddsFeePercent
FROM AffInfo ai with (nolock)
     inner join AffGroupHistory gh(nolock) on gh.AffID=ai.AffID and gh.MonthDate=@LastDay    
     inner join CommGroupHistory ch(nolock) on ch.groupid=gh.groupid and ch.MonthDate=@LastDay 
     inner join #MemberSummary r on r.AffID=ai.AffID
 
where ai.status=@Status
group by ai.AffID 
       ,ai.Currency
       ,gh.GroupID
       ,r.ProductID


 delete from #AffSummary where ProductID is null

 update a
 set a.TotalActivePlayer=ISNULL(t.TotalActivePlayer,0)
 from #AffSummary a with (nolock)
 left join 
 (
 select m.AffID,COUNT(distinct m.username) as TotalActivePlayer
 from #MemberSummary m 
 where m.MemTurnover>0 or m.MemDeposit>0
 Group by m.AffID
 ) t on a.AffID=t.AffID



--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID

update a
set a.MemPSP= Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1),
    a.MemPSP_aff= Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1),
    a.Marketing=Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1),
    a.Marketing_aff=Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1),
    a.OddsFee=Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) ,
    a.OddsFee_aff=Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) , 
   
    a.NetWinlost_aff=(-isnull(a.MemWinlost_aff,0) 
                 - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) 
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1) 
                ),
    a.NetWinlost=(-isnull(a.MemWinlost,0) 
                 - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
                ),
                
     a.commission=isnull((select  top(1) Commission
                          from 
                            (
                                select isnull((select Commission
                                              from GroupSettingHistory(nolock)
                                              where GroupID=a.GroupID 
                                                    and ProductID=a.ProductID
                                                    and MonthDate=@LastDay
                                                    and floor(
                                                              abs(
                                                               -isnull(a.MemWinlost_aff,0) 
                                                                 - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)
                                                                -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) 
                                                                 -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1) 
                                                                )
                                                            ) 
                                                        between MinAmount and MaxAmount),0) as Commission
                                union all                             
                                  select isnull((select top(1) Commission 
                                                      from GroupSettingHistory(nolock)
                                                      where GroupID=a.GroupID 
                                                            and ProductID=a.ProductID 
                                                            and MonthDate=@LastDay
                                                            and a.TotalQM between MinQM and MaxQM
                                                   ),0)
                                           as Commission
                            ) t  
                            order by t.Commission asc
                    ),0)
from #AffSummary a

update a
set a.Commission = @MinimumNegativeCommission
from #AffSummary a
where a.NetWinlost_aff < 0 and a.Commission = 0     
      and a.GroupID not in (select groupId from CommGroup with (nolock) where GroupName='NoCommission')
       and a.ProductID in (
        select distinct ProductID from GroupSettingHistory (nolock) where GroupID=a.GroupID     and DATEDIFF(m,MonthDate,@LastDay)=0
      )    
--Insert transaction to AffTrans and AffCommission
declare @WinlostDate smalldatetime
select @WinlostDate=current_timestamp

declare  @SystemCurrency smallint
set @SystemCurrency=dbo.Aff_GetSystemCurrencyID()



begin transaction

BEGIN TRY
    declare @Temp table(RefID int, AffID int, ProductID tinyint) 
    INSERT INTO [AffCommission]
           ([AffID]
           ,[GroupID]
           ,[ProductID]
           ,[WinlostDate]
           ,[AffCurrency]
           ,[SysCurrency]
           ,[QualifiedMember]
           ,[ActivePlayer]
           ,[Commission]
           ,[HasBonus]
           ,[HasAdjustment]
           ,[HasMarketing]
           ,[HasPSP]
           ,[HasOddsFee]
           ,[Status]
           ,[AffWinlost]
           ,[MemberWinlost]
           ,[MemberBonus]
           ,[MemberAdjustment]
           ,[MemberPSP]
           ,[MemberSum]
           ,[MemberTurnover]
           ,[MemberDeposit]
           ,[Marketing]
           ,[MemOddsFee]
           ,[AffWinlost_aff]
           ,[MemberWinlost_aff]
            ,[MemberBonus_aff]
           ,[MemberAdjustment_aff]
           ,[MemberPSP_aff]
           ,[MemberSum_aff]
           ,[MemberTurnover_aff]
           ,[MemberDeposit_aff]
           ,[Marketing_aff]
           ,[MemOddsFee_aff])

    
    output inserted.RefID,inserted.AffID,inserted.ProductID into @Temp 
    select AffID,GroupID,ProductID,@LastDay,Currency,@SystemCurrency, TotalQM,TotalActivePlayer,Commission 
           ,HasBonus,HasAdjustment,HasMarketing,HasPSP,HasOddsFee, @Status    
          ,(NetWinlost-Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)           
          ,MemWinlost
          ,MemBonus
          ,MemAdjustment
          ,MemPSP
          ,-NetWinlost
          ,MemTurnover
          ,MemDeposit    
          ,Marketing
         , OddsFee
         ,(NetWinlost_aff-Cast(a.HasBonus as int)* isnull(a.MemBonus_aff,0)*isnull(a.BonusPercent,1))  * isnull(Commission,0)           
          ,MemWinlost_aff
          ,MemBonus_aff
          ,MemAdjustment_aff
          ,MemPSP_aff
          ,-NetWinlost_aff
          ,MemTurnover_aff
          ,MemDeposit_aff    
          ,Marketing_Aff
         , OddsFee_Aff
    from #AffSummary a (nolock)    
    
    update d
    set d.RelNo=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.RefID>0 )
   from AffCommission d with (rowlock,updlock)       
   where d.WinlostDate=@LastDay

    insert into AffTrans(AffID,TransDate,CompletedDate,Amount,Status,Description,Creator,AffCurrency,SysCurrency,SysExRate,TransType)
    select a.AffID,@LastDay,@WinlostDate,sum((NetWinlost-Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1) )  * isnull(Commission,0)),@Status, 'Monthly Earning',
         9999,a.Currency,@SystemCurrency,dbo.Aff_GetExchangeRate(a.Currency,@SystemCurrency,@LastDay),@TransType
    from #AffSummary a (nolock)          
    group by a.AffID,a.Currency
    

    update d
    set d.RefID=(select top(1) RefID from @Temp d1 where d1.AffID=d.AffID and d1.RefID>0)
   from AffTrans d with (rowlock,updlock)       
   where d.TransDate=@LastDay and d.TransType=@TransType 
        
       
   update ad 
     set 
        ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),
        ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),
        ad.AffNetWinlost=( -isnull(ad.MemWinlost,0) 
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                 
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
                       
                       ) * isnull(a.commission,0),
                       
       ad.HouseNetWinlost= (-isnull(ad.MemWinlost,0) 
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                 
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
                           ) * (1-isnull(a.commission,0)) 
                
      from AffDaily ad with (rowlock,updlock)  
      left join #AffSummary a with (nolock) on a.AffID=ad.AffID and a.ProductID=ad.ProductID     
   where datediff (mm,ad.Winlostdate, @FirstDay)=0  
   
   update ad 
     set /*ad.MemMarketing=Cast(isnull(a.HasMarketing,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.MarketingPercent,0) ,
         ad.MemOddsFee=Cast(isnull(a.HasOddsFee,0) as int) *  abs(isnull(ad.MemWinlost,0)) * isnull(a.OddsFeePercent,0) ,         */
        ad.AffWinlost = -isnull(ad.MemWinlost,0) *  isnull(a.commission,0),
        ad.HouseWinlost=-isnull(ad.MemWinlost,0) * (1-isnull(a.commission,0)),
        ad.AffNetWinlost=( -isnull(ad.MemWinlost,0) 
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                 
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
                       
                       ) * isnull(a.commission,0),
                       
       ad.HouseNetWinlost= (-isnull(ad.MemWinlost,0) 
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)                 
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus,0)*isnull(a.BonusPercent,1)
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment,0) * isnull(a.AdjustmentPercent,1) */
                           ) * (1-isnull(a.commission,0)), 

        ad.AffWinlost_aff = -isnull(ad.MemWinlost_aff,0) *  isnull(a.commission,0),
        ad.HouseWinlost_aff=-isnull(ad.MemWinlost_aff,0) * (1-isnull(a.commission,0)),
        ad.AffNetWinlost_aff=( -isnull(ad.MemWinlost_aff,0) 
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) 
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1)                 
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus_aff,0)*isnull(a.BonusPercent,1)
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment_aff,0) * isnull(a.AdjustmentPercent,1) */
                       
                       ) * isnull(a.commission,0),
                       
       ad.HouseNetWinlost_aff= (-isnull(ad.MemWinlost_aff,0) 
                            - Cast(a.HasPSP as int)* isnull(a.MemPSP_aff,0)*isnull(a.PSPPercent,1)
                            -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.OddsFeePercent,1) 
                            -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost_aff,0)) * isnull(a.MarketingPercent,1)                 
                            - Cast(isnull(a.HasBonus,0) as int)* isnull(ad.MemBonus_aff,0)*isnull(a.BonusPercent,1)
                            /*-Cast(isnull(a.HasAdjustment,0) as int) *  isnull(ad.MemAdjustment_aff,0) * isnull(a.AdjustmentPercent,1) */
                           ) * (1-isnull(a.commission,0)) 
                
      from AffDailySummary ad with (rowlock,updlock)  
      left join #AffSummary a with (nolock) on a.AffID=ad.AffID and a.ProductID=ad.ProductID     
   where datediff (mm,ad.Winlostdate, @FirstDay)=0  
   
   
   
END TRY

BEGIN CATCH
    rollback transaction    
    drop table #AffSummary
    drop table #MemberSummary
    PRINT ERROR_MESSAGE()
    RETURN
END CATCH

commit transaction


declare @TaskID int,@LogID int , @RunDate datetime

select @RunDate=getdate(), @Status='completed'

select @TaskID= TaskID from TaskManager(nolock) where TaskName='Commission Monthly Transfer'
exec [dbo].[Aff_TaskLogIns]
    @TaskID,
    @RunDate,
    @Status,
    @LogID OUTPUT
drop table #AffSummary
drop table #MemberSummary
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_MemberInfoUpdateCreatedDate]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_MemberInfoUpdateCreatedDate    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Task_Aff_MemberInfoUpdateCreatedDate]   
    @XmlData XML,  
    @ErrCode int = 0 OUTPUT,  
    @ErrMsg nvarchar(500) = '' OUTPUT  
AS   
/*
    Task : Update created date for users deposited
    Author : Johnny@20130328
    DB: DB052.Affiliate_MYM
    Original: [Aff_MemberInfoImportData]
    Revisions:         
        Johnny@2013Mar27: Fix to update Clickstatistics, Clickstatistics_bk and ClickstatisticsSum table
*/

--Import new Data here 
DECLARE @TmpClick TABLE (ClickId  bigint)
 
DECLARE @TempTrans TABLE(UserName varchar(30), IBCUserName varchar(50), Date datetime)  
  
insert into @TempTrans --Convert xml to table  
  
Select      
    [Table].[Column].value('./@username', 'varchar(30)') as [UserName],    
    [Table].[Column].value('./@ibcusername', 'varchar(50)') as [IBCUserName],    
    [Table].[Column].value('./@date', 'datetime') as [Date]  
from @XmlData.nodes('/root/trans') as [Table]([Column])  

UPDATE m  
SET m.CreatedDate= temp.Date   
    , m.IBCUsername = temp.IBCUserName
OUTPUT Inserted.ClickId INTO @TmpClick
FROM MemberInfo AS m   
    INNER JOIN @TempTrans AS temp ON m.UserName = temp.UserName;  



--Update Click Statistics
Declare @MinClickID bigint, @MinClickID_Statistics bigint

Select @MinClickID = min(ClickId)
from @TmpClick

select @MinClickID_Statistics = min(ClickId)
from ClickStatistics nolock

if @MinClickID < @MinClickID_Statistics
begin
    --Temp table to insert click value to update to clickstatisticsSum table
    Declare @TmpClickDetail table ([date] smalldatetime)

    insert into @TmpClickDetail(date)
    Select distinct c.date
    from @TmpClick as t
        inner join ClickStatistics_bk as c on t.[clickId] = c.ClickID
    where c.ClickId < @MinClickID_Statistics
    
    Delete ClickStatisticsSum
    where Date in (Select [DATE] from @TmpClickDetail)
     --Summary for Daily by Domain and Date
    insert into ClickStatisticsSum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
    select  c.AffID,
            DomainReferrer,
            c.[Date] as [Date],
            SportCode,
            LanguageCode,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
            SUM(isnull(FDM, 0)) as  FDM 
    from ClickStatistics_bk c with (nolock)
        left join @TmpClickDetail t on c.Date = t.Date
        left join 
            (Select ClickId, 
                SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
            from MemberInfo m with (nolock)             
            group by ClickId
            ) as m on c.ClickId = m.ClickId
    group by c.AffID, DomainReferrer, c.[Date], SportCode, LanguageCode
end
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_MemberInfoImportData]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_MemberInfoImportData    Script Date: 7/29/2013 1:41:19 AM ******/
CREATE Procedure [dbo].[Task_Aff_MemberInfoImportData]    
    @AdminID int,    
    @XmlData XML,    
    @RegisteredDate smalldatetime,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*
    Task : Import member info from xml into table MemberInfo
    Author : Joseph@20130114
    DB: DB052.Affiliate_MYM
    Original: [Aff_MemberInfoImportData]
    Revisions:         
        20120122: apply currency converter
        Johnny@2013Mar27: Fix to update Clickstatistics table
*/
BEGIN  
SET NOCOUNT ON  

DECLARE @TmpTable TABLE (UserName  VARCHAR(30))
--Import new Data here
DECLARE @TempTrans TABLE(
    UserName varchar(30),
    DepositCustID int,
    Btag varchar(100), 
    AffID int,
    ClickID bigint,
    RegisteredDate datetime, 
    Currency varchar(6),
    CountryID varchar(8))

insert into @TempTrans --Convert xml to table

Select
        
        [Table].[Column].value('./@username', 'varchar(30)') as [UserName],
        [Table].[Column].value('./@playerid', 'int') as [DepositCustID],
        [Table].[Column].value('./@btag', 'varchar(100)') as [Btag],        
        [Table].[Column].value('./@affid', 'int') as [AffID],        
        [Table].[Column].value('./@clickid', 'int') as [ClickID],        
        @RegisteredDate as [RegisteredDate],
        [Table].[Column].value('./@currency', 'varchar(6)') as [Currency],
        [Table].[Column].value('./@country', 'varchar(8)') as [CountryID]
    from @XmlData.nodes('/root/trans') as [Table]([Column])

--Update info if this user exists in Memberinfo table
UPDATE m
SET 
    m.DepositCustID = temp.DepositCustID,    
    m.Btag = temp.Btag, m.AffID = temp.AffID,
    m.ClickID = temp.ClickID,
    m.Currency = cc.ExchangeID, 
    m.RegisteredDate = temp.RegisteredDate,
    m.CountryID = temp.CountryID

OUTPUT Inserted.UserName INTO @TmpTable
FROM 
    MemberInfo AS m 
    INNER JOIN @TempTrans AS temp ON m.UserName = temp.UserName
    INNER JOIN CurrencyConverter cc ON temp.Currency = cc.PartnerCurrency AND cc.ApplicationID = 1
    inner join AffInfo as ai with(nolock) on m.AffId = ai.AffId

--insert new members into Memberinfo table
INSERT INTO MemberInfo(
            UserName, DepositCustID, Btag, 
            AffID, ClickID, Currency, CountryID, RegisteredDate)
SELECT temp.UserName, temp.DepositCustID, temp.Btag, 
            temp.AffID, temp.ClickID, cc.ExchangeID,
            CountryID, temp.RegisteredDate 
FROM @TempTrans temp
    INNER JOIN CurrencyConverter cc ON temp.Currency = cc.PartnerCurrency AND cc.ApplicationID = 1
    inner join AffInfo as ai with(nolock) on temp.AffId = ai.AffId
WHERE temp.UserName NOT IN (SELECT UserName FROM @TmpTable);


--Update Click Statistics
Declare @MinClickID bigint, @MinClickID_Statistics bigint

Select @MinClickID = min(ClickId)
from @TempTrans

select @MinClickID_Statistics = min(ClickId)
from ClickStatistics nolock

if @MinClickID < @MinClickID_Statistics
begin
    --Temp table to insert click value to update to clickstatisticsSum table
    Declare @TmpClickDetail table ([date] smalldatetime)

    insert into @TmpClickDetail(date)
    Select distinct c.date
    from @TempTrans as t
        inner join ClickStatistics_bk as c on t.[clickId] = c.ClickID
    where c.ClickId < @MinClickID_Statistics

    
    Delete ClickStatisticsSum
    where Date in (Select [DATE] from @TmpClickDetail)
     --Summary for Daily by Domain and Date
    insert into ClickStatisticsSum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
    select  c.AffID,
            DomainReferrer,
            c.[Date] as [Date],
            SportCode,
            LanguageCode,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
            SUM(isnull(FDM, 0)) as  FDM 
    from ClickStatistics_bk c with (nolock)
        inner join @TmpClickDetail t on c.Date = t.Date--Fix for cannot get date of click
        left join 
            (Select ClickId, 
                SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
            from MemberInfo m with (nolock)             
            group by ClickId
            ) as m on c.ClickId = m.ClickId
    group by c.AffID, DomainReferrer, c.[Date], SportCode, LanguageCode
end


END
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_MemberDailyTransactionImportData]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_MemberDailyTransactionImportData    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Task_Aff_MemberDailyTransactionImportData]	
	@AdminID int,	
	@XmlData XML,	
	@WinlostDate smalldatetime,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*
	Task : Import member daily (deposit, withdrawal, Bonus,....) from xml into table MemberDaily
	Author : Joseph@20130114
	DB: DB052.Affiliate_MYM
	Original: [Aff_MemberDailyImportData]
	Revisions: 		
		- Johnny@20130402: Fix the way import transfer transaction
*/
BEGIN  
SET NOCOUNT ON 

-- check data is calculated for this month?

if exists(select top(1) 1 from AffCommission (nolock) where DATEDIFF(m,@WinlostDate,Winlostdate)=0)
   return

Declare @SportsBookID tinyint, @SystemCurrency smallint--Deposit, withdraw,... is assigned to sportbook

select @SportsBookID = dbo.Aff_GetSportID('SportsBook') 
Exec Aff_GetSystemCurrency @SystemCurrency = @SystemCurrency output

DECLARE @TmpTable TABLE (UserName  VARCHAR(30), WinlostDate smalldatetime)
--Import new Data here
DECLARE @TempTrans TABLE(
	UserName varchar(30),
	WinlostDate smalldatetime,
	Currency varchar(5),
	Deposit money,
	Withdrawal money, 
	Bonus money,
	Adjustment money,
	AffTransfer money,
	Transfer3rd money);

INSERT INTO @TempTrans --Convert xml to table
SELECT				
		[Table].[Column].value('./@username', 'varchar(30)') as [UserName],		
		[Table].[Column].value('./@winlostdate', 'smalldatetime') as [WinlostDate],
		[Table].[Column].value('./@currency', 'varchar(5)') as [Currency],
		[Table].[Column].value('./@deposit', 'money') as [Deposit],
		[Table].[Column].value('./@withdrawal', 'money') as [Withdrawal],
		[Table].[Column].value('./@bonus', 'money') as [Bonus],
		[Table].[Column].value('./@adjustment', 'money') as [Adjustment],
		[Table].[Column].value('./@afftransfer', 'money') as [AffTransfer],
		[Table].[Column].value('./@transfer3rd', 'money') as [Transfer3rd]
	FROM @XmlData.nodes('/root/trans') as [Table]([Column]);

UPDATE m
SET 
      m.[Deposit] = temp.Deposit,
      m.[Withdrawal] = temp.Withdrawal,
      m.[Bonus] = temp.Bonus,
      m.[Adjustment] = temp.Adjustment,     
	  m.[AffTransfer] = temp.AffTransfer,     
	  m.[Transfer3rd] = temp.Transfer3rd   
	   
OUTPUT Inserted.UserName,Inserted.WinlostDate INTO @TmpTable
FROM MemberDaily AS m 
	INNER JOIN @TempTrans AS temp ON m.UserName = temp.UserName			
Where m.ProductID = @SportsBookID
        AND m.WinlostDate = temp.WinlostDate
			AND temp.UserName != ''
			AND temp.Currency != ''
        and temp.WinlostDate=@WinlostDate

INSERT INTO MemberDaily
			([UserName]
			,[WinlostDate]
			,[ProductID]       
				,[AffID]       
			,[Currency] 
			,[AffCurrency]   
			,[AffExRate]
			,[SysCurrency]
			,[SysExrate]
			,[Deposit]
			,[Withdrawal]
			,[Bonus]
			,[Adjustment]
			,[Turnover]
			,[Outstanding]
			,[Winlost]
			,[DrawGame]
			,AffTransfer
			,Transfer3rd
           ) 	
SELECT		t1.UserName, 
			WinlostDate, 
			@SportsBookID,--is not bet transaction -> productid = sportbook ID
			mi.AffId,
			mi.Currency, 
			ai.Currency,   
			dbo.Aff_GetExchangeRate(mi.Currency, ai.Currency, @WinlostDate) as AffExRate,
			@SystemCurrency,
			dbo.Aff_GetExchangeRate(mi.Currency, @SystemCurrency, @WinlostDate) as SysExRate, 
			Deposit,
			Withdrawal,
			Bonus,	
			Adjustment,
			0 as [Turnover],
			0 as [Outstanding],
			0 as [Winlost],
			0 as [DrawGame],
			t1.AffTransfer,
			t1.Transfer3rd
FROM @TempTrans t1
	INNER JOIN MemberInfo AS mi (nolock) ON t1.UserName = mi.UserName  
	inner join affinfo as ai with (nolock) on mi.AffId = ai.AffId
	-- inner join Exchange as ex with (nolock) on ai.Currency = ex.ExchangeId

WHERE t1.WinlostDate=@WinlostDate 
       AND t1.UserName != ''
		AND t1.Currency != '' 
		AND NOT EXISTS (SELECT 1 FROM @TmpTable t2 WHERE t1.UserName = t2.UserName AND 
					t1.WinlostDate = t2.WinlostDate)
       AND mi.IsRemoved = 0


--Update MemberDaily PSP, Marketting fee,...
Update m
set PSP = (abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'PSP',@WinlostDate),0),
	Marketing = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Marketing',@WinlostDate),0),
	MemOddsFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Odds Fee',@WinlostDate),0),
	MemPLayTechFee = abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'PlayTech Royalties', @WinlostDate),0),
	MemWinlostFake = -(-Winlost  
						   - ((abs(Deposit) * e.DepositPercent + abs(Withdrawal) * e.WithdrawalPercent))* isnull(dbo.Aff_GetDeductionPercent(AffID,@SportsBookID,'PSP',@WinlostDate),0)  
						   -  abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Marketing', @WinlostDate),0)  
						   - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'Odds Fee', @WinlostDate),0)  
						   - abs(Winlost) * isnull(dbo.Aff_GetDeductionPercent(AffID, ProductId, 'PlayTech Royalties', @WinlostDate),0)  
						)
from MemberDaily as m (nolock)
	inner join Exchange as e (nolock) on m.Currency = e.ExchangeId

where m.WinlostDate=@WinlostDate


------------Update others field MemberDaily, insert data for AffDaily, AffDailySummary table

--Delete data and re-import AffDaily, AffDailySummary
DELETE FROM AffDaily
WHERE WinlostDate = @WinlostDate

DELETE FROM [AffDailySummary]
WHERE WinlostDate = @WinlostDate
		
	
INSERT INTO AffDaily
        ([AffID]
        ,[MemCurrency]
        ,[Winlostdate]
        ,[ProductID]
        ,[AffCurrency]
        ,[AffExRate]
        ,[SysCurrency]
        ,[SysExRate]
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
		,[MemAffTransfer]
		,[MemTransfer3rd]
		,[MemBetCount]
		,[MemPlayerComm]
		)

select m.[AffID]
		,m.[Currency] as [MemCurrency]
        ,m.[WinlostDate]
        ,m.[ProductID]
        ,m.[AffCurrency]
        ,m.[AffExRate]
        ,m.[SysCurrency]
        ,m.[SysExRate]
		,Sum(Deposit) as MemDeposit
		,Sum(Withdrawal) as MemWithdrawal
        ,Sum(Turnover) as MemTurnover
		,Sum(Bonus) as MemBonus
		,Sum(Adjustment) as MemAdjustment
		,Sum(Marketing) as MemMarketing	
		,Sum(PSP) as MemPSP
        ,Sum(Winlost) as MemWinlost
        ,0 as AffWinlost
        ,-Sum(Winlost)  as HouseWinlost
        ,0 as AffNetWinlost
        ,0 as HouseNetWinlost
        ,Sum(MemWinlostFake) as MemWinlostFake
        ,Sum(MemOddsFee) as MemOddsFee          		   
		,Sum(MemPLayTechFee) as MemPLayTechFee
		,Sum([AffTransfer])
		,Sum([Transfer3rd])
		,Sum([BetCount])
		,Sum([PlayerComm])
from MemberDaily(nolock) as m
where m.WinlostDate = @WinlostDate
group by m.AffID
	,m.Winlostdate
	,m.ProductID
	,m.Currency
    ,m.[AffCurrency]
    ,m.[AffExRate]
    ,m.[SysCurrency]
    ,m.[SysExRate]

update AffDaily with (rowlock,updlock)    
set 
	HouseNetWinLost=HouseWinLost  
		 - isnull(MemBonus,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',Winlostdate),0)     
		 -isnull(MemAdjustment,0)  
		 -isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',Winlostdate),0)  
		 - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',Winlostdate),0)  
		 - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',Winlostdate),0)
		 - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',Winlostdate),0)  
where WinlostDate = @winlostdate

--Update [AffDailySummary] table
INSERT INTO [dbo].[AffDailySummary]  
	([AffID]  
	,[Winlostdate]  
	,[ProductID]
	,[AffCurrency]
	,[SysCurrency]   
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
	,[MemPLayTechFee]
	,[MemWinlostFake]
	,[MemAffTransfer]
	,[MemTransfer3rd]
	,[MemBetCount]
	,[MemPlayerComm]
	,[MemDeposit_aff]
	,[MemWithdrawal_aff]
	,[MemTurnover_aff]
	,[MemBonus_aff]
	,[MemAdjustment_aff]
	,[MemMarketing_aff]
	,[MemPSP_aff]
	,[MemWinlost_aff]
	,[AffWinlost_aff]
	,[HouseWinlost_aff]
	,[AffNetWinlost_aff]
	,[HouseNetWinlost_aff]
	,[MemOddsFee_aff]
	,[MemWinlostFake_aff]
	,[MemPLayTechFee_aff]
	,[MemAffTransfer_aff]
	,[MemTransfer3rd_aff]	
	,[MemPlayerComm_aff]
     )  
  
select [AffID]  
	,[Winlostdate]  
	,[ProductID]
	,[AffCurrency]
	,[SysCurrency]  
	,Sum([MemDeposit] * SysExRate) as [MemWithdrawal]
	,Sum([MemWithdrawal] * SysExRate) as [MemWithdrawal]
	,Sum([MemTurnover] * SysExRate) as [MemTurnover]
	,Sum([MemBonus] * SysExRate) as   [MemBonus]
	,Sum([MemAdjustment] * SysExRate) as   [MemAdjustment]
	,Sum([MemMarketing] * SysExRate) as  [MemMarketing] 
	,Sum([MemPSP] * SysExRate) as   [MemPSP]
	,Sum([MemWinlost] * SysExRate) as   [MemWinlost]
	,Sum([AffWinlost] * SysExRate) as [AffWinlost]  
	,-Sum([MemWinlost] * SysExRate) as  [HouseWinlost] 
	,0 as  [AffNetWinlost] 
	,0 as  [HouseNetWinlost] 
	,Sum([MemOddsFee] * SysExRate) as   [MemOddsFee]
	,Sum([MemPLayTechFee] * SysExRate) as [MemPLayTechFee]
	,0 as [MemWinlostFake]

	,Sum([MemAffTransfer] * SysExRate)
	,Sum([MemTransfer3rd] * SysExRate)
	,Sum([MemBetCount])
	,Sum([MemPlayerComm] * SysExRate)

	,Sum([MemDeposit] * AffExRate) as [MemDeposit_aff]
	,Sum([MemWithdrawal] * AffExRate) as [MemWithdrawal_aff]
	,Sum([MemTurnover] * AffExRate) as [MemTurnover_aff]
	,Sum([MemBonus] * AffExRate) as [MemBonus_aff]
	,Sum([MemAdjustment] * AffExRate) as [MemAdjustment_aff]
	,Sum([MemMarketing] * AffExRate) as [MemMarketing_aff]
	,Sum([MemPSP] * AffExRate) as [MemPSP_aff]
	,Sum([MemWinlost] * AffExRate) as [MemWinlost_aff]
	,0 as [AffWinlost_aff]
	,-Sum([MemWinlost] * AffExRate) as [HouseWinlost_aff]
	,0 as [AffNetWinlost_aff]
	,0 as [HouseNetWinlost_aff]
	,Sum([MemOddsFee] * AffExRate) as [MemOddsFee_aff]
	,Sum([MemWinlostFake] * AffExRate) as [MemWinlostFake_aff]
	,Sum([MemPLayTechFee] * AffExRate) as [MemPLayTechFee_aff]

	,Sum([MemAffTransfer] * AffExRate)
	,Sum([MemTransfer3rd] * AffExRate)	
	,Sum([MemPlayerComm] * AffExRate)


from AffDaily(nolock)  
where WinlostDate = @winlostdate
group by AffID, Winlostdate, ProductID, AffCurrency, SysCurrency



update AffDailySummary with (rowlock,updlock)  
set 
	 /*MemWinlostFake=  -(-MemWinlost  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)
		  - MemPSP * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)) ,      
     */
	  HouseNetWinlost=(  
		  -MemWinlost  
		  -MemBonus * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)  
		  -MemAdjustment  
		  -MemPSP * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
		  - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)  
		  ) ,
		  
		  HouseNetWinlost_aff=(  
		  -MemWinlost_aff  
		  -MemBonus_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)  
		  -MemAdjustment_aff  
		  -MemPSP_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)  
		  - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
		  - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
		  - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)  
		  )   



where WinlostDate = @winlostdate



-----------Update MemwinlostFake for last date (forex winlost for previous date) of each account
declare @temp table(affid int,ProductID int,totalWinlost money, oddsFeePercent float,marketingPercent float,PSPPercent float, PlaytechPercent float,WLFake money,totalPSP money,maxWinlostDate smalldatetime,previousMaxWinlostDate smalldatetime,firstday smallDateTime)  
  
insert into @temp(Affid,maxWinlostDate,ProductID)  
select affid,max(winlostdate),ProductID  
from AffDailySummary (nolock)  
where datediff(m,@winlostdate,WinlostDate)=0--  and ProductID = @SportsBookID      
group by affid,ProductID,month(winlostdate),year(winlostdate)  
  
update t  
set t.previousMaxWinlostDate=isnull(  
          (select max(winlostdate)   
           from AffDailySummary (nolock)   
            where ProductID=t.ProductID and winlostdate<t.maxWinlostDate   
            and datediff(m,winlostdate,t.maxWinlostDate)=0  
            and affid=t.affid  
            ) ,t.maxWinlostDate)  
	,t.firstday=[dbo].[Aff_GetFirstDayOfMonth](t.maxWinlostDate)      
	,t.oddsFeePercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'Odds Fee',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
	,t.marketingPercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'Marketing',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
	,t.PSPPercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'PSP',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
	,t.PlaytechPercent=dbo.Aff_GetDeductionPercent(AffID,t.ProductID,'PlayTech Royalties',[dbo].[Aff_GetLastDayOfMonth] (t.maxWinlostDate))  
from @temp t  
  
--reupdate WinlostFake of previous MaxWinlostDate for AffDailySummary    
update ad    
set ad.MemWinlostFake=-(-isnull(ad.MemWinlost,0)  
      -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'Odds Fee',ad.Winlostdate),0)  
      -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'Marketing',ad.Winlostdate),0)          
      -abs(isnull(ad.MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'PlayTech Royalties',ad.Winlostdate),0)          
      -isnull(ad.MemPSP,0) *  isnull(dbo.Aff_GetDeductionPercent(ad.AffID,t.ProductID,'PSP',ad.Winlostdate),0)          
     )  
from AffDailySummary ad with (rowlock,updlock)        
	inner join @temp t on t.affid=ad.AffID and t.previousMaxWinlostDate=ad.WinlostDate and t.ProductID=ad.ProductID  
  
--don so tien winlostFake tat ca vao ngay cuoi cung cua thang nay 
update d    
set d.totalWinlost=isnull(c.totalwinlost,0)  
   ,d.WLFake=isnull(c.memWinlostFake,0)  
   ,d.totalPSP=isnull(c.memPSP,0)   
from @temp d  
	left join  
		( select t.affid,t.ProductID,sum(ad.memwinlost) totalwinlost,sum(ad.memWinlostFake) memWinlostFake, sum(ad.MemPSP) as memPSP  
		from AffDailySummary ad (nolock)   
			inner join @temp t on t.AffID=ad.AffID and t.ProductID=ad.ProductID  
		where ad.WinlostDate between t.firstday and  t.previousMaxWinlostDate  
		--and ad.ProductID = @SportsBookID  
		group by t.Affid,t.ProductID     
		) c on c.AffID=d.AffID  and c.ProductID=d.ProductID   
  
--Member Winlost - All Fee - Winlost fake from first date of month to yesterday
update d  
Set MemWinlostFake=-(-(d1.totalwinlost + d.memwinlost) - abs (d1.totalwinlost + d.memwinlost) * (d1.oddsFeePercent+d1.marketingPercent+d1.PlaytechPercent)-(d1.totalPSP+d.MemPSP)* d1.PSPPercent)- d1.WLFake  
from AffDailySummary d with (rowlock,updlock)  
	inner join @temp d1 on d1.affid=d.affid and  d1.maxWinlostDate=d.winlostdate and d1.ProductID=d.ProductID       
where d1.previousMaxWinlostDate < d1.maxWinlostDate  
	--and d.ProductID = @SportsBookID
  

END
GO
/****** Object:  StoredProcedure [dbo].[Task_Aff_MemberDailyImportData]    Script Date: 07/30/2013 04:21:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Task_Aff_MemberDailyImportData    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE PROCEDURE [dbo].[Task_Aff_MemberDailyImportData]    
    @AdminID int,    
    @XmlData XML,
    @WinlostDate smalldatetime,    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*3
    Task : Import member daily transaction from xml into table MemberDaily
    Author : Joseph@20130114
    DB: DB052.Affiliate_ZZun
    Original: [Aff_MemberDailyImportData]
    Revisions:         
*/
BEGIN  
SET NOCOUNT ON  

-- check data is calculated for this month?

if exists(select top(1) 1 from AffCommission (nolock) where DATEDIFF(m,@WinlostDate,Winlostdate)=0)
   return

Declare @SystemCurrency smallint

Exec Aff_GetSystemCurrency @SystemCurrency = @SystemCurrency output


DECLARE @TmpTable TABLE (UserName  VARCHAR(30), WinlostDate smalldatetime, ProductID tinyint)
--Import new Data here
DECLARE @TempTrans TABLE(
    UserName varchar(30),
    WinlostDate smalldatetime,
    ProductID tinyint,
    Turnover money,
    Outstanding money, 
    Winlost money,
    DrawGame money,
    
    BetCount int,
    PlayerComm money);

INSERT INTO @TempTrans --Convert xml to table
SELECT                
        [Table].[Column].value('./@username', 'varchar(30)') as [UserName],        
        [Table].[Column].value('./@winlostdate', 'smalldatetime') as [WinlostDate],
        [Table].[Column].value('./@productid', 'tinyint') as [ProductID],
        [Table].[Column].value('./@turnover', 'money') as [Turnover],
        [Table].[Column].value('./@outstanding', 'money') as [Outstanding],
        [Table].[Column].value('./@winloss', 'money') as [Winlost],
        [Table].[Column].value('./@drawgame', 'money') as [DrawGame],    
        [Table].[Column].value('./@betcount', 'int') as [betcount],
        [Table].[Column].value('./@playercomm', 'money') as [PlayerComm]
    FROM @XmlData.nodes('/root/trans') as [Table]([Column]);

DELETE MemberDaily
WHERE WinlostDate = @WinlostDate

INSERT INTO MemberDaily 
            ([UserName]
           ,[WinlostDate]
           ,[ProductID]           
           ,[Turnover]
           ,[Outstanding]
           ,[Winlost]
           ,[DrawGame]
           ,[AffId]
           ,[IBCCustId]
           ,[Currency]
           ,[AffCurrency]
           ,[AffExRate]
           ,[SysCurrency]
           ,[SysExRate]
           ,[Deposit]
           ,[Withdrawal]
           ,[Bonus]
           ,[Adjustment]           
           ,[BetCount]
           ,[PlayerComm]
           )     
SELECT t1.UserName, t1.WinlostDate, p.ProductID, t1.Turnover, t1.Outstanding, t1.Winlost, t1.DrawGame
    , mi.AffId
    , mi.IBCCustId
    , mi.Currency
    , ai.Currency
    , dbo.Aff_GetExchangeRate(mi.Currency, ai.Currency, @WinlostDate) as AffExRate
    , @SystemCurrency
    , dbo.Aff_GetExchangeRate(mi.Currency, @SystemCurrency, @WinlostDate) as SystemExRate
    ,0 as Deposit
    ,0 as Withdrawal
    ,0 as Bonus
    ,0 as Adjustment    
    ,t1.BetCount
    ,t1.PlayerComm
FROM @TempTrans AS t1
    INNER JOIN MemberInfo AS mi ON t1.UserName = mi.UserName
    inner join affinfo as ai with (nolock) on mi.AffId = ai.AffId
    -- inner join Exchange as ex with (nolock) on ai.Currency = ex.ExchangeId
    inner join Product as p with (nolock) on t1.ProductID = p.API_ProductId
where t1.WinlostDate=@WinlostDate and mi.IsRemoved = 0

END
GO
/****** Object:  StoredProcedure [dbo].[Aff_EarningSelDetail]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_EarningSelDetail    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE PROCEDURE [dbo].[Aff_EarningSelDetail]
    @AffId int = 0,
    @ProductID tinyint = 0,
    @MonthDate smalldatetime,
    @AffCurrency varchar(8) = 'UUS' OUTPUT
AS
/*
    Created: 200900911@VinhTrinh
    Task : [description of SP]  
    DB: DB052.Affiliate_ZZun
    Revisions:          
          - addition Prefix info
    Param's Explanation:  
    • @AffId affliate Id  
    • @MonthDate Month date need to view.  
*/  
SET NOCOUNT ON

select @MonthDate = dateadd(d, datediff(d, 0, @MonthDate), 0)

-- Exec Aff_GetPrefixByAff @AffId = @AffId, @Prefix = @Prefix OUTPUT

select @AffCurrency=e.CurrencyCode
from AffInfo ai (nolock)
    inner join Currency e (nolock) on e.CurrencyID=ai.Currency
where ai.AffID=@AffID



SELECT 
        m.UserName,        
        isnull(Sum(d.Winlost * AffExRate), 0) as winlost,
        isnull(Sum(d.Deposit * AffExRate), 0) as Deposit,
        isnull(Sum(d.Withdrawal * AffExRate), 0) as Withdrawal,
        isnull(Sum(d.Bonus * AffExRate), 0) as Bonus,
        isnull(Sum(d.Turnover * AffExRate), 0) as Turnover,
        isnull(Sum(d.Adjustment * AffExRate), 0) as Adjustment,
        isnull(Sum(d.PSP * AffExRate), 0) as PSP
    FROM MemberDaily d with(nolock)
        inner join MemberInfo m with (nolock) on m.UserName = d.UserName
    WHERE d.AffID = @AffID        
        AND d.winlostdate = @MonthDate
        and (case when @ProductID = 0 then 1 when @ProductID = ProductID then 1 else 0 end) = 1        
    GROUP BY  m.UserName
GO
/****** Object:  StoredProcedure [dbo].[Aff_PlayersSelDetail]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PlayersSelDetail    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_PlayersSelDetail]
    @AffID int,
    @ProductID tinyint = 0,
    @MonthDate datetime = null,
    @PageSize int=200,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
    Created: @VietHoang
    Task : 
    DB: DB052.Affiliate_MYM    
    Revisions:        
        - 20100511@Johnny: upgrade performance(paging first and then calculate member related)
    Param's Explanation:
        • @AffID : Affiliate custid
        • @MonthDate: Month search. If Month is null => get all month Else get just the specification month        
        ----Continue....
*/
SET NOCOUNT ON
DECLARE  @Today datetime,@fdate datetime, @tdate datetime
SELECT @Today = convert(varchar(10),current_timestamp,120)



IF @MonthDate is not NULL
BEGIN
    SELECT @fdate = dbo.Aff_GetFirstDayOfMonth(@MonthDate)
    select @tdate = dbo.Aff_GetLastDayOfMonth(@MonthDate)
END


Create table #ListCustId(TheCount int IDENTITY(1,1),username varchar(100),TurnOver money,winlost money,deposit money,withdrawal money,bonus money,adjustment money,psp money,AffCurrency varchar(8),Description varchar(100))

insert into #ListCustId(username,TurnOver,winlost,deposit,withdrawal,bonus,adjustment,psp,AffCurrency,Description)


select  m.username, 
        isnull(sum(d.turnover * d.AffExRate), 0) as turnover, 
        isnull(sum(d.winlost * d.AffExRate), 0) as winlost,
        isnull(sum(d.deposit  * d.AffExRate), 0) as deposit,
        isnull(sum(d.withdrawal  * d.AffExRate), 0) as withdrawal,
        isnull(sum(d.bonus * d.AffExRate), 0) as bonus, 
        isnull(sum(d.Adjustment * d.AffExRate), 0) as Adjustment,
        isnull(sum(d.PSP  * d.AffExRate), 0) as PSP,
        e.Code as AffCurrency,
        (case when m.IsRemoved=1 then 'Member is removed since ' + 
                                 (select cast(RemovedDate as varchar(50))
                                   from MemberRemoval (nolock) where username=m.username)
        else '' end) as Description
    from MemberDaily d with (nolock)
        inner join MemberInfo m with(nolock) on m.username = d.username
        left join Exchange e on e.ExchangeID = d.AffCurrency
    where m.AffID=@AffID 
    and (@ProductID=0 or d.ProductID= @ProductID)
    and d.AffID = @AffID
    and (turnover > 0 or deposit > 0 or withdrawal>0 or bonus>0 or Adjustment>0 or PSP>0 )
    and (@MonthDate is NULL or d.winlostdate between @fdate and @tdate)    
    group by m.username,e.Code,m.IsRemoved
order by Username    

select @NRows=@@ROWCOUNT


DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   


select * from #ListCustId (nolock) where TheCount between @RowStart and @RowEnd

drop table #ListCustId
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberStatisticsDetail]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberStatisticsDetail    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_MemberStatisticsDetail]
    @AffId [int],
    @Fromdate [datetime],
    @Todate [datetime],
    @IsGetAll [bit]
WITH EXECUTE AS CALLER
AS
Set Nocount On

if @IsGetAll = 1
Begin
    select WinlostDate,
        Sum(Active) as Active,
        Sum(Dormant) as Dormant
    From
        (
        select WinlostDate,
            count(distinct m.IBCCustId) as Active,
            0 as Dormant
        from MemberDaily m with (nolock)
        where AffID = @AffId
            and deposit <> 0 and turnover > 0
        group by WinlostDate

        Union All

        select WinlostDate,
            0,
            count(distinct m.IBCCustId) as Dormant
        from MemberDaily m with (nolock)
        where deposit <> 0 and turnover = 0
        group by WinlostDate
        ) tmp
    Group by WinlostDate
End
Else
Begin
    
    select WinlostDate,
        Sum(Active) as Active,
        Sum(Dormant) as Dormant
    From
        (
        select WinlostDate,
            count(distinct m.IBCCustId) as Active,
            0 as Dormant
        from MemberDaily m with (nolock)
        where AffID = @AffId
            and deposit <> 0 and turnover > 0
            and WinlostDate Between @Fromdate and @Todate
        group by WinlostDate

        Union All

        select WinlostDate,
            0,
            count(distinct m.IBCCustId) as Dormant
        from MemberDaily m with (nolock)
        where AffID = @AffId
            and deposit <> 0 and turnover = 0
            and WinlostDate Between @Fromdate and @Todate
        group by WinlostDate
        ) tmp
    Group by WinlostDate

End
GO
/****** Object:  StoredProcedure [dbo].[Aff_WriteLog]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_WriteLog    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_WriteLog]
    @Creator int,
    @AffID int =0,
    @Typename varchar(50),    
    @RefNo bigint = null OUTPUT,
    @SPName varchar(50),
    @IP varchar(20) =NULL,
    @Details nvarchar(4000)
AS
/*
Created: 20090714@VietHoang
Task : Write Log for affiliate
DB: DB052.Affiliate_MYM
Original:

Revisions:
*/
SET NOCOUNT ON
begin transaction
 begin try
    if(@RefNo is null or @RefNo=0) 
    begin    
        UPDATE Ref with (Rowlock, Updlock)
        SET  @RefNo=refno=refno+1  
        WHERE RefName = 'Log'   
    end

    INSERT INTO dbo.UserLog (RefNo, TypeID, Creator, AffID, LoggedDate, SPName, IP, Details)
    VALUES (@RefNo,dbo.Aff_GetLogType(@Typename) , @Creator, @AffID, CURRENT_TIMESTAMP, @SPName, @IP, @Details)    
     end try
     begin catch
            rollback transaction
            return
      end catch 
commit transaction
GO
/****** Object:  StoredProcedure [dbo].[Aff_ClickStatisticsSelBySite]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ClickStatisticsSelBySite    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ClickStatisticsSelBySite]    
    @AffID int,    
    @FromDate smalldatetime,  
    @ToDate smalldatetime,  
    @TotalClicks int = 0 output,  
    @UniqueClicks int = 0 output  
AS    
/*    
Created: 20111005@Johnny    
Task :   Report click statistics by Referrer site  
DB: DB052.Affiliate_12BET    
Original:    
    
Revisions:    
-   
*/    
  
SET NOCOUNT ON    
  
Declare @LastDateSum smalldatetime  
if(@FromDate > @ToDate)  
    return  
  
Declare @Result as table(DomainReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)  
  
select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)  
  
select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))  
    , @FromDate = convert(varchar(10), @FromDate,120)  
  
if (@LastDateSum < @FromDate)--get from main table  
Begin  
insert into @Result  
select DomainReferrer,  
    sum(TotalClick) as TotalClick,  
    sum(UniqueClick) as UniqueClick,  
    sum(Signups) as Signups,  
    sum(FDM) as FDM  
from   
    (  
    Select   
        DomainReferrer,  
        sum(ClickCount) as TotalClick,  
        count(distinct IP) as UniqueClick,  
        SUM(isnull(Signups, 0)) as Signups,
        SUM(isnull(FDM, 0)) as  FDM 
    from ClickStatistics c with(nolock)   
        left join 
            (Select ClickId, 
                SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
            from MemberInfo m with (nolock) 
            where AffId = @AffID
            group by ClickId
            ) as m on c.ClickId = m.ClickId
    where [Date] between @FromDate and @ToDate  
        and c.AffId = @AffID  
    group by DomainReferrer, [Date]  
    ) as t  
group by DomainReferrer  
End  
else if (@LastDateSum > @ToDate)--get from summary table  
Begin  
insert into @Result  
Select   
    DomainReferrer,  
    sum(TotalClick) as TotalClick,  
    sum(UniqueClick) as UniqueClick,  
    sum(TotalSignup) as Signups,  
    sum(TotalDeposit) as FDM  
from ClickStatisticsSum with(nolock)   
where [Date] between @FromDate and @ToDate  
    and AffId = @AffID  
group by DomainReferrer  
End  
else--@fromdate < @LastDateSum < @ToDate  
Begin  
insert into @Result  
select DomainReferrer,  
    sum(TotalClick) as TotalClick,  
    sum(UniqueClick) as UniqueClick,  
    sum(Signups) as Signups,  
    sum(FDM) as FDM  
from   
    (  
    Select   
        DomainReferrer,  
        sum(TotalClick) as TotalClick,  
        sum(UniqueClick) as UniqueClick,  
        sum(TotalSignup) as Signups,  
        sum(TotalDeposit) as FDM  
    from ClickStatisticsSum with(nolock)   
    where [Date] between @FromDate and @LastDateSum  
        and AffId = @AffID  
    group by DomainReferrer  
  
    Union All  
  
    Select   
        DomainReferrer,  
        sum(ClickCount) as TotalClick,  
        count(distinct IP) as UniqueClick,  
        SUM(isnull(Signups, 0)) as Signups,
        SUM(isnull(FDM, 0)) as  FDM 
    from ClickStatistics c with(nolock)   
            left join 
            (Select ClickId, 
                SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
            from MemberInfo m with (nolock) 
            where AffId = @AffID
            group by ClickId
            ) as m on c.ClickId = m.ClickId
    where [Date] between @LastDateSum and @ToDate  
        and c.AffId = @AffID  
    group by DomainReferrer, [Date]  
    ) tmp  
group by DomainReferrer  
  
End  
  
Select * from @Result  
  
select @TotalClicks = SUM(TotalClick)  
    , @UniqueClicks = SUM(UniqueClick)  
from @Result
GO
/****** Object:  StoredProcedure [dbo].[Aff_ClickStatisticsSelByPage]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ClickStatisticsSelByPage    Script Date: 7/29/2013 1:41:20 AM ******/
CREATE Procedure [dbo].[Aff_ClickStatisticsSelByPage]  
    @AffID int,  
    @FromDate smalldatetime,
    @ToDate smalldatetime,
    @SportCode varchar(50) = null,
    @LanguageCode varchar(10) = null
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
- 
*/  

SET NOCOUNT ON  

Declare @LastDateSum smalldatetime
if(@FromDate > @ToDate)
    return

Declare @Result as table(SportCode varchar(50), LanguageCode varchar(10), TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)

select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))
        , @FromDate = convert(varchar(10), @FromDate,120)

if (@LastDateSum < @FromDate)--get from main table
Begin
    insert into @Result
    Select 
        SportCode,
        LanguageCode,
        sum(TotalClick) as TotalClick,
        Sum(UniqueClick) as UniqueClick,
        SUM(Signups) as Signups,
        SUM(FDM) as  FDM
    From(
        Select 
            SportCode,
            LanguageCode,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
            SUM(isnull(FDM, 0)) as  FDM
        from ClickStatistics c with(nolock) 
            left join 
                (Select ClickId, 
                    SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                    SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
                from MemberInfo m with (nolock) 
                where AffId = @AffID
                group by ClickId
                ) as m on c.ClickId = m.ClickId
        where [Date] between @FromDate and @ToDate
            and c.AffId = @AffID
            and SportCode = ISNULL(@SportCode, SportCode)
            and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
        group by SportCode, LanguageCode, [Date]--[Date] in condition to calculate unique click
        ) as tmp
    group by SportCode, LanguageCode
    order by SportCode, LanguageCode
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
    insert into @Result
    Select 
        SportCode,
        LanguageCode,
        sum(TotalClick) as TotalClick,
        sum(UniqueClick) as UniqueClick,
        sum(TotalSignup) as Signups,
        sum(TotalDeposit) as FDM
    from ClickStatisticsSum with(nolock) 
    where [Date] between @FromDate and @ToDate
            and AffId = @AffID
            and SportCode = ISNULL(@SportCode, SportCode)
            and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
    group by SportCode, LanguageCode
    order by SportCode, LanguageCode
End
else--@fromdate < @LastDateSum < @ToDate
Begin
    insert into @Result
    select SportCode,
            LanguageCode,
            sum(TotalClick) as TotalClick,
            sum(UniqueClick) as UniqueClick,
            sum(Signups) as Signups,
            sum(FDM) as FDM
    from 
        (
        Select 
            SportCode,
            LanguageCode,
            sum(TotalClick) as TotalClick,
            sum(UniqueClick) as UniqueClick,
            sum(TotalSignup) as Signups,
            sum(TotalDeposit) as FDM
        from ClickStatisticsSum with(nolock) 
        where [Date] between @FromDate and @LastDateSum
            and AffId = @AffID
            and SportCode = ISNULL(@SportCode, SportCode)
            and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
        group by SportCode, LanguageCode

        Union All

        Select 
            SportCode,
            LanguageCode,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
        SUM(isnull(FDM, 0)) as  FDM
        from ClickStatistics c with(nolock) 
            left join 
                (Select ClickId, 
                    SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                    SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
                from MemberInfo m with (nolock) 
                where AffId = @AffID
                group by ClickId
                ) as m on c.ClickId = m.ClickId
        where [Date] between @LastDateSum and @ToDate
            and c.AffId = @AffID
            and SportCode = ISNULL(@SportCode, SportCode)
            and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
        group by SportCode, LanguageCode, [Date]
        ) tmp
    group by SportCode, LanguageCode
    order by SportCode, LanguageCode

End

Select * from @Result
GO
/****** Object:  StoredProcedure [dbo].[Aff_ClickStatisticsDetailBySite]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ClickStatisticsDetailBySite    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_ClickStatisticsDetailBySite]  
    @AffID int,  
    @Domain nvarchar(300) = null,
    @SportCode varchar(50) = null,
    @LanguageCode varchar(10) = null,
    @FromDate smalldatetime,
    @ToDate smalldatetime,
    @PageSize int=50,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
- 
*/  

SET NOCOUNT ON  

Declare @LastDateSum smalldatetime
if(@FromDate > @ToDate)
    return

Declare @Result as table(UrlReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)
        , @FromDate = convert(varchar(10), @FromDate,120)

select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))

if (@LastDateSum < @FromDate)--get from main table
Begin
    insert into @Result
    select URLReferrer,
            sum(TotalClick) as TotalClick,
            sum(UniqueClick) as UniqueClick,
            sum(Signups) as Signups,
            sum(FDM) as FDM
    from 
        (
        Select 
            URLReferrer,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
            SUM(isnull(FDM, 0)) as  FDM
        from ClickStatistics c with(nolock) 
            left join 
                (Select ClickId, 
                    SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                    SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
                from MemberInfo m with (nolock) 
                where AffId = @AffID
                group by ClickId
                ) as m on c.ClickId = m.ClickId
        where [Date] between @FromDate and @ToDate
            and c.AffId = @AffID
            and DomainReferrer = isnull(@Domain, DomainReferrer)
            and SportCode = isnull(@SportCode, SportCode)
            and LanguageCode = isnull(@LanguageCode, LanguageCode)
        group by URLReferrer, [Date]
        ) as t
    group by URLReferrer
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
    insert into @Result
    select URLReferrer,
            sum(TotalClick) as TotalClick,
            sum(UniqueClick) as UniqueClick,
            sum(Signups) as Signups,
            sum(FDM) as FDM
    from 
        (
        Select 
            URLReferrer,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
            SUM(isnull(FDM, 0)) as  FDM
        from ClickStatistics_bk c with(nolock) 
            left join 
                (Select ClickId, 
                    SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                    SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
                from MemberInfo m with (nolock) 
                where AffId = @AffID
                group by ClickId
                ) as m on c.ClickId = m.ClickId
        where [Date] between @FromDate and @ToDate
            and c.AffId = @AffID
            and DomainReferrer = isnull(@Domain, DomainReferrer)
            and SportCode = isnull(@SportCode, SportCode)
            and LanguageCode = isnull(@LanguageCode, LanguageCode)
        group by URLReferrer, [Date]
        ) as t
    group by URLReferrer
End
else--@fromdate < @LastDateSum < @ToDate
Begin
    insert into @Result
    select URLReferrer,
            sum(TotalClick) as TotalClick,
            sum(UniqueClick) as UniqueClick,
            sum(Signups) as Signups,
            sum(FDM) as FDM
    from 
        (
        Select 
            URLReferrer,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
            SUM(isnull(FDM, 0)) as  FDM
        from ClickStatistics_bk c with(nolock) 
            left join 
                (Select ClickId, 
                    SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                    SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
                from MemberInfo m with (nolock) 
                where AffId = @AffID
                group by ClickId
                ) as m on c.ClickId = m.ClickId
        where [Date] between @FromDate and @LastDateSum
            and c.AffId = @AffID
            and DomainReferrer = isnull(@Domain, DomainReferrer)
            and SportCode = isnull(@SportCode, SportCode)
            and LanguageCode = isnull(@LanguageCode, LanguageCode)
        group by URLReferrer, [Date]

        Union All

        Select 
            URLReferrer,
            sum(ClickCount) as TotalClick,
            count(distinct IP) as UniqueClick,
            SUM(isnull(Signups, 0)) as Signups,
            SUM(isnull(FDM, 0)) as  FDM
        from ClickStatistics c with(nolock) 
            left join 
                (Select ClickId, 
                    SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
                    SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
                from MemberInfo m with (nolock) 
                where AffId = @AffID
                group by ClickId
                ) as m on c.ClickId = m.ClickId
        where [Date] between @LastDateSum and @ToDate
            and c.AffId = @AffID
            and DomainReferrer = isnull(@Domain, DomainReferrer)
            and SportCode = isnull(@SportCode, SportCode)
            and LanguageCode = isnull(@LanguageCode, LanguageCode)
        group by URLReferrer, [Date]
        ) tmp
    group by URLReferrer

End

--Select * from @Result

--count nrows
select @NRows=count(1)
FROM @Result

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT     *
FROM(       
    SELECT TOP(@RowEnd) 
            ROW_NUMBER() OVER(ORDER BY URLReferrer) AS TheCount,
            *
    FROM @Result
       ) x
 where x.TheCount between @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_CalMonthlyEarningCurrent]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CalMonthlyEarningCurrent    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_CalMonthlyEarningCurrent] (
@AffID int,
@ProductID int =0,
@Amount money OUTPUT)
AS
/*
    Task : Calculate monthy earning for affiliate current month
    DB: DB052.Affiliate_MYM
    Author : Peter@20090909
    -20100709@Peter:
                    http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&st=0&sk=t&sd=a&start=10
                    Change the way to calculation:

                    if CNW <0 then we must also use the condition of Qualifying Members ( old way does not have)
                     and the minimum commission in this case is 10%  if the qualifying members <5.
     -20100927@Peter:
                 http://ccs.sunplus.vn/viewtopic.php?f=4&t=3845&p=19236#p19236  
                 Change the way to calculation:
                   PSP=deposit * depositpercent + withdrawal * withdrawalpercent
                      For European Currencies: EURO,AUD,GBP, US$
                          + depositpercent=0.06
                          + withdrawalpercent=0.03
                      For Asian Currencies:
                          + depositpercent=0.02
                          + withdrawalpercent=0.02
                   PSP now follow tier commission
                   New Fee:  Odds Management Fee = 17 % MemberWinlost
                   CNW= MemberWinlost - Odds Management Fee - Marketing Fee - PSP Fee
                   From CNW => AComm
                   Affiliate Earning=(CNW - Bonus - Adjustement)* AComm                 
    - 20101228@Henry: change bettype to new range
*/
BEGIN    
  
 SET NOCOUNT ON
 Declare @FirstDay smalldatetime,@LastDay smalldatetime,@Today smalldatetime, @MinimumNegativeCommission float
        
select @MinimumNegativeCommission = 0.1


Select @FirstDay = cast(cast(year(getdate()) as varchar(5)) + '-' + cast(Month(getdate()) as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @Today = convert (varchar(12),current_timestamp)
select @LastDay=@Today

Declare @AffSummary Table
(
    ProductID int,
    MemWinlost money,
    MemBonus money,    
    MemPSP money,    
    MemTurnover money,
    Commission decimal(9,8),
    TotalQM int,  
    NetWinlost money,
    HasBonus bit,
    HasMarketing bit,   
    HasPSP bit,
    HasOddsFee bit,
    BonusPercent float,
    MarketingPercent float,   
    PSPPercent float,
    OddsFeePercent float
    
)

                      
 Declare @GroupID int
   
  Select @GroupID=GroupID
   from AffInfo (nolock)
   Where AffID=@AffID
   


INSERT INTO @AffSummary(ProductID,MemWinlost,MemBonus,MemPSP,MemTurnover,
          TotalQM,
          HasBonus,
          HasMarketing,         
          HasPSP,
          HasOddsFee,
          BonusPercent,          
          MarketingPercent,
          PSPPercent,
          OddsFeePercent)

Select  r.ProductID as ProductID
       ,sum(isnull(r.Winlost,0)) as MemWinlost
       ,sum(isnull(r.Bonus,0)) as MemBonus       
       ,sum(isnull(r.PSP,0)) as MemPSP       
       ,sum(isnull(r.Turnover,0)) as MemTurnover
       ,sum(case when r.TurnOver>=dbo.[Aff_GetQMTurnOver](@AffID,current_timestamp) then 1 else 0 end) as TotalQM      
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Bonus',null) as HasBonus
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Marketing',null) as HasMarketing
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'PSP',null) as HasPSP
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Odds Fee',null) as HasOddsFee
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Bonus',null) as BonusPercent       
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Marketing',null) as MarketingPercent
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'PSP',null) as PercentPSP
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Odds Fee',null) as OddsFeePercent
FROM  
      (
        select md.username,md.ProductID
               ,sum(isnull(md.Winlost,0) * isnull(md.AffExRate,1)) as Winlost
               ,sum(isnull(md.Bonus,0) * isnull(md.AffExRate,1)) as Bonus               
               ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP
               ,sum(isnull(Marketing,0) * isnull(AffExRate,1)) as Marketing
               ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver               
        from MemberDaily md  (nolock)       
          where AffID=@AffID and WinlostDate between @FirstDay and @LastDay 
                and (@ProductID=0 or md.ProductID=@ProductID)   
        group by  md.username,ProductID
        

      ) r 
      --left join Product s (nolock) on s.ProductID=r.ProductID 
group by r.ProductID
 


--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID

update a
set   a.NetWinlost=(-isnull(a.MemWinlost,0) 
                  - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
                ),
      a.commission=isnull((select  top(1) Commission
                          from 
                            (
                                select isnull((select Commission
                                              from GroupSetting(nolock)
                                              where GroupID=@GroupID 
                                                    and ProductID=a.ProductID                                                    
                                                    and floor(
                                                              abs(
                                                                -isnull(a.MemWinlost,0) 
                                                                 - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                                                                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                                                                 -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
                                                                )
                                                            ) 
                                                        between MinAmount and MaxAmount),0) as Commission
                                union all                             
                                  select isnull((select top(1) Commission 
                                                      from GroupSetting(nolock)
                                                      where GroupID=@GroupID
                                                            and ProductID=a.ProductID                                                             
                                                            and a.TotalQM between MinQM and MaxQM
                                                   ),0)
                                           as Commission
                            ) t  
                            order by t.Commission asc
                    ),0)
from @AffSummary a

if @GroupID not in (select groupId from CommGroup with (nolock) where GroupName='NoCommission')
begin
update a
set a.Commission = @MinimumNegativeCommission
from @AffSummary a
where a.NetWinlost < 0 and a.Commission = 0     
      and a.ProductID in (
        select distinct ProductID from GroupSetting (nolock) where GroupID=@GroupID    
      )   
end     

select @Amount=sum((a.NetWinlost- Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1) )*isnull(a.Commission,0))
from  @AffSummary a

--Select * from  @AffSummary 
   
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_CalMonthlyEarning]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CalMonthlyEarning    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_CalMonthlyEarning] (
@AffID int,
@Month int,
@Year int,
@ProductID int =0,
@Amount money OUTPUT)
AS
/*
    Task : Calculate monthy earning for affiliate
    Author : Peter@20090909
    -20100709@Peter:
                    http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&st=0&sk=t&sd=a&start=10
                    Change the way to calculation:

                    if CNW <0 then we must also use the condition of Qualifying Members ( old way does not have)
                     and the minimum commission in this case is 10%  if the qualifying members <5. 
    -20100927@Peter:
                 http://ccs.sunplus.vn/viewtopic.php?f=4&t=3845&p=19236#p19236  
                 Change the way to calculation:
                   PSP=deposit * depositpercent + withdrawal * withdrawalpercent
                      For European Currencies: EURO,AUD,GBP, US$
                          + depositpercent=0.06
                          + withdrawalpercent=0.03
                      For Asian Currencies:
                          + depositpercent=0.02
                          + withdrawalpercent=0.02
                   PSP now follow tier commission
                   New Fee:  Odds Management Fee = 17 % MemberWinlost
                   CNW= MemberWinlost - Odds Management Fee - Marketing Fee - PSP Fee
                   From CNW => AComm
                   Affiliate Earning=(CNW - Bonus - Adjustement)* AComm
                                
    
*/
BEGIN    
  
 SET NOCOUNT ON

Declare @FirstDay smalldatetime,@LastDay smalldatetime, @MinimumNegativeCommission float

select @MinimumNegativeCommission = 0.1

Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
--Get last day of inputted month
Select @LastDay = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,@FirstDay)+1,0))

 Declare @GroupID int
   
  Select @GroupID=GroupID
   from AffGroupHistory (nolock)
   Where AffID=@AffID and MonthDate=@LastDay
   

Declare @AffSummary Table
(
    ProductID int,
    MemWinlost money,
    MemBonus money,    
    MemPSP money,    
    MemTurnover money,
    Commission decimal(9,8),
    TotalQM int,  
    NetWinlost money,
    HasBonus bit,
    HasMarketing bit,   
    HasPSP bit,
    HasOddsFee bit,
    BonusPercent float,
    MarketingPercent float,   
    PSPPercent float,
    OddsFeePercent float
    
)


INSERT INTO @AffSummary(ProductID,MemWinlost,MemBonus,MemPSP,MemTurnover,
          TotalQM,
          HasBonus,
          HasMarketing,         
          HasPSP,
          HasOddsFee,
          BonusPercent,          
          MarketingPercent,
          PSPPercent,
          OddsFeePercent)


Select  r.ProductID as ProductID
       ,sum(isnull(r.Winlost,0)) as MemWinlost
       ,sum(isnull(r.Bonus,0)) as MemBonus       
       ,sum(isnull(r.PSP,0)) as MemPSP       
       ,sum(isnull(r.Turnover,0)) as MemTurnover
       ,sum(case when r.TurnOver>=dbo.[Aff_GetQMTurnOver](@AffID,current_timestamp) then 1 else 0 end) as TotalQM      
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Bonus',@LastDay) as HasBonus
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Marketing',@LastDay) as HasMarketing
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'PSP',@LastDay) as HasPSP
       ,dbo.Aff_HasDeduction(@GroupID,r.ProductID,'Odds Fee',@LastDay) as HasOddsFee
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Bonus',@LastDay) as BonusPercent       
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Marketing',@LastDay) as MarketingPercent
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'PSP',@LastDay) as PercentPSP
       ,dbo.Aff_GetDeductionPercent(@AffID,r.ProductID,'Odds Fee',@LastDay) as OddsFeePercent
FROM  
      (
        select md.username,md.ProductID
               ,sum(isnull(md.Winlost,0) * isnull(md.AffExRate,1)) as Winlost
               ,sum(isnull(md.Bonus,0) * isnull(md.AffExRate,1)) as Bonus               
               ,sum(isnull(PSP,0) * isnull(AffExRate,1)) as PSP
               ,sum(isnull(Marketing,0) * isnull(AffExRate,1)) as Marketing
               ,sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as TurnOver               
        from MemberDaily md  (nolock)       
          where AffID=@AffID and WinlostDate between @FirstDay and @LastDay 
                and (@ProductID=0 or md.ProductID=@ProductID)   
        group by  md.username,ProductID
        

      ) r 
      --left join Product s (nolock) on s.ProductID=r.ProductID 
group by r.ProductID
  


--Choose commission value and calculate Total Balance after deduction for each Affiliate and ProductID

update a
set  a.NetWinlost=(-isnull(a.MemWinlost,0) 
                 - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                 -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1) 
                ),
                
     a.commission=isnull((select  top(1) Commission
                          from 
                            (
                                select isnull((select Commission
                                              from GroupSettingHistory(nolock)
                                              where GroupID=@GroupID
                                                    and ProductID=a.ProductID
                                                    and MonthDate=@LastDay
                                                    and floor(
                                                              abs(
                                                                    -isnull(a.MemWinlost,0) 
                                                                    - Cast(a.HasPSP as int)* isnull(a.MemPSP,0)*isnull(a.PSPPercent,1)
                                                                    -Cast(a.HasOddsFee as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.OddsFeePercent,1) 
                                                                     -Cast(a.HasMarketing as int) *  abs(isnull(a.MemWinlost,0)) * isnull(a.MarketingPercent,1)
                                                                )
                                                            ) 
                                                        between MinAmount and MaxAmount),0) as Commission
                                union all                             
                                  select  isnull((select top(1) Commission 
                                                      from GroupSettingHistory(nolock)
                                                      where GroupID=@GroupID 
                                                            and ProductID=a.ProductID 
                                                            and MonthDate=@LastDay
                                                            and a.TotalQM between MinQM and MaxQM
                                                   ),0)
                                          as Commission
                            ) t  
                            order by t.Commission asc
                    ),0)

from @AffSummary a

update a
set a.Commission = @MinimumNegativeCommission
from @AffSummary a
where a.NetWinlost < 0 and a.Commission = 0    
      and @GroupID not in (select groupId from CommGroup with (nolock) where GroupName='NoCommission')
       and a.ProductID in (
        select distinct ProductID from GroupSettingHistory (nolock) where GroupID=@GroupID     and DATEDIFF(m,MonthDate,@LastDay)=0
      )   


select @Amount=sum((a.NetWinlost- Cast(a.HasBonus as int)* isnull(a.MemBonus,0)*isnull(a.BonusPercent,1))*isnull(a.Commission,0))
from  @AffSummary a

--Select * from  @AffSummary 
 
   
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelLog]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelLog    Script Date: 7/29/2013 1:41:21 AM ******/
/****** Object:  Stored Procedure dbo.Aff_AffiliateSelLog    Script Date: 5/15/2010 6:06:49 AM ******/

CREATE Procedure [dbo].[Aff_AffiliateSelLog]
    @AffID INT = NULL, 
    @LogType INT = NULL,
    @DateFrom DATETIME = '2000-01-01',
    @DateTo DATETIME = '2020-01-01',
    @PageIndex INT =1,
    @PageSize INT = 20,
    @PageCount INT = 0 OUTPUT,
    @RowCount INT = 0 OUTPUT
AS
/*
    Created: 20100423@Jacob
    Task : Get all log type
    DB: DB052.Affiliate_MYM
    Revisions:
        - 20100423@Jacob initialize
        
    Param's Explanation:

*/
SET NOCOUNT ON;

select @DateFrom=convert(varchar(10),@DateFrom,120)
select @DateTo=dateadd(s,-1,dateadd(d,1,@DateTo)) 

IF (@PageSize<=0) SET @PageSize = 20;


WITH UserLogs AS
(
    SELECT TOP(@PageIndex*@PageSize) ROW_NUMBER() OVER (ORDER BY [RefNo] desc, [LoggedDate] DESC) AS Row
           , L.[RefNo]
          ,L.[TypeID]
          ,L.[AffID]
          ,C.[UserName]
          ,L.[Creator]
          ,L.[LoggedDate]
          ,L.[SPName]
          ,L.[Details]
          ,L.[IP]
          ,T.[TypeName]
          ,T.[Description]    
           FROM [dbo].[UserLog] L WITH(NOLOCK) 
                INNER JOIN [dbo].[AffInfo]AS C WITH(NOLOCK) ON C.AffID = L.[AffID]
                INNER JOIN [dbo].[LogType] T WITH(NOLOCK) 
                    ON (T.[TypeID]=L.[TypeID] AND (ISNULL(@LogType,0) = 0 OR T.[TypeID] = ISNULL(@LogType,0)))
           WHERE L.[AffID]=ISNULL(@AffID,0)           
                AND L.[LoggedDate] BETWEEN ISNULL(@DateFrom,'2000-01-01') AND ISNULL(@DateTo,GETDATE())    
)

SELECT   [Row]
          , [RefNo]
          ,[TypeID]
          ,[AffID]
          ,[UserName]
          ,[Creator]
          ,[LoggedDate]
          ,[SPName]
          ,[Details]
          ,[IP]
          ,[TypeName]
          ,[Description]    
FROM UserLogs
WHERE  Row BETWEEN (@PageIndex-1)*@PageSize + 1 AND @PageIndex*@PageSize

SELECT @RowCount=COUNT(L.[RefNo])
FROM [dbo].[UserLog] L WITH(NOLOCK)
WHERE (ISNULL(@LogType,0) = 0 OR L.[TypeID] = ISNULL(@LogType,0))
    AND L.[AffID]=ISNULL(@AffID,0)           
    AND L.[LoggedDate] BETWEEN ISNULL(@DateFrom,'2000-01-01') AND ISNULL(@DateTo,GETDATE())            
            
IF (@RowCount % @PageSize = 0) SET @PageCount = (@RowCount / @PageSize);
ELSE SET @PageCount = (@RowCount / @PageSize) + 1;
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateStatisticsDetail]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateStatisticsDetail    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateStatisticsDetail]
    @AffId int,
    @Fromdate datetime,
    @Todate datetime,
    @IsGetAll bit,
    @PageSize int=50,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get statistics report detail for affiliate.
DB: DB052.Affiliate_ZZun
Original: [Aff_AffiliateStatisticsDetail]
Revisions:
    
Param's Explanation:
    • @AffId Affiliate Id
    • @Fromdate Time search From
    • @Todate Time search To,
    • @IsGetAll if getall = 1 => get data in all date of Affiliate,
*/
Set Nocount On    
--Get all date from all related tables
Create table #Temp (Date smalldatetime)

if @IsGetAll = 1
BEGIN
    --From RegisteredDate Column
    insert into #Temp(Date)
    Select dateadd(d, 0, datediff(d, 0, RegisteredDate)) 
    from MemberInfo (nolock)
    where AffID=@AffID and IsRemoved=0
    group by dateadd(d, 0, datediff(d, 0, RegisteredDate))

    insert into #Temp(Date)
    Select dateadd(d, 0, datediff(d, 0, CreatedDate)) 
    from MemberInfo (nolock)
    where AffID=@AffID  and IsRemoved=0
        and CreatedDate is not null and dateadd(d, 0, datediff(d, 0, CreatedDate)) not in (Select Date from #Temp with (nolock))
    group by dateadd(d, 0, datediff(d, 0, CreatedDate))

    insert into #Temp(Date)
    Select distinct winlostdate    
    From  MemberDaily md with(nolock) 
                inner join MemberInfo mi with (nolock) on mi.username=md.username                 
            where Turnover > 0 and IsRemoved=0 and mi.AffID=@AffID        
            and winlostdate not in (Select Date from #Temp with (nolock))
END
ELSE
BEGIN
    Select @Fromdate = dateadd(d, datediff(d, 0, @Fromdate), 0)
    Select @ToDate = dateadd(s, -1, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))
    insert into #Temp(Date)
    Select dateadd(d, 0, datediff(d, 0, RegisteredDate)) 
    from MemberInfo (nolock)
    where AffID=@AffID and username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)    
            and RegisteredDate between @FromDate and @ToDate    
    group by dateadd(d, 0, datediff(d, 0, RegisteredDate))

    insert into #Temp(Date)
    Select dateadd(d, 0, datediff(d, 0, CreatedDate)) 
    from MemberInfo (nolock)
    where AffID=@AffID  and username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)    
    and CreatedDate is not null and dateadd(d, 0, datediff(d, 0, CreatedDate)) not in (Select Date from #Temp with (nolock))
          and CreatedDate between @FromDate and @ToDate
    group by dateadd(d, 0, datediff(d, 0, CreatedDate))
    
    insert into #Temp(Date)
    Select distinct winlostdate    
            From  MemberDaily md with(nolock) 
                inner join MemberInfo mi with (nolock) on mi.username=md.username                 
            where Turnover > 0 and mi.AffID=@AffID and md.WinlostDate between @FromDate and @ToDate
                    --and mi.CreatedDate between @FromDate and @ToDate
                    and mi.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)    
                  and winlostdate not in (Select Date from #Temp with (nolock))

END

select @NRows=count(1)    
FROM  #Temp with (nolock)  

if(isnull(@NRows,0)=0)    
    return  

DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
        
DECLARE @TempAff TABLE(date smalldatetime, Active int, Dormant int,Total int , TotalRegistered int)

insert into @TempAff(date)
select date
from  
    (select ROW_NUMBER() OVER(ORDER BY date) AS TheCount,  
        date
    from #Temp with (nolock)            
    )m 
where m.TheCount between @RowStart and @RowEnd   

drop table #Temp

update t
    set t.Total=isnull(a.Total,0),
        t.TotalRegistered=isnull(a.TotalRegistered,0),
        t.Active=isnull(b.Active,0),
        t.Dormant=isnull(a.Total,0)-isnull(b.Active,0)
    from  @TempAff t    
    left join      
    (
        SELECT r.Date,
            sum(case when datediff(d,r.date,d.registeredDate)=0 then 1 else 0 end ) as TotalRegistered,
            sum(case when CreatedDate is not null and datediff(d,r.date,d.CreatedDate)=0 then 1 else 0 end) as Total        
        FROM @TempAff r
            inner join MemberInfo d WITH(NOLOCK) on datediff(d,r.date,d.registeredDate)=0 or datediff(d,r.date,d.CreatedDate)=0
        where d.username not in (Select username from MemberRemoval (nolock) where datediff(d,RemovedDate,r.Date)=0 )    
              and d.AffID=@AffID     
        group by r.Date

    ) a on a.Date = t.Date
   left join
    (
        Select r.date,
            Count(Distinct md.username) as Active        
        From  @TempAff r
            inner join MemberDaily md with(nolock) on md.WinlostDate=r.date
            inner join MemberInfo mi with (nolock) on mi.username=md.username                 
        where Turnover > 0 and
            (
                (md.WinlostDate between @FromDate and @ToDate
                --and mi.CreatedDate between @FromDate and @ToDate
                --and mi.CreatedDate is not null
                --and mi.RegisteredDate between @FromDate and @ToDate    
                ) 
                or @IsGetAll = 1
            )
            and mi.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)    
            and mi.AffID = @AffID
        group by r.date
    )b on b.Date = t.Date

Select * from @TempAff
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateStatistics]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateStatistics    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateStatistics]
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit,
	@UserName nvarchar(50)=NULL,
	@PreferredLanguage varchar(11) = null,
	@Currency smallint = 0,
	@AffType tinyint = 0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get report by date for all affiliate.
DB: DB052.Affiliate_ZZun
Original: [Aff_AffiliateStatistics]
Revisions:
    - Remove un-used column in result table. And 
	- 20130802@Jim: fix bug active member not same  as Total Active Players in Affiliate Info
Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
	• @UserName Affiliate username need to search(must match username),
	• @PageSize Page Size,
	• @PageIndex Current page,
	• @TotalPages num pages return,
	• @NRows num rows return
*/
Set Nocount On

Select @Fromdate=isnull(@Fromdate,current_timestamp),@Todate=isnull(@Todate,current_timestamp)
Select @FromDate = dbo.Date_Only(@FromDate), @ToDate = dbo.Date_Only(@ToDate)
select @UserName= '%' + Coalesce(@UserName, '') + '%'
Select @Fromdate = dateadd(d, datediff(d, 0, @Fromdate), 0)
Select @ToDate = dateadd(s, -60, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))

--count nrows
select @NRows=count(1)    
FROM  AffInfo ai with (nolock)  
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE (@IsGetAll=1 or ai.ApprovedDate <= dbo.Aff_GetEndDate(@ToDate)) 
	and ai.Status='Approved'	
	and ai.Username like @UserName
	and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage)
	and (@Currency=0 or  @Currency=ai.Currency)
	and (@AffType=0 or AffType = @AffType)
	
if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
        
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30), 
		ActiveAll int,FDMAll int,Active int, Dormant int,TotalFDM int , 
		NonDeposit int , TotalRegistered int, AffTypeName varchar(50))

insert into @TempAff(AffID,UserName,AffTypeName)
select m.AffId, m.username,m.AffTypeName
from  
	(select ROW_NUMBER() OVER(ORDER BY ai.AffId) AS TheCount,  
		ai.AffID, ai.UserName, ad.PreferredLanguage,at.Name as AffTypeName
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId		
		left join AffType at with (nolock) on ai.AffType = at.TypeID
	WHERE  (@IsGetAll=1 or ai.ApprovedDate <= dbo.Aff_GetEndDate(@ToDate))			
	and ai.Status='Approved'	
	and ai.Username like @UserName
	and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage)
	and (@Currency=0 or  @Currency=ai.Currency)
	and (@AffType=0 or AffType = @AffType)
	
	)m 
where m.TheCount between @RowStart and @RowEnd      

if @IsGetAll = 1
Begin
	update t
	set t.TotalFDM=isnull(a.Total,0),
		t.TotalRegistered=isnull(a.TotalRegistered,0),
		t.Active=isnull(b.Active,0)
	from  @TempAff t	
	left join  	
	(
		SELECT r.AffID,
			sum(1) as TotalRegistered,
			sum(case when CreatedDate is not null then 1 else 0 end) as Total		
		FROM @TempAff r
			inner join MemberInfo d WITH(NOLOCK) on r.AffId = d.AffId and d.IsRemoved=0		
		Group by r.AffID
	) a on a.AffId = t.AffId
   left join
	(
		Select r.AffId,
			Count(Distinct md.username) as Active			
		From  @TempAff r
			inner join MemberDaily md with(nolock) on md.AffID=r.AffID
		where (Turnover > 0 OR md.Deposit>0)
		Group by r.AffId
	)b on b.AffId = t.AffId
		
End
Else
Begin
	Select @ToDate = dateadd(s, -1, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))

	update t
	set 
		t.TotalFDM=isnull(a.TotalFDM,0),
		t.TotalRegistered=isnull(a.TotalRegistered,0),
		t.Active=isnull(b.Active,0)
	from  @TempAff t	
	left join  	
	(
		SELECT r.AffID,
			sum(case when RegisteredDate between @FromDate and @ToDate then 1 else 0 end ) as TotalRegistered,
			sum(case when CreatedDate is not null and CreatedDate between @FromDate and @ToDate and RegisteredDate between @FromDate and @ToDate then 1 else 0 end) as TotalFDM
		FROM @TempAff r
			inner join MemberInfo d WITH(NOLOCK) on r.AffId = d.AffId
		where d.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
		Group by r.AffID
	) a on a.AffId = t.AffId
	left join
	(
		Select r.AffId,
			Count(Distinct md.username) as Active
		From  @TempAff r
			inner join MemberDaily md with(nolock) on md.AffID=r.AffID
			inner join MemberInfo mi with (nolock) on mi.username=md.username 				
		where (Turnover > 0 OR md.Deposit>0) 
			and md.WinlostDate between @FromDate and @ToDate			
			and mi.username not in (Select username from MemberRemoval (nolock) where RemovedDate between @FromDate and @Todate)	
		Group by r.AffId
	)b on b.AffId = t.AffId
End

Select * from @TempAff 
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateStatementHistorySel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateStatementHistorySel    Script Date: 7/29/2013 1:41:21 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateStatementHistorySel]  
    @AffId int,  
    @PageSize int=50,  
    @PageIndex int=1,  
    @TotalPages int=0 OUTPUT,  
    @NRows int=0 OUTPUT  
AS  
/*Created: 20091225@Peter
Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)
DB: DB052.Affiliate_ZZun
Original: [Aff_AffiliateStatementHistorySel]  
Revisions:      
Param's Explanation:  
• @AffID : Affiliate custid  
• @PageSize : Size of page
• @PageIndex : current page
• @TotalPages : number of pages
• @NRows : number of rows
*/  
SET NOCOUNT ON

declare @AffTrans table(TransId bigint, MonthDate SmallDatetime, TransType int, Amount money, Status varchar(20), Creator nvarchar(50), Description varchar(300))
declare @Month int,
       @Year int,
       @Amount money ,      
       @Currentdate datetime,
       @NetPercentReceived float
       
select @NetPercentReceived=1.0,@CurrentDate=current_timestamp     

exec [dbo].[Aff_CalMonthlyEarningCurrent] 
@AffID =@AffID,
@Amount=@Amount OUTPUT

insert into @AffTrans
select 0 as TransID,current_timestamp as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'Current Month Statistics' as Description              

--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc
if(not exists (select top(1) 1 from AffCommission with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0) and 
  datediff(m,(select ApprovedDate from AffInfo with (nolock) where AffID=@AffID),@CurrentDate) >=1
  and exists (select top(1) 1 from AffDailySummary with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0))
BEGIN
  select @Month=month(dateadd(m,-1,@CurrentDate)),@Year=Year(dateadd(m,-1,@CurrentDate))
  exec [dbo].[Aff_CalMonthlyEarning] 
        @AffID =@AffID,
        @Month=@Month,
        @Year=@Year,
        @Amount=@Amount OUTPUT

  insert into @AffTrans
  select 0 as TransID,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(m,-1,@CurrentDate))+1,0)) as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'UnCalculated Month' as Description    
END

insert into @AffTrans

select TransID, a.TransDate as MonthDate, TransType, (case when transtype=202 then abs(a.Amount) else a.Amount end) as Amount, (case when transtype=203 then 'B/F' else a.Status end) as  Status,

case when a.Status in ('Pending','Cancelled') and a.TransType=202 then ai.UserName
                 when a.TransType=201  then 'System'                  
                  else i.username
            end  as Creator,

 case when TransType = 203 then '' else coalesce(p.AffDesc,a.Description) end as Description
from AffTrans a (nolock)
      inner join AffInfo ai (nolock) on ai.AffID= a.AffID
     left join AffPayout p (nolock) on p.RefID=a.RefID
    left join AdminUser i with (nolock) on i.custid=a.Creator 
where a.AffId = @AffId
    and TransType in (202, 203)--202: Payment request and 203 : adjustment
Union All

Select 0 as TransId, a.MonthDate, 201 as TransType, isnull(a.Amount, 0) + isnull(b.Amount, 0) as Amount, 'B/F', 'System',  a.Description
From
    (select TransDate as MonthDate, Amount,  Description
    from AffTrans a (nolock)
    where AffId = @AffId
        and TransType = 201--201: Monthly Transfer
    )a left join
    
    (select TransDate as MonthDate, Amount
    from AffTrans a (nolock)
    where AffId = @AffId
        and TransType = 204--204 : Marketing fee(deduction 20% per Affiliate Net Winlost)
    ) b on a.MonthDate = b.MonthDate 


select @NRows = Count(*)
From @AffTrans

DECLARE @RowStart int, @RowEnd int    

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 
 
select TransId, MonthDate, TransType, Amount, Status, Creator, Description
from  
    (
        select ROW_NUMBER() OVER(ORDER BY MonthDate desc) AS TheCount, 
            TransId, MonthDate, TransType, Amount, Status, Creator, Description
        from @AffTrans
    )m  
where m.TheCount between @RowStart and @RowEnd  order by monthdate desc
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateRecoverPwd]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateRecoverPwd    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE PROCEDURE [dbo].[Aff_AffiliateRecoverPwd]
	@AffId int,
	@ValidCode varchar(10),
	@NewPwd varchar(40),
	@Email nvarchar(50) = NULL OUTPUT,
	@Username varchar(30)= NULL OUTPUT,
	@Firstname nvarchar(50) = NULL OUTPUT,
	@Lastname nvarchar(50) = NULL OUTPUT,
	@PreferredLanguage varchar(11) = 'en-US' OUTPUT,
	@MailOption bit = 0 OUTPUT,
	@Language varchar(20) = 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
	Created: 20090930@VinhTrinh:
	Task : Affiliate require new password when they forget it.
	DB: DB052.Affiliate_ZZun

	Revisions:
	  - 20130814@Joseph: fix unicode for errmsg string 
	Param's Explanation:
	• @Email email request password
	• @ValidCode code generate to affiliate when using forget password
	• @NewPwd Generate random password and send to Affiliate
	• @AffID return affid
	• @Username return username
	• @Firstname return firstname
	• @Lastname return lastname
*/
SET NOCOUNT ON
IF Exists(Select 1 FROM AffDetail with(nolock) WHERE AffId=@AffId and ValidCode=@ValidCode and datediff(hh, convert(datetime,CodeExpiry), current_timestamp)< 24)
BEGIN
	UPDATE AffInfo with(rowlock,updlock)
	SET Password=@NewPwd--, pwdexpiry=dateadd(dd, 30, CURRENT_TIMESTAMP),answer='',question=''
	WHERE AffId=@AffId
	
	UPDATE AffDetail with(rowlock,updlock)
	SET ValidCode='', CodeExpiry = null--, pwdexpiry=dateadd(dd, 30, CURRENT_TIMESTAMP),answer='',question=''
	WHERE AffId=@AffId
	
	Select @Email=email,@UserName=UserName,@ErrCode=0,@Firstname = firstname, @Lastname = lastname
	From AffInfo with(nolock) 
	Where AffId=@AffId
	
	Select @PreferredLanguage = PreferredLanguage, @MailOption = MailOption
	From AffDetail with(nolock) 
	Where AffId=@AffId
END
ELSE
BEGIN
	SELECT @ErrMsg =CASE @Language 
					WHEN 'en-US' THEN 'The address that you have used to request a new password is not valid.'
					WHEN 'zh-TW' THEN N'您用於申請新密碼的地址無效'	
					WHEN 'zh-CN' THEN N'您用于申请新密码的地址无效。'					
					WHEN 'th-TH' THEN N'ระบุที่อยู่ เพื่อแจ้งเปลี่ยนพาสเวิดไม่ถูกต้อง.'
					WHEN 'es-ES' THEN N'La dirección que ha utilizado para solicitar una nueva contraseña no es válida.'
					WHEN 'vi-VN' THEN N'Địa chỉ bạn đã sử dụng để yêu cầu mật khẩu mới không hợp lệ.'
					WHEN 'id-ID' THEN N'Alamat yang Anda gunakan untuk meminta kata sandi baru, tidak valid.'
					ELSE N'The address that you have used to request a new password is not valid.'
				END, @ErrCode = 1001	 
	RETURN 
END

declare @SPName varchar(50), @LogData nvarchar(300)
Select @LogData = 'Recover password for customer AffiliateID:' + dbo.Aff_ToString(@AffId) 
select @SPName = OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @AffID,
	@AffID = @AffID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData	 
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateLogin]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateLogin    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateLogin]  
 @UserName varchar(50),  
 @UserPwd varchar(50),   
 @LoginIP varchar(20),  
 @ServerID int,   
 @CustID int OUTPUT,   
 @FirstName nvarchar(50) ='' OUTPUT,  
 @LastName nvarchar(50) ='' OUTPUT,  
 @Email nvarchar(50)='' OUTPUT,  
 @MailOption bit = 1 OUTPUT,  
 @PreferLang varchar(11) = 'en-US' OUTPUT,  
 @Language varchar(20) = 'en-US',  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT,  
 --20090202 @Dung check whether user is required to input security question  
 @HasSecurityQuestion bit=1 OUTPUT,  
 --20101016@Peter check whether user is allowed to use Affiliate Personalized Page function  
 @IsAllowedPersonalizedPage bit=0 OUTPUT,  
 @Prefix varchar(3) = '$' OUTPUT,  
 @Currency varchar(5) = 'USD' OUTPUT,  
 @AffLevel int=0 OUTPUT,
 @InputAffType int = 1,--Check Kiosk system login
 @AffType int = 1 OUTPUT
AS  
/*  
 * Created: 20090720@Ken  
 * Task : Login to Affiliate  
 * DB: DB052.Affiliate_MYM  
 *  
 * Revisions:     
   - 20130815@Joseph: correct vietnamese error message
*/  
SET NOCOUNT ON  
declare @LogData nvarchar(200)  
  
Declare @db_custid int, @db_userpwd nvarchar(50), @db_roleid tinyint, @failedcount int  
Declare @IsClosed bit, @status varchar(30),@IsLocked bit,@LastLoginDate Datetime  
  
declare @SPName varchar(50)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
/*  
-------------------------------------    
--Hard-code for AdminLogin  
-------------------------------------    
if @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%'  
BEGIN  
  
 Declare @AdminUsername varchar(30)  
 select @AdminUsername = left(@username, charindex('/',@UserName)-1),  
   @username = replace(@UserName, @AdminUsername + '/', '')  
   
 if exists (select 1  
    from bodb02.dbo.customer with (nolock)  
    WHERE username = @AdminUsername and userpwd = @UserPwd and RoleID > 8)  
 BEGIN  
  select @UserPwd = userpwd  
  from bodb02.dbo.customer with (nolock)  
  WHERE username = @username    
 END  
 ELSE  
  select @UserPwd = ''  
     
END    
-------------------------------------    
*/  
  
SELECT @db_custid = i.affID, @db_userpwd = isnull(Password, ''), @failedcount = LoginCount,@LastLoginDate=isnull(LastLoginDate,current_timestamp),  
 @FirstName = firstname,@LastName = lastname,@Email = Email, @IsClosed = IsClosed, @Status = Status,@IsLocked=isnull(IsLocked,0),  
 @HasSecurityQuestion = (case when Question is null or Answer is null then 0 else 1 end),  
 @MailOption = MailOption, @PreferLang = d.PreferredLanguage, @IsAllowedPersonalizedPage=i.IsPageEnabled,@AffLevel=i.Level, @AffType = AffType
 , @Prefix = isnull(Prefix, '$'), @Currency=isnull(e.Code,'USD')
FROM AffInfo i with (nolock)  
 INNER JOIN AffDetail d with(nolock) on i.AffID = d.affID  
 left join Exchange e with(nolock) on i.Currency = e.ExchangeID  
WHERE i.username = @UserName or i.Email= @UserName   
   
-- user not found  
IF (@@ROWCOUNT = 0 Or (@InputAffType = 3 and @AffType <> 3) or (@InputAffType <> 3 and @AffType = 3))--Check for kiosk system
BEGIN  
 SELECT @LogData = 'Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
 select @ErrMsg = case @Language when 'en-US' then 'Wrong username or password.'  
         when 'zh-TW' then N'用戶名或密碼錯誤'  
         when 'zh-CN' then N'用户名或密码错误'  
         when 'J' then N'Wrong username or password.'  
         when 'th-TH' then N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'  
         when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'  
         when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'  
         when 'id-ID' then N'Nama pengguna dan kata sandi salah.'  
         else N'Wrong username or password.'  
        end ,@ErrCode=1006        
 return  
END  
  

  
--check Account IsClosed  
If(IsNull(@IsClosed,0) = 1)  
begin  
 --print datediff (n,@LastLoginDate,current_timestamp)  
 SELECT @LogData = 'Failed login attempt (account is Closed), ServerID:' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
 select @ErrMsg = case @Language when 'en-US' then 'Your account is closed. Please contact your administrator!'  
        when 'zh-TW' then N'帳號關閉. 請聯絡管理員.'  
        when 'zh-CN' then N'账号关闭，请联络管理员'  
        when 'J' then N'Your account is closed. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'  
        when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'  
        else N'Your account is closed. Please contact your administrator!'  
      end ,@ErrCode=1009  
 return  
end    
  
--check Account Is Locked   
--print datediff (n,@LastLoginDate,current_timestamp)  
IF (IsNull(@IsLocked,0) = 1 and datediff (mi,@LastLoginDate,current_timestamp)<10)  
BEGIN  
  --print datediff (n,@LastLoginDate,current_timestamp)  
 SELECT @LogData = 'Failed login attempt (account is Locked), ServerID:' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
 select @ErrMsg = case @Language when 'en-US' then 'Your account is locked temporarily due to 5 consecutive failed login attempts. Please try again after 10 minutes or contact your administrator!'  
        when 'zh-TW' then N'因為連續5次登陸失敗，您的帳戶被暫時鎖定。請10分鐘以後再嘗試登陸或者聯繫管理員！'  
        when 'zh-CN' then N'因为连续5次登陆失败，您的账户被暂时锁定。请10分钟以后再尝试登陆或者联系管理员！'  
        when 'J' then N'Your account is closed. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'  
        when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản của bạn bị khóa tạm thời do đăng nhập sai 5 lần liên tiếp. Vui lòng thử lại sau 10 phút hoặc liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'  
        else N'Your account is locked temporarily due to 5 consecutive failed login attempts. Please try again after 10 minutes or contact your administrator!'  
      end ,@ErrCode=1008  
 return  
END  

UPDATE AffDetail with (rowlock, updlock)  
SET  LastLoginDate = CURRENT_TIMESTAMP  
WHERE AffID = @db_custid  
  
--check pending or expired  
IF @status <> 'Approved'   
BEGIN    
 SELECT @LogData = 'Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData  
   
 SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Account not approved.' + dbo.Aff_ToString(@ServerID)  
 EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @Details = @LogData  
   
 select @ErrMsg = case @Language when 'en-US' then 'Wrong username or password.'  
         when 'zh-TW' then N'用戶名或密碼錯誤'  
         when 'zh-CN' then N'用户名或密码错误'  
         when 'J' then N'Wrong username or password.'  
         when 'th-TH' then N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'  
         when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'  
         when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'  
         when 'id-ID' then N'Nama pengguna dan kata sandi salah.'  
         else N'Wrong username or password.'  
        end ,@ErrCode=1006     
  RETURN  
END   
  
IF @db_userpwd <> @UserPWD  
 BEGIN  
  SELECT @LogData = 'Failed login attempt (wrong password), ServerID:' + dbo.Aff_ToString(@ServerID)  
  EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData    
    
  SELECT @failedcount = @failedcount + 1    
  IF @failedcount > 5     
  BEGIN  
   UPDATE AffInfo with(rowlock, updlock) SET IsLocked = ~isnull(IsLocked,0) WHERE AffID = @db_custid  
  
   SELECT @LogData = 'The A/C is Locked due to 5 wrong password attempts'  
   EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData        
   select @ErrMsg = case @Language when 'en-US' then 'Your account is locked temporarily due to 5 consecutive failed login attempts. Please try again after 10 minutes or contact your administrator!'  
        when 'zh-TW' then N'因為連續5次登陸失敗，您的帳戶被暫時鎖定。請10分鐘以後再嘗試登陸或者聯繫管理員！'  
        when 'zh-CN' then N'因为连续5次登陆失败，您的账户被暂时锁定。请10分钟以后再尝试登陆或者联系管理员！'  
        when 'J' then N'Your account is closed. Please contact your administrator!'  
        when 'th-TH' then N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า!'  
        when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'  
        when 'vi-VN' then N'Tài khoản của bạn bị khóa tạm thời do đăng nhập sai 5 lần liên tiếp. Vui lòng thử lại sau 10 phút hoặc liên hệ với quản trị viên của bạn!'  
        when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'  
        else N'Your account is locked temporarily due to 5 consecutive failed login attempts. Please try again after 10 minutes or contact your administrator!'  
      end ,@ErrCode=1008  
     
  END  
  else  
  BEGIN  
    select @ErrMsg = case @Language when 'en-US' then 'Wrong username or password.'  
        when 'zh-TW' then N'用戶名或密碼錯誤'  
        when 'zh-CN' then N'用户名或密码错误'  
        when 'J' then N'Wrong username or password.'  
        when 'th-TH' then N'ชื่อยูสเสอร์และพาสเวิดไม่ถูกต้อง.'  
        when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'  
        when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'  
        when 'id-ID' then N'Nama pengguna dan kata sandi salah.'  
        else N'Wrong username or password.'  
       end ,@ErrCode=1005  
   END  
  UPDATE AffDetail with(rowlock, updlock) SET logincount = @failedcount WHERE AffID = @db_custid    
  return  
 END  
  
-- Successful  
SELECT @CustID = @db_custid  
--Unlock user after 10 minute login sucessfully automatically  
  
if(IsNull(@IsLocked,0) = 1)  
begin   
  Update AffInfo with (rowlock,updlock)  
  set isLocked=~ isLocked  
  WHERE AffID = @db_custid  
end  
  
UPDATE AffDetail with (rowlock, updlock)  
SET logincount = 0, LastLoginIP = @LoginIP, LastLoginDate = CURRENT_TIMESTAMP  
WHERE AffID = @db_custid  
  
SELECT @LogData = 'Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)  
EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateInternalLogin]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateInternalLogin    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateInternalLogin]
    @AdminID int,
    @UserName varchar(50),    
    @LoginIP varchar(20),
    @ServerID int,    
    @AdminUserName varchar(50) OUTPUT,
    @CustID int OUTPUT,    
    @FirstName nvarchar(50) ='' OUTPUT,
    @LastName nvarchar(50) ='' OUTPUT,
    @Email nvarchar(50)='' OUTPUT,
    @PreferLang varchar(11) = 'en-US' OUTPUT,
    @Language varchar(20) = 'en-US',
    @Prefix varchar(3) = '$' OUTPUT,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT,
    --20101016@Peter check whether user is allowed to use Affiliate Personalized Page function
    @IsAllowedPersonalizedPage bit=0 OUTPUT,
    @AffLevel int=0 OUTPUT,
    @InputAffType int = 1,--Check Kiosk system login
    @AffType int = 1 OUTPUT,
    @Currency varchar(6) OUTPUT
AS
/*
 *    Created: 20090316@Ken
 *    Task : Login Affiliate from Admin site (internal login)
 *    DB: DB052.Affiliate_MYM
 *
 *    Revisions:            
*/
SET NOCOUNT ON
declare @LogData nvarchar(200)

Declare @db_custid int, @failedcount int
Declare @closed bit, @status varchar(30)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

SELECT @AdminUserName = ''
SELECT @AdminUserName = UserName
FROM AdminUser WITH(NOLOCK)
WHERE CustID = @AdminID

IF @AdminUserName = '' RETURN

SELECT @db_custid = i.affID, @failedcount = LoginCount,
    @FirstName = firstname,@LastName = lastname,@Email = Email, @closed = IsClosed, @Status = Status, @PreferLang = d.PreferredLanguage, @IsAllowedPersonalizedPage=i.IsPageEnabled,@AffLevel=i.Level
    , @Prefix = isnull(Prefix, '$'), @AffType = AffType,@Currency = c.CurrencyCode
FROM AffInfo i with (nolock)
    INNER JOIN AffDetail d with(nolock) on i.AffID = d.affID
    left join Exchange e with(nolock) on e.ExchangeID = i.Currency
    inner join Currency c with(nolock) on i.Currency = c.CurrencyID
WHERE i.username = @UserName    

-- user not found
IF (@@ROWCOUNT = 0 Or (@InputAffType = 3 and @AffType <> 3) or (@InputAffType <> 3 and @AffType = 3))--Check for kiosk system
BEGIN
    SELECT @LogData = '[FROM ADMIN] Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'
    EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData

    select @ErrMsg = case @Language    when 'en-US' then 'Wrong username or password.'
                                    when 'zh-TW' then N'用戶名或密碼錯誤'
                                    when 'zh-CN' then N'用户名或密码错误'
                                    when 'J' then N'Wrong username or password.'
                                    when 'th-TH' then N'Wrong username or password.'
                                    when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'
                                    when 'vi-VN' then N'Tên truy cập hoặc mật khẩu sai.'
                                    when 'id-ID' then N'Nama pengguna dan kata sandi salah.'
                                    else N'Wrong username or password.'
                                end    ,@ErrCode=1006                        
    return
END

IF IsNull(@closed, 1) = 1
    BEGIN
        SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)
        EXEC [dbo].[Aff_WriteLog] 
            @Creator = @AdminID, 
            @AffID = @db_custid, 
            @Typename = 'LoginAdmin', 
            @SPName = @SPName, 
            @IP = @LoginIP, 
            @Details = @LogData

        select @ErrMsg =    case @Language    when 'en-US' then 'Your account is closed. Please contact your administrator!'
                                when 'zh-TW' then N'帳號關閉. 請聯絡管理員.'
                                when 'zh-CN' then N'账号关闭，请联络管理员'
                                when 'J' then N'Your account is closed. Please contact your administrator!'
                                when 'th-TH' then N'Your account is closed. Please contact your administrator!'
                                when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
                                when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'
                                when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
                                else N'Your account is closed. Please contact your administrator!'
                            end    ,@ErrCode=1008
        return
    END

--check pending or expired
IF @status <> 'Approved'    
BEGIN  
    SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)
    EXEC [dbo].[Aff_WriteLog] 
        @Creator = @AdminID, 
        @AffID = @db_custid, 
        @Typename = 'LoginAdmin', 
        @SPName = @SPName, 
        @IP = @LoginIP, 
        @Details = @LogData
    
    select @ErrMsg =    case @Language    when 'en-US' then 'Account is not approved. Please contact your administrator!'
                                when 'zh-TW' then N'帳號未核準，請聯絡管理員。'
                                when 'zh-CN' then N'账号未核准，请联络管理员'
                                when 'J' then N'Account is not approved. Please contact your administrator!'
                                when 'th-TH' then N'Account is not approved. Please contact your administrator!'
                                when 'es-ES' then N'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
                                when 'vi-VN' then N'Tài khoản không được chấp nhận. Vui lòng liên hệ với quản trị viên của bạn!'
                                when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
                                else N'Account is not approved. Please contact your administrator!'
                        end    ,@ErrCode=1009
    RETURN
END 


-- Successful
SELECT @CustID = @db_custid

SELECT @LogData = '[FROM ADMIN] Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)
EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @AffID = @db_custid, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateIns]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateIns    Script Date: 7/29/2013 1:41:22 AM ******/
/****** Object:  Stored Procedure dbo.Aff_AffiliateIns    Script Date: 11/3/2009 5:46:27 PM ******/  
CREATE PROCEDURE [dbo].[Aff_AffiliateIns]   
 @AffId int OUTPUT, 
 @AffType tinyint = 1,   
 @firstname nvarchar(50),    
 @lastname nvarchar(50),    
 @Gender bit = null,    
 @email nvarchar(50),    
 @phone nvarchar(50),    
 @mobilephone nvarchar(50),    
  
 @address nvarchar(80),    
 @city nvarchar(50),     
 @state nvarchar(50),    
 @postal nvarchar(50),    
 @country nvarchar(50),     
 @emailformat bit = null,  
 @Currency int,  
 --------------------------------------------------     
 @SiteURL varchar(100),     
 @MoreSiteURLs varchar(1000) = NULL,    
 @PreferredLanguage varchar(5),    
 @PreferredPayment varchar(20), --Player, Neteller, Moneybookers, Wire, Cheque    
 @Player_Username varchar(30),    
 @Neteller_AccountID varchar(50) = null,    
 @Moneybookers_Email varchar(50) = null,    
 @Wire_BankName  nvarchar(100) = null,    
 @Wire_BankAddress nvarchar(200) = null,    
 @Wire_SwiftCode  nvarchar(20) = null,    
 @Wire_AccountName nvarchar(100) = null,     
 @Wire_AccountNo  varchar(50) = null,    
 @Cheque_FullName nvarchar(200) = null,    
 @Cheque_Address  nvarchar(200) = null,    
 @Cheque_City  nvarchar(50) = null,    
 @Cheque_State  nvarchar(50) = null,    
 @Cheque_Postal  nvarchar(50) = null,    
 @Cheque_Country  varchar(50) = null,     
 --------------------------------------------------       
 @Question   nvarchar(120),    
 @Answer    nvarchar(120),    
 @IP varchar(20),    
 @Browser varchar(100)='',
 @language varchar(5) = 'en-US',    
 @username varchar(30) = NULL OUTPUT,    
 @ErrCode int = 0 OUTPUT,    
 @ErrMsg nvarchar(200) = '' OUTPUT    
AS  
/*      
Created:     
Task : Register new Affiliate    
DB: DB052.Affiliate_ZZun  
Original: [Aff_AffiliateIns]    
Revisions:      
  
Param's Explanation:      
• @ErrCode:      
    = 0: Create agent successfully.      
    > 0: Specific Error.      
        
• @ErrMsg: Error description.      
*/     
SET NOCOUNT ON  
  
/*IF Exists(Select 1 From AffInfo with (nolock) where UserName2=@UserName2)    
BEGIN    
 SELECT @ErrMsg = case @Language   
      when 'en-US' then N'Nickname has been used. Please choose another one!'  
      when 'zh-TW' then N'Nickname has been used. Please choose another one!'  
      when 'zh-CN' then N'Nickname has been used. Please choose another one!'  
      when 'th-TH' then N'Nickname has been used. Please choose another one!ะ'  
      when 'es-ES' then N'Nickname has been used. Please choose another one!'  
      when 'vi-VN' then N'Nickname đã được sử dụng. Vui lòng chọn Nickname khác!'  
      when 'id-ID' then N'Nickname has been used. Please choose another one!'  
      else N'Nickname has been used. Please choose another one!'    
      end, @ErrCode = 1012  
 return  
END  */  
  
  
IF Exists(Select 1 From AffInfo with (nolock) where email=@email and Status <> 'Disapproved')    
BEGIN    
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Email Address has been used. Please choose another one!'  
      when 'zh-TW' then N'此郵箱地址已被使用，請選用其他郵箱地址。'  
      when 'zh-CN' then N'此邮箱地址已被使用，请选用其他邮箱地址。'  
      when 'th-TH' then N'อีเมลล์นี้ได้ถูกใช้แล้ว กรุณาระบุข้อมูลใหม่คะ'  
      when 'es-ES' then N'Esta dirección de correo electrónico ya se ha utilizado. Escoja otra diferente.'  
      when 'vi-VN' then N'Địa chỉ Email đã được sử dụng. Vui lòng chọn địa chỉ khác!'  
      when 'id-ID' then N'Alamat Email sudah digunakan. Silakan pilih yang berbeda!'  
      else N'Email Address has been used. Please choose another one!'    
      end, @ErrCode = 1002  
 return  
END     
  
  
--Generate username-----------------    
Exec Aff_GenUsername @username = @username OUTPUT    
  
if exists(select 1 from AffInfo with (nolock) where username = @username)    
BEGIN    
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Invalid affiliate information.'  
      when 'zh-TW' then N'此郵箱地址已被使用，請選用其他郵箱地址。'  
      when 'zh-CN' then N'此邮箱地址已被使用，请选用其他邮箱地址。'  
      when 'th-TH' then N'ระบุข้อมูลพันธมิตรไม่ถูกต้อง.'   
      when 'es-ES' then N'La información de afiliación no es válida.'   
      when 'vi-VN' then N'Thông tin hội viên không hợp lệ.'   
      when 'id-ID' then N'Informasi afiliasi tidak valid.'   
      else N'Invalid affiliate information.'       
      end, @ErrCode = 1004  
 return  
END   
--End generate username-----------------    
  
  
  
  
Insert into AffInfo(  
 [UserName]  
 --,[UserName2]  
 ,[FirstName]  
 ,[LastName]  
 ,[Status]  
 ,[IsClosed]  
 ,[Currency]  
 ,[RegisteredDate]  
 ,[Email]  
 ,[Password]  
 ,[IsLocked]
 ,[AffType])  
Values  
(  
 @Username  
 --,@Username2  
 ,@FirstName  
 ,@LastName  
 ,'Pending'  
 ,0  
 ,@Currency  
 ,GetDate()  
 ,@Email  
 ,''  
 ,0  
 ,@AffType
)  
  
if @@error <> 0  
BEGIN    
 SELECT @ErrMsg = case @Language     
    when 'en-US' then 'Create customer failed. Please try again.'    
    when 'zh-TW' then N'新增会员不成功，请重新尝试.'    
    when 'zh-CN' then N'新增會員不成功,請重新再試.'    
    when 'th-TH' then N'เพิ่มลูกค้าไม่สำเร็จ กรุณาลองอีกครั้งคะ'        
    when 'es-ES' then N'No se ha podido crear el cliente. Vuelva a intentarlo.'    
    when 'KO' then N'크레딧 업데이트에 실패했습니다.  현재 마스터의 크레딧이 충분하지 않습니다.'    
    when 'vi-VN' then N'Tạo khách hàng không thành công. Hãy thử lại.'    
    when 'id-ID' then N'Gagal membuat pelanggan. Harap coba lagi.'    
    else N'Create customer failed. Please try again.'    
   end,    
 @ErrCode = 114    
      
 -- ROLLBACK MANUALLY  `  
 Delete From AffInfo With (ROWLOCK) Where AffId = @AffId    
      
 return    
END    
  
select @AffId = @@IDENTITY  
  
Insert into AffDetail(  
 [AffID]  
 ,[UserName]  
 ,[SiteURL]  
 ,[MoreSiteURLs]  
 ,[PreferredLanguage]  
 ,[Gender]  
 ,[Address]  
 ,[Postal]  
 ,[City]  
 ,[State]  
 ,[CountryID]  
 ,[Phone]  
 ,[MobilePhone]  
 ,[Fax]  
 ,[Question]  
 ,[Answer]  
 ,[PreferredPayment]   
 ,[Player_Username]  
 ,[Neteller_AccountID]  
 ,[Moneybookers_Email]  
 ,[Wire_BankName]  
 ,[Wire_BankAddress]  
 ,[Wire_SwiftCode]  
 ,[Wire_AccountName]  
 ,[Wire_AccountNo]  
 ,[Cheque_FullName]  
 ,[Cheque_Address]  
 ,[Cheque_City]  
 ,[Cheque_State]  
 ,[Cheque_Postal]  
 ,[Cheque_Country]  
 ,[MailOption]  
)  
Values  
(  
 @AFfId  
 ,@Username  
 ,@SiteURL  
 ,@MoreSiteURLs  
 ,@PreferredLanguage  
 ,@Gender  
 ,@address  
 ,@postal  
 ,@city  
 ,@state  
 ,@country  
 ,@phone  
 ,@mobilephone  
 ,''  
 ,@Question  
 ,@Answer  
 ,@PreferredPayment   
 ,@Player_Username  
 ,@Neteller_AccountID  
 ,@Moneybookers_Email  
 ,@Wire_BankName  
 ,@Wire_BankAddress  
 ,@Wire_SwiftCode  
 ,@Wire_AccountName  
 ,@Wire_AccountNo  
 ,@Cheque_FullName  
 ,@Cheque_Address  
 ,@Cheque_City  
 ,@Cheque_State  
 ,@Cheque_Postal  
 ,@Cheque_Country  
 ,@EmailFormat  
)  
if @@error <> 0  
BEGIN    
 SELECT @ErrMsg = case @Language     
    when 'en-US' then 'Create customer failed. Please try again.'    
    when 'zh-TW' then N'新增会员不成功，请重新尝试.'    
    when 'zh-CN' then N'新增會員不成功,請重新再試.'    
    when 'th-TH' then N'เพิ่มลูกค้าไม่สำเร็จ กรุณาลองอีกครั้งคะ'        
    when 'es-ES' then N'No se ha podido crear el cliente. Vuelva a intentarlo.'    
    when 'KO' then N'크레딧 업데이트에 실패했습니다.  현재 마스터의 크레딧이 충분하지 않습니다.'    
    when 'vi-VN' then N'Tạo khách hàng không thành công. Hãy thử lại.'    
    when 'id-ID' then N'Gagal membuat pelanggan. Harap coba lagi.'    
    else N'Create customer failed. Please try again.'    
   end,    
 @ErrCode = 111    
      
 -- ROLLBACK MANUALLY  `  
 Delete From AffInfo With (ROWLOCK) Where AffId = @AffId    
 Delete From AffDetail With (ROWLOCK) Where AffId = @AffId    
      
 return    
END    
  
  
Declare @LogData varchar(5000), @SPName varchar(100)   
select @SPName = OBJECT_NAME(@@ProcID)  
    
Select @LogData = 'Add new Affifilate  
firstname='+ dbo.Aff_ToString(@firstname) + ',  
lastname'+ dbo.Aff_ToString(@lastname) + ',  
Gender='+ dbo.Aff_ToString(@Gender) + ',  
country='+ dbo.Aff_ToString(@country) + ',  
email='+ dbo.Aff_ToString(@email) + ',  
phone='+ dbo.Aff_ToString(@phone) + ',  
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',  
address='+ dbo.Aff_ToString(@address) + ',  
city='+ dbo.Aff_ToString(@city) + ',  
state='+ dbo.Aff_ToString(@state) + ',  
postal='+ dbo.Aff_ToString(@postal) + ',  
Currency='+ dbo.Aff_ToString(@Currency) + ',  
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',  
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',  
PreferredPayment='+ dbo.Aff_ToString(@PreferredPayment) + ',  
PreferredLanguage='+ dbo.Aff_ToString(@PreferredLanguage) + ',  
Player_Username='+ dbo.Aff_ToString(@Player_Username) + ',  
Neteller_AccountID='+ dbo.Aff_ToString(@Neteller_AccountID) + ',  
Moneybookers_Email='+ dbo.Aff_ToString(@Moneybookers_Email) + ',  
Wire_BankName='+ dbo.Aff_ToString(@Wire_BankName) + ',  
Wire_BankAddress='+ dbo.Aff_ToString(@Wire_BankAddress) + ',  
Wire_SwiftCode='+ dbo.Aff_ToString(@Wire_SwiftCode) + ',  
Wire_AccountName='+ dbo.Aff_ToString(@Wire_AccountName) + ',  
Wire_AccountNo='+ dbo.Aff_ToString(@Wire_AccountNo) + ',  
Cheque_FullName='+ dbo.Aff_ToString(@Cheque_FullName) + ',  
Cheque_Address='+ dbo.Aff_ToString(@Cheque_Address) + ',  
Cheque_City='+ dbo.Aff_ToString(@Cheque_City) + ',  
Cheque_State='+ dbo.Aff_ToString(@Cheque_State) + ',  
Cheque_Postal='+ dbo.Aff_ToString(@Cheque_Postal) + ',  
Cheque_Country='+ dbo.Aff_ToString(@Cheque_Country) + ',  
language='+ dbo.Aff_ToString(@language)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@AffID,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateForgotPwd]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateForgotPwd    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateForgotPwd]
    @Email nvarchar(50)=Null,
    @ValidCode nvarchar(10),
    @Language varchar(20) = 'en-US',    
    @AffID int OUTPUT,
    @Username varchar(30) OUTPUT,
    @Firstname nvarchar(50) = NULL OUTPUT,
    @Lastname nvarchar(50) = NULL OUTPUT, 
    @PreferredLanguage varchar(11) = null Output,
    @MailOption bit = 1 Output,
    @IP varchar(20) = '', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg     nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20090930@VinhTrinh:
    Task : Affiliate require new password when they forget it.
    DB: DB052.Affiliate_MYM

    Revisions:
      - 
    Param's Explanation:
    • @Email email request password
    • @ValidCode 
    • @AffID return affid
    • @Username return username
    • @Firstname return firstname
    • @Lastname return lastname
*/
SET NOCOUNT ON
Declare @IsClosed bit

select @AffID = null

SELECT @AffID=AffID, @Username=c.username, @Firstname = c.firstname, @Lastname = c.lastname, @IsClosed = IsClosed
FROM AffInfo c with(nolock) 
WHERE Email=@Email 
    and Status = 'Approved'


IF @AffID is null
BEGIN
    IF EXISTS(
                SELECT 1 
                FROM AffInfo with(nolock) 
                where Email=@Email and Status <> 'Approved'
               )
    BEGIN
        SELECT @ErrMsg =CASE @Language 
                        WHEN 'en-US' THEN 'Account is not approved. Please contact your administrator!'
                        WHEN 'zh-TW' THEN N'賬號未被核准，請聯絡管理員'
                        WHEN 'zh-CN' THEN N'账号未被核准，请联络管理员'
                        WHEN 'th-TH' THEN 'บัญชีของคุณไม่ได้รับการอนุมัติ กรุณาติดต่อฝ่ายบริการลูกค้า'
                        WHEN 'es-ES' THEN 'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
                        when 'vi-VN' then N'Tài khoản không được chấp nhận. Vui lòng liên hệ với quản trị viên của bạn!'
                        when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
                        ELSE N'Account is not approved. Please contact your administrator!'
                    END, @ErrCode = 1009     
        RETURN 
    END

    SELECT @ErrMsg =CASE @Language 
                    WHEN 'en-US' THEN N'You have not entered an email address that we recognise. Please try again or <a href=ContactUs.aspx>contact us</a>.'
                    WHEN 'zh-TW' THEN N'您所輸入的電子郵箱地址無法識別，請重新輸入或者 <a href=ContactUs.aspx>contact us</a>.'
                    WHEN 'zh-CN' THEN N'您所输入的电子邮箱地址无法识别，请重新输入或者 <a href=ContactUs.aspx>contact us</a>.'
                    WHEN 'th-TH' THEN N'อีเมลล์ของคุณไม่ถูกต้อง กรุณาลองอีกครั้ง หรือ <a href=ContactUs.aspx> ติดต่อเรา </a>.'
                    when 'vi-VN' then N'Bạn đã không nhập địa chỉ email mà chúng tôi ghi nhận. Hãy thử lại hoặc <a href=ContactUs.aspx>liên hệ với chúng tôi</a>.'
                    when 'id-ID' then N'Anda belum memasukkan alamat email yang kami akui. Silakan coba lagi, atau <a href=ContactUs.aspx>hubungi kami</a>.'
                    WHEN 'es-ES' THEN N'No se ha podido identificar la dirección de correo electrónico que ha proporcionado. Vuelva a intentarlo o <a href=ContactUs.aspx>póngase en contacto con nosotros</a>.'
                    ELSE N'You have not entered an email address that we recognise. Please try again or <a href=ContactUs.aspx>contact us</a>.'
                    
                END, @ErrCode = 1001     
    RETURN 
    
END
ELSE IF @IsClosed = 1
BEGIN
    SELECT @ErrMsg =CASE @Language 
                    WHEN 'en-US' THEN N'Your account is closed. Please contact your administrator!'
                    WHEN 'zh-TW' THEN N'帳號關閉. 請聯絡管理員.'
                    WHEN 'zh-CN' THEN N'账号关闭，请联络管理员'
                    WHEN 'th-TH' THEN N'บัญชีของคุณถูดปิด กรุณาติดต่อฝ่ายบริการลูกค้า'
                    WHEN 'es-ES' THEN N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
                    when 'vi-VN' then N'Tài khoản của bạn bị đóng. Vui lòng liên hệ với quản trị viên của bạn!'
                    when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
                    ELSE N'Your account is closed. Please contact your administrator!'
                END, @ErrCode = 1008     
    RETURN 
END

--Return preference language and mail option
select @PreferredLanguage = PreferredLanguage, @MailOption = MailOption
FROM AffDetail c with(nolock) 
WHERE AffID=@AffID

    
--Update customer store validcode in answer field,expiry in question field
UPDATE AffDetail with(rowlock,updlock) 
SET ValidCode=@ValidCode, CodeExpiry=dateadd(hh, 24, current_timestamp)
WHERE AffId=@AffId
Select @Errcode=0

--Write log
declare @SPName varchar(50), @LogData nvarchar(300)
Select @LogData = 'Forgot password for affiliateID:' + dbo.Aff_ToString(@AffID) + ' ValidCode:' + @ValidCode
select @SPName = OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @AffID,
    @AffID = @AffID,
    @Typename = 'Password', -- refer to table LogType
    @SPName = @SPName,
    @Details = @LogData,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateCommReport]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateCommReport    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateCommReport]
    @MonthDate datetime=null,        
    @ProductID tinyint=0,
    @UserName nvarchar(50)=NULL,
    @PreferredLanguage varchar(11) = null,
    @Currency varchar(5) = 0,
    @AffType tinyint = 0,
    @PageSize int=50,
    @PageIndex int=1,
    @TotalPages int=0 OUTPUT,
    @NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get report of Active members 
DB: DB052.Affiliate_MYM
Original: [Aff_AffiliateCommReport]
Revisions:
    
Param's Explanation:
    • @Fromdate Time search From
    • @Todate Time search To,
    • @IsGetAll if getall = 1 => get data in all date,
    • @UserName Affiliate username need to search(must match username),
    • @PageSize Page Size,
    • @PageIndex Current page,
    • @TotalPages num pages return,
    • @NRows num rows return
*/
Set Nocount On

select @UserName= '%' + Coalesce(@UserName, '') + '%'

select @MonthDate=dbo.Date_Only([dbo].[Aff_GetLastDayOfMonth] (@MonthDate))



--count nrows
select @NRows=count(1)    
FROM  AffInfo ai with (nolock)  
    inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE ai.Status='Approved'    
    and ai.Username like @UserName
    and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage) 
    and (@Currency=0 or @Currency= ai.Currency) 
    and (@AffType=0 or AffType = @AffType)
    and ai.ApprovedDate <=  [dbo].[Aff_GetLastDayOfMonth] (@MonthDate)


if(isnull(@NRows,0)=0)    
    return  

DECLARE @RowStart int, @RowEnd int,@AffectedRows int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
        
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30),IsClosed bit, 
Currency varchar(5), AffComm money,AffTypeName varchar(50))

insert into @TempAff
select m.AffId, m.username,m.IsClosed, m.Currency,NULL,m.AffTypeName
from  
    (select ROW_NUMBER() OVER(ORDER BY ai.IsClosed,ai.AffId) AS TheCount,  
        ai.AffID, ai.UserName, ad.PreferredLanguage,ai.IsClosed, c.CurrencyCode as Currency,
        at.Name as AffTypeName
    from AffInfo ai with (nolock)    
        inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
       inner join Currency c with (nolock) on c.CurrencyID=ai.Currency
       left join AffType at with(nolock) on ai.AffType = at.TypeID
    WHERE ai.Status='Approved'    
    and ai.Username like @UserName
    and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage) 
    and (@Currency=0 or @Currency= ai.Currency) 
    and (@AffType=0 or AffType = @AffType)
    and ai.ApprovedDate <= [dbo].[Aff_GetLastDayOfMonth] (@MonthDate)
    )m 
where m.TheCount between @RowStart and @RowEnd      
select @AffectedRows=@@ROWCOUNT


if(not exists (select top(1) 1 from AffCommission(nolock) where winlostdate=@MonthDate))            
begin
        declare @AffID int,
        @Amount money, -- Amount with Marketing Fee included
        @Month int,
        @Year int,
        @count int
        
        if(datediff(m,current_timestamp,@MonthDate)=0)
        begin
            --calculate for current month and display the data
            select top(1) @AffId=AffID
            from @TempAff
            where AffComm is null    
            select @count=0
            --print @AffID        
            while(@AffId is not null and @count<@AffectedRows)
            begin
                exec [dbo].[Aff_CalMonthlyEarningCurrent] @AffID=@AffID,@ProductID=@ProductID, @Amount=@Amount OUTPUT
                update @TempAff
                set AffComm=isnull(@Amount,0)
                where AffID=@AffID
                --Get next AffID
                
                select top(1) @AffId=AffID
                from @TempAff
                where AffComm is null    
                
                set @count=@count+1
                
            end            
        end
        else
        begin
            --calculate for the month and display the data
            select @Month=month(@MonthDate),@Year=year(@MonthDate)
            select top(1) @AffId=AffID 
            from @TempAff
            where AffComm is null    
            select @count=0
                    
            while(@AffId is not null and @count<@AffectedRows)
            begin
                exec [dbo].[Aff_CalMonthlyEarning] @AffID=@AffID,@Month=@Month,@Year=@Year,@ProductID=@ProductID,@Amount=@Amount OUTPUT
                update @TempAff
                set AffComm=isnull(@Amount,0)
                where AffID=@AffID
                --Get next AffID
                select top(1) @AffId=AffID 
                from @TempAff
                where AffComm is null    
                 set @count=@count+1                    
            end
        end    
        --Select the result Data in order
        Select t.AffId,
            t.Username,
            t.IsClosed,
            t.Currency,
            t.AffComm,
            t.AffTypeName        
            From @TempAff t
            order by t.IsClosed,t.AffId, t.Username
    end
else
    begin
            Select t.AffId,
            t.Username,
            t.IsClosed,
            t.Currency,
            sum(t2.AffWinlost) as AffComm,
            t.AffTypeName        
            From @TempAff t left join
            (        
                Select ac.AffId,
                    ac.AffWinlost
                From AffCommission ac with(nolock)                        
                    inner join @TempAff t1 on t1.AffId=ac.AffId            
                where winlostdate=@MonthDate
                        and (@ProductID=0 or ProductID=@ProductID)
            ) t2 on t.AffId = t2.AffId
            group by  t.AffId,
            t.Username,
            t.IsClosed,
            t.Currency,
            t.AffTypeName
            order by t.IsClosed,t.AffId, t.Username    
    end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminUpdPwd]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminUpdPwd    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE PROCEDURE [dbo].[Aff_AdminUpdPwd]  
    @CustID int,
    @UserID int,  
    @OldPwd nvarchar(50)=null,
    @UserPwd nvarchar(50),    
    @Language varchar(5)= 'en-US', 
    @IP varchar(20), 
    @ErrCode int = 0 OUTPUT,  
    @ErrMsg nvarchar(2000)='' OUTPUT  
AS  
  
SET NOCOUNT ON  
--DB02.bodb02 --> DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
--Check permission-----------------------------
if @OldPwd is null
BEGIN
    EXEC [dbo].[Aff_Con_CheckPermission] 
        @custid=@UserID,
        @funcname='[UserControl]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output
        
    If @ErrCode <> 0
        RETURN
END
    
    
if not exists(select 1 from AdminUser with (NOLOCK) 
                where CustID = @CustID 
                and (case when (@OldPwd is not null and UserPwd = @OldPwd) or @OldPwd is null then 1 
                        else 0 end ) = 1 )
BEGIN
    Select @ErrMsg =  case @Language 
    when 'en-US' then N'Old password is incorrect' 
    when 'zh-TW' then N'舊密碼不正確.' 
    when 'zh-CN' then N'旧密码不正确' 
    when 'th-TH' then N'ใส่พาสเวิดเดิมไม่ถูกต้อง' 
    when 'es-ES' then N'La contraseña antigua es incorrecta' 
    when 'vi-VN' then N'Mật khẩu cũ không đúng'    
    when 'id-ID' then N'Kata sandi lama salah'
    else N'Old password is incorrect'
    end,
    @ErrCode = 1001
    RETURN 
END


      
declare @PwdExpiry datetime
  
select @PwdExpiry = dateadd(dd, 30, getdate())  
UPDATE AdminUser  with (ROWLOCK, UPDLOCK)  
SET userpwd=@UserPwd, pwdexpiry=@PwdExpiry   
where custid=@CustID  
 
 
 --Write log
declare @SPName varchar(50),@LogData nvarchar(200)  
Select @LogData = 'Changed password CustID:' + dbo.Aff_ToString(@CustID)
select @SPName = OBJECT_NAME(@@ProcID)
  
EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Password', -- refer to table LogType
    @SPName = @SPName,
    @Details = @LogData,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminNoteUpd]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminNoteUpd    Script Date: 7/29/2013 1:41:22 AM ******/
CREATE PROCEDURE [dbo].[Aff_AdminNoteUpd]
	@Noteid int ,
	@Note nvarchar(1000) ,
	@Updatedby int ,
	@UserID int,
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@TrangLe
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20100904@Johnny: Check permission (media affiliate, normal affiliate on this function)
- 20130808@Joseph: fix write log params

Param's Explanation:
. @Noteid : autonumber output
. @Note: content of the note
. @UserID Affiliate ID
. @Updatedby: User cust id

• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Update note unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC dbo.Aff_CheckPermissionOnAff 
	@custid=@Updatedby,
	@AffId=@UserID,
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
UPDATE AdminNotes with(rowlock,updlock)
SET 	
	Updateddate = getdate(),
	Note=@Note,
	Updatedby=@Updatedby
WHERE Noteid=@Noteid

IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! Update note unsuccessfully!' 
					when 'zh-CN' then N'錯誤!更新註解不成功!'
					when 'zh-TW' then N'错误！更新注解不成功！'
					else N'Error! Update note unsuccessfully!' 
				end, @ErrCode = 1001
	return
END


DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Update Note ID:' + dbo.Aff_ToString(@Noteid)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog] 
@AffID = @UserID,  
@Creator = @Updatedby,
@Typename = 'UserNote', -- refer to table LogType
@SPName = @SPName,
@Details = @LogData,
@IP=@IP

end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AddExchanges]    Script Date: 07/30/2013 04:21:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AddExchanges    Script Date: 7/29/2013 1:41:23 AM ******/
-- =============================================
-- Author:        Joseph
-- Create date: 20-02-2013
-- Description:    
-- =============================================
CREATE Procedure [dbo].[Aff_AddExchanges]
    @Currencies varchar(255), 
    @Data varchar(8000), 
    @CustId int,
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT    
AS
BEGIN
    
    SET NOCOUNT ON;
    
    DECLARE @table1 table (RowID int not null primary key identity(1,1), val nvarchar( 4000) )            
    
    DECLARE @RowsToProcess  int
    DECLARE @CurrentRow     int
    DECLARE @val  varchar(1000)
        
    insert into @table1(val) select val from strSplit(@Data,'#')    
    
    SET @RowsToProcess=@@ROWCOUNT

    SET @CurrentRow=0
    WHILE @CurrentRow<@RowsToProcess
    BEGIN
        SET @CurrentRow=@CurrentRow+1
        SELECT 
            @val='insert into dbo.Exchange(IsAutoRefresh,CreatedDate,ExchangeID,Code,Currency,Creator,' +
             @Currencies + ') values(0, CURRENT_TIMESTAMP,' +
            replace(val,'{creator}',@CustId) + ')'
            FROM @table1
            WHERE RowID=@CurrentRow
        --select @val    
        exec(@val)
        --do your thing here--

    END


DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Add exchanges of affiliate. Currencies:' + @Currencies + ', Rates: ' + dbo.Aff_ToString(@Data) 

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@CustId,        
    @TypeName= 'AddExchange',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData

END
GO
/****** Object:  StoredProcedure [dbo].[Aff_AddAffCurrencies]    Script Date: 07/30/2013 04:21:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AddAffCurrencies    Script Date: 7/29/2013 1:41:23 AM ******/
-- =============================================
-- Author:        Joseph
-- Create date: 20-02-2013
-- Description:    
-- =============================================
CREATE Procedure [dbo].[Aff_AddAffCurrencies]    
    @Data varchar(1000), 
    @CustId int,
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT    
AS
BEGIN
    
    SET NOCOUNT ON;
    
    update dbo.SystemSettings
    set SValue = SValue + ',' + @Data
    where Type='Meta' AND SName = 'AffiliateCurrencies'

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Add Aff currencies . Currencies:' + @Data

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@CustId,        
    @TypeName= 'AddAffCurrencies',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData

END
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminNoteIns]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminNoteIns    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_AdminNoteIns]  
 @Noteid [int] OUTPUT,  
 @Note [nvarchar](1000),  
 @CustID [int],  
 @Updatedby [int],  
 @IP [nvarchar](15) = '',  
    @Language varchar(5)= 'en-US', 
 @ErrCode [int] = 0 OUTPUT,  
 @ErrMsg [nvarchar](4000) = '' OUTPUT  
WITH EXECUTE AS CALLER  
AS  
begin   
/*  
Created: 20090122@TrangLe  
Task : [description of SP]  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
- 20090122@[Reviewer]: [Description of revision]   
  
Param's Explanation:  
. @Noteid : autonumber output  
. @Note: content of the note  
. @CustID: Affiliate ID  
. @Updatedby: User cust id  
  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert note unsuccessfully!  
  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
  
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@Updatedby,  
 @AffId=@CustID,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
BEGIN TRANSACTION  
INSERT INTO AdminNotes  
(    
 [Note] ,  
 [Updateddate] ,  
 [AffID] ,  
 [Updatedby]   
)  
VALUES  
(   
 @Note ,  
 GETDATE(),  
 @CustID ,  
 @Updatedby   
)  
IF @@ERROR <> 0  
BEGIN  
 ROLLBACK TRANSACTION  
 Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error! Insert note unsuccessfully!' 
                    when 'zh-CN' then N'錯誤!插入註解不成功!'
                    when 'zh-TW' then N'错误！插入注解不成功！'
                    else N'Error! Insert note unsuccessfully!' 
                end, @ErrCode = 1001  
 return  
END  
  
SELECT @Noteid = SCOPE_IDENTITY()  
COMMIT TRANSACTION  
  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Create Note ID:' + dbo.Aff_ToString(@Noteid)  
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @Updatedby,  
 @AffID = @CustID,  
 @Typename = 'UserNote', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP  
   
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminNoteDel]    Script Date: 07/30/2013 04:21:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminNoteDel    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_AdminNoteDel]
    @AffId int,
    @listnode varchar(500),
    @UserID int,
    @IP nvarchar(15)='',
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@TrangLe
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
.@Noteid: Note needs to be deleted.
.@UserID: User to be logged

• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete note unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
/*EXEC [dbo].[Aff_Con_CheckPermission] 
    @custid=@UserID,
    @funcname='[Affiliate]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output*/
    
EXEC dbo.Aff_CheckPermissionOnAff 
    @custid=@UserID,
    @AffId=@AffId,
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
Delete AdminNotes with(rowlock)
WHERE Noteid in (select Val from strSplit(@listnode, ';'))

IF @@ERROR <> 0
BEGIN
    
    Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error! Delete note unsuccessfully!' 
                    when 'zh-CN' then N'錯誤!刪除註解不成功!'
                    when 'zh-TW' then N'错误！删除注解不成功！'
                    else N'Error! Delete note unsuccessfully!' 
                end, @ErrCode = 1001
    return
END

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Delete Notes:' + dbo.Aff_ToString(@listnode)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog] 
@Creator = @UserID,
@AffID = @AffID,
@Typename = 'UserNote', -- refer to table LogType
@SPName = @SPName,
@IP=@IP,
@Details = @LogData
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdminLogin]    Script Date: 07/30/2013 04:21:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdminLogin    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_AdminLogin] 
    @UserName varchar(50) OUTPUT,
    @UserPwd varchar(50),
    @LoginIP varchar(20),    
    @CustID int OUTPUT,
    @RoleID tinyint OUTPUT,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT,
    @Language varchar(5)= 'en-US',
    @From nvarchar(200) = '',
    @IsIT bit = 0 OUTPUT
AS
SET NOCOUNT ON
-- DB03.bodb02 --> DB052.Affiliate_ZZun
-- 20100713@Peter : Remove Write Log on IBC DB
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun

declare @LogData nvarchar(200),
    @db_userpwd nvarchar(50),
    @failedcount tinyint, @closed bit,    
    @SPName varchar(50),
    @GroupName nvarchar(50),
    @GroupID int

select @SPName = OBJECT_NAME(@@ProcID)
SELECT @LogData = '', @ErrMsg = '', @ErrCode = 0 -- initial value

SELECT @CustID = custid, @db_userpwd = UserPwd, @RoleID = roleid, @failedcount = IsNull(logincount, 0),
        @UserName = username, @closed = closed, @GroupName = GroupName, @GroupID = au.GroupId
FROM     AdminUser au with (NOLOCK) 
        inner join AffGroupInfo g with (nolock) on au.GroupId = g.GroupId
WHERE username = @UserName


IF @@ROWCOUNT = 0 -- user not found
    SELECT  @ErrMsg = case @Language 
                            when 'en-US' then 'Wrong username or password.'
                            when 'zh-CN' then N'用户名或密码错误.'
                            when 'zh-TW' then N'用戶名或密碼錯誤.'
                            when 'J' then N'IDまたはパスワードが正しくありません。'
                            when 'th-TH' then N'Wrong username or password.'
                            when 'vi-VN' then N'Sai tên truy cập hoặc mật khẩu.'
                            when 'es-ES' then N'Wrong username or password.'
                            else N'Wrong username or password.'
                        end,
        @ErrCode = 1001,
        @CustID = 0,
        @LogData = 'Admin:' + @UserName + ' IP:' + @LoginIP + ' Result:Failed(User_Not_Found) From:' + @From

ELSE IF @RoleID NOT IN (5,6,7,8,9,10)
    SELECT  @ErrMsg =case @Language 
                            when 'en-US' then 'Wrong username or password.'
                            when 'zh-CN' then N'用户名或密码错误.'
                            when 'zh-TW' then N'用戶名或密碼錯誤.'
                            when 'J' then N'IDまたはパスワードが正しくありません。'
                            else N'Wrong username or password.'
                        end,
        @ErrCode = 1002, 
        @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(Not_Admin) From:' + @From

ELSE IF @UserPWD <> @db_userpwd
BEGIN
    SELECT @ErrMsg = case @Language
                            when 'en-US' then 'Wrong username or password.'
                            when 'zh-CN' then N'用户名或密码错误.'
                            when 'zh-TW' then N'用戶名或密碼錯誤.'
                            when 'J' then N'IDまたはパスワードが正しくありません。'
                            else N'Wrong username or password.'
                      end,
        @ErrCode = 1003,
        @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(Password) From:' + @From

    IF @failedcount = 5  -- already failed for 5 times, this is 6th time , LOCK THE A/C        
    BEGIN
        
         UPDATE AdminUser with (rowlock, updlock) SET closed = 1 WHERE custid = @custid
         
        
        select @LogData = 'The A/C is closed due to 5 wrong password attempts'    
            , @ErrMsg = case @Language
                            when 'en-US' then 'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
                            when 'zh-CN' then N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
                            when 'zh-TW' then N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
                            when 'J' then N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
                            else N'Your account is closed due to 5 consecutive failed login attempts. Please contact your administrator.'
                      end,
        @ErrCode = 1003
        
        
    END
    ELSE
        UPDATE AdminUser with (rowlock, updlock) SET logincount = @failedcount + 1 WHERE custid = @custid
END

IF (@ErrMsg = '') AND (@LogData = '')
BEGIN    
    
    IF @closed = 1
        SELECT  @ErrMsg = case @Language
                            when 'en-US' then 'Account closed. Please contact your administrator!'
                            when 'zh-CN' then N'账号已关闭，请联络管理员.'
                            when 'zh-TW' then N'帳號已關閉. 請聯絡管理員.'
                            when 'J' then N'Account closed. Please contact your administrator!'
                            else N'Account closed. Please contact your administrator!'
                          end,
            @ErrCode = 1004,
            @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Failed(A/C_Closed) From:' + @From    
    ELSE
    BEGIN
        UPDATE AdminUser with (rowlock, updlock)
        SET logincount = 0, iplogin = @LoginIP, lastlogged = CURRENT_TIMESTAMP, on_sessionid = 0
        WHERE custid = @custid

        SET @LogData = 'Admin:' + @username + ' IP:' + @LoginIP + ' Result:Success From:' + @From
    END
END

    IF @LogData <> ''
    BEGIN
            
        EXEC [dbo].[Aff_WriteLog] @Creator = @CustID, @AffID = 0, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
    END

Declare @GroupIT varchar(50)

select @GroupIT = [dbo].[Aff_Con_GetGroupItID]()

if(@GroupID = @GroupIT)
    select @IsIT = 1
GO
/****** Object:  StoredProcedure [dbo].[Aff_AdjustmentIns]    Script Date: 07/30/2013 04:21:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AdjustmentIns    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_AdjustmentIns]  
 @Amount  money,   
 @AffID  int,  
 @AdminID int,   
 @transdesc nvarchar(300) = '',  
 @transid bigint OUTPUT,  
 @ip   nvarchar(15) = '',  
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg  nvarchar(200) = '' OUTPUT  
AS  
SET NOCOUNT ON  
-- DB: DB052.Affiliate_ZZun  
/*  
Creator : Vinh  
Date : 2009-07-30  
Task : Approve a payment request.  
  
Input   
 0) @Amount Adjusment amount  
    1) @AffId (For Double check)   
    2) @AdminID User insert transaction  
    3) @transdesc Description of transaction  
    4) @transid transid for this Adjustment  
    5) @userid ID of Admin update this Adjustment  
    6) @IP IP update Adjustment  
   Output  
    1) @ErrCode:  
  = 0: Transaction recorded successfully.  
  > 0: Specific Error.  
    2) @ErrMsg: Error description.  
Revisions:  
  
*/  
SET NOCOUNT ON  
  
--SELECT @ErrCode = 101, @ErrMsg = 'do it later..'  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@AdminID,  
 @funcname='[Payment]',--User the same with payment  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
  
If @ErrCode <> 0  
 RETURN  
  
IF @Amount = 0  
BEGIN  
 Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, amount is invalid.'
                            when 'zh-CN' then N'抱歉,總額是無效的'
                            when 'zh-TW' then N'抱歉，总额是无效的'
                            else N'Sorry, amount is invalid.'
                        end, @ErrCode = 30001  
 return  
END  
  
if(not exists(select 1 from AffInfo(nolock) where AffID=@AffID ))  
begin  
 SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Affiliate!'
                            when 'zh-CN' then N'無效的工作夥伴!'
                            when 'zh-TW' then N'无效的工作伙伴！'
                            else N'Invalid Affiliate!'
                        end
        , @ErrCode = 1001  
 RETURN  
end  
  
Declare @AffCurrency varchar(5), @SysCurrency varchar(5), @SysExRate float, @Status varchar(30), @IsClosed bit  
  
select @AffCurrency = b.Currency,  @Status = Status, @IsClosed = IsClosed  
from AffInfo b with (nolock)   
 inner join Exchange e (nolock) on e.ExchangeId=b.currency  
where AffID = @AffID  
  
  
--Check Data  
if @AffCurrency is null  
Begin  
 Select @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Currency'
                            when 'zh-CN' then N'無效的貨幣'
                            when 'zh-TW' then N'无效的货币'
                            else N'Invalid Currency'
                        end,   
        @ErrCode = 30002  
 return  
End  
  
if @Status <> 'Approved'  
Begin  
 Select 
    @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, You cannot do adjustment because this Affiliate is not approved yet.'
                            when 'zh-CN' then N'抱歉,您無法調整,因為這個工作夥伴尚未核准'
                            when 'zh-TW' then N'抱歉，您无法调整，因为这个工作伙伴尚未核准'
                            else N'Sorry, You cannot do adjustment because this Affiliate is not approved yet.'
                        end,
    @ErrCode = 30003  
    
    return  
End  
  
if @IsClosed = 1  
Begin  
 Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, You cannot do adjustment because this Affiliate is closed.'
                            when 'zh-CN' then N'抱歉,您無法調整,因為這個工作夥伴已經關閉'
                            when 'zh-TW' then N'抱歉，您无法调整，因为这个工作伙伴已经关闭'
                            else N'Sorry, You cannot do adjustment because this Affiliate is closed.'
                        end,   
    @ErrCode = 30004  
 return  
End  
  
  
declare @CurrentDate datetime  
 Set @CurrentDate=current_timestamp  
  
select @SysCurrency=dbo.Aff_GetSystemCurrencyID()  
select @SysExRate=dbo.Aff_GetExchangeRate(@AffCurrency,@SysCurrency, default)  
  
insert into AffTrans([AffID]  
 ,[TransDate]  
 ,[CompletedDate]  
 ,[Amount]  
 ,[Status]  
 ,[Description]  
 ,[Creator]  
 ,[AffCurrency]  
 ,[SysCurrency]  
 ,[SysExRate]   
 ,[TransType]   
 ,[RefID])  
values(  
 @AffID,  
 @CurrentDate,  
 @CurrentDate,  
 @Amount,  
 'Completed',  
 @transdesc,  
 @AdminID,  
 @AffCurrency,  
 @SysCurrency,  
 @SysExRate,  
 203,--Adjustment TransType  
 0  
   
)  
set @transid=SCOPE_IDENTITY()   
  
if @@ERROR <> 0  
begin  
 Select @ErrMsg = case @Language 
                            when 'en-US' then 'This transaction is unsuccessful.'
                            when 'zh-CN' then N'這筆交易是不成功的'
                            when 'zh-TW' then N'这笔交易是不成功的'
                            else N'This transaction is unsuccessful.'
                        end,   
    @ErrCode = 4005   
 return  
end  
  
--Write log  
declare @SPName varchar(50), @Detail nvarchar(4000)   
select @SPName = OBJECT_NAME(@@ProcID)  
select @Detail = 'Modify Balance Brought Forward. Amount = ' + dbo.Aff_ToString(@Amount)   
  
EXEC [dbo].[Aff_WriteLog]   
 @Creator = @AdminID,  
 @AffID = @AffID,  
 @Typename = 'Adjustment', -- refer to table LogType  
 @SPName = @SPName,  
 @Details = @Detail,  
 @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminUpdClosed]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminUpdClosed    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_AdminUpdClosed]
    @CustID int,
    @Closed bit,
    @UserID int,
    @Language varchar(5) = 'en-US',
    @IP varchar(15) = '',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT    
AS
/*
create AccAdmin from existed Admin
DB03.bodb02(Move this SP from DB02.bodb02 to DB03.bodb02) --> DB052.Affiliate_ZZun
Revisions:
    - VinhTrinh@20100507: update closed field in table AdminUser(instead of CustInfo)
    -- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun    
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
    RETURN
--end

update AdminUser with (ROWLOCK) 
set Closed = @Closed,
    LoginCount = (case when @Closed = 0 then 0 else LoginCount end)
where custid = @CustID

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Update AFFILIATE for CustID: ' + dbo.Aff_ToString(@custid) + ' closed: ' + case @closed when 0 then 'open' else 'closed' end


EXEC [dbo].[Aff_WriteLog]
        @Creator=@UserID,    
        @AffID=@CustID,
        @Typename= 'UserControl',    
        @SPName=@SPName ,        
        @IP =@IP,
        @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_ExchangeUpdate]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ExchangeUpdate    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_ExchangeUpdate]
    @CustId int,
    @ExchangeId int,
    @Rate float,
    @ToCurrency varchar(5),
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20091010@Johnny
    Task : Update exchange rate
    DB: DB052.Affiliate_ZZun
    Revisions:
        - 20091014@Johnny initialize
        - 20110223@Viet: Revise
        
    Param's Explanation:

*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@CustId,@funcname='[AffEx.Rate]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN    

if not Exists(select 1 from Exchange with (nolock) where ExchangeId = @ExchangeId)
    return--Do nothing if actualrate as the same as the current one            

IF not Exists(select 1 from systemsettings s where SName = 'AFF_SupportedCurrencies'
            and SValue like '%'+@ToCurrency+'%') 
    return -- currency is not supported
    
DECLARE @sql nvarchar(1000)
    
set @sql = 'update Exchange with (rowlock, updlock) set ' +
     @ToCurrency + ' = ' + LTRIM(Str(@Rate,25,5)) +
    ' where ExchangeId = ' + LTRIM(Str(@ExchangeId,25))

exec (@sql)

set @sql = ' update ExchangeDaily with (rowlock, updlock) set ' +
     @ToCurrency + ' = ' +LTRIM(Str(@Rate,25,5)) +
    ' where ExchangeId = ' + LTRIM(Str(@ExchangeId,25)) +
    ' and datediff(day,[Date],CURRENT_TIMESTAMP)=0'

exec (@sql)


---------Update for ToCurrency convert to FromCurrency
Declare @FromCurrency varchar(5)

Select @FromCurrency = Code From Exchange nolock where ExchangeId = @ExchangeId
IF Exists(select 1 from systemsettings s where SName = 'AFF_SupportedCurrencies'
            and SValue like '%'+@FromCurrency+'%') 
Begin
    --select LTRIM(Str(1/@Rate,25,5))    

    declare @revertRate float
    if @Rate >= 0.0000000000001    
       select @revertRate=1/@Rate     
    else
       select @revertRate=@Rate     
    
    Set @Sql  = 'update Exchange with (rowlock, updlock) set ' +
     @FromCurrency + ' = ' + LTRIM(Str(@revertRate,25,5)) +
    ' where Code = ''' + @ToCurrency + ''''
    select @Sql

    exec (@sql)
    
    Set @Sql  = 'update ExchangeDaily with (rowlock, updlock) set ' +
     @FromCurrency + ' = ' + LTRIM(Str(@revertRate,25,5)) +
    ' where Code = ''' + @ToCurrency + '''' +
    ' and datediff(day,[Date],CURRENT_TIMESTAMP)=0'
    exec (@sql)
End


--------Write Log
DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Update exchange rate of affiliate. ExchangeId:' + dbo.Aff_ToString(@ExchangeId) + ', Rate: ' + dbo.Aff_ToString(@Rate) + ',BasedCurrency:' + dbo.Aff_ToString(@ToCurrency)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@CustId,        
    @TypeName= 'ExchangeRate',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainControlIns]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainControlIns    Script Date: 7/29/2013 1:41:23 AM ******/
CREATE PROCEDURE [dbo].[Aff_DomainControlIns]
    @AffDomainID int,
    @MemberDomainID int,
    @CountryID nvarchar(10),
    @Creator int,
    @Status bit = 1,    
    @UserID int,    
    @IP nvarchar(15)='',
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Add a new AffDomainControl
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
If Exists(select 1 from AffDomainControl nolock where AffDomainID = @AffDomainID and [MemberDomainID] = @MemberDomainID and CountryID = @CountryID)
Begin
    select @ErrCode = 1001,
            @ErrMsg = case @Language 
                    when 'en-US' then 'This domain setting has been existed!' 
                    when 'zh-CN' then N'這個網域設定已經存在!'
                    when 'zh-TW' then N'这个网域设定已经存在！'
                    else N'This domain setting has been existed!' 
                end
    return
End

declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp

BEGIN TRANSACTION
INSERT INTO [AffDomainControl]
   (    
        [AffDomainID]
       ,[MemberDomainID]
       ,[CountryID]
       ,[CreateDate]
       ,[ModifyDate]
       ,[Creator]
       ,[Status]
    )
    VALUES
    (            
        @AffDomainID,
        @MemberDomainID,
        @CountryID,
        @CreatedDate,
        @CreatedDate,
        @Creator,
        @Status
    )
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Insert unsuccessfully.'
                        when 'zh-CN' then N'錯誤發生.插入不成功'
                        when 'zh-TW' then N'错误发生。插入不成功'
                        else N'Error occurs.Insert unsuccessfully.!'
                    end, @ErrCode = 1002
    return
END

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                     
                    + ' MemberDomainID:' + dbo.Aff_ToString(@MemberDomainID)                    
                    + ' CountryID:' + dbo.Aff_ToString(@CountryID)                    

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomainControl', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainControlDel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainControlDel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_DomainControlDel]
    @Id int,
    @UserID int,    
    @IP nvarchar(15)='',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Add a new AffDomainControl
DB: DB052.Affiliate
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
declare @AffDomainID int, @MemberDomainID int, @CountryID nvarchar(10)

select @AffDomainID = AffDomainID, @MemberDomainID = [MemberDomainID], @CountryID = CountryID
from [AffDomainControl]
where Id = @Id

delete [AffDomainControl]
where Id = @Id

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                     
                    + ' MemberDomainID:' + dbo.Aff_ToString(@MemberDomainID)                    
                    + ' CountryID:' + dbo.Aff_ToString(@CountryID)                    

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomainControl', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainAffUpd]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainAffUpd    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE PROC [dbo].[Aff_DomainAffUpd]
    @DomainID int,
    @DomainName nvarchar(50),     
    @UserID int,        
    @IP nvarchar(15)='',
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Update a AffDomain
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
BEGIN TRANSACTION
UPDATE [AffDomain] with (rowlock,updlock)
SET
    [ModifyDate] = getdate(),
    [DomainName] = @DomainName,              
    [Creator] = @UserID
WHERE DomainID = @DomainID

IF @@Error <> 0 
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = case @Language   
          when 'en-US' then 'Error occurs.Update unsuccessfully.'  
          when 'zh-TW' then N'出現錯誤.更新不成功.'  
          when 'zh-CN' then N'出現錯誤，更新失敗'  
          else N'Error occurs.Update unsuccessfully.'    
          end, @Errcode=1001
    return
END     

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                    

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomain', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainAffIns]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainAffIns    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE PROC [dbo].[Aff_DomainAffIns]
    @DomainID int OUTPUT,
    @DomainName nvarchar(50),     
    @UserID int,        
    @IP nvarchar(15)='',
    @Language varchar(8)='en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Add a new AffDomain
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
If Exists(select 1 from [AffDomain] nolock where DomainName = @DomainName)
Begin
    select @ErrCode = 1001
            , @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Insert unsuccessfully.'
                        when 'zh-CN' then N'錯誤發生.插入不成功'
                        when 'zh-TW' then N'错误发生。插入不成功'
                        else N'Error occurs.Insert unsuccessfully.!'
                    end
    return
End

declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp

BEGIN TRANSACTION
INSERT INTO [AffDomain]
   (    
        [DomainName]
       ,[CreateDate]
       ,[ModifyDate]
       ,[Creator]       
    )
    VALUES
    (            
        @DomainName,                
        @CreatedDate,
        @CreatedDate,
        @UserID        
    )
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrCode = 1002
            , @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Insert unsuccessfully.'
                        when 'zh-CN' then N'????.?????'
                        when 'zh-TW' then N'??????????'
                        else N'Error occurs.Insert unsuccessfully.!'
                    end
    return
END

SELECT @DomainID = @@IDENTITY

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                    

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomain', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainAffDel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainAffDel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE PROCEDURE [dbo].[Aff_DomainAffDel]
    @DomainID int OUTPUT,
    @DomainName nvarchar(50),     
    @UserID int,    
    @IP nvarchar(15)='',
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Del a AffDomain
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
If Exists(select 1 from AffDomainControl nolock where [AffDomainID] = @DomainID)
Begin
    select @ErrCode = 1001,
            @ErrMsg = case @Language 
                when 'en-US' then 'This Affiliate domain has been used!'
                when 'zh-CN' then N'?????????????!'
                when 'zh-TW' then N'??????????????'
                else N'This Affiliate domain has been used!'
            end
    return
End

delete [AffDomain]
where DomainID = @DomainID

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                                        

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomain', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_CustomerUdpSecurityQuestion]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CustomerUdpSecurityQuestion    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_CustomerUdpSecurityQuestion]
    @AffID int,
    @UserName varchar(50),
    @Question nvarchar(300),
    @Answer nvarchar(300),
    @LoginIP varchar(20),
    @ServerID int,
    @Language varchar(20) = 'en-US',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT,
    @IP varchar(20)
AS
/*
Created: 20091028@HungPham
Task : update security question for those affiliates who hadn't had security question before this feature came
DB: DB052.Affiliate_MYM
Original:

Revisions:
    - 20091028@[Reviewer]: [Description of revision]    

Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
    
• @ErrMsg: Error description.
• @AffID: AffID of this affiliate
• @Language: current session language of this affiliate.
*/
SET NOCOUNT ON

declare @LogData nvarchar(200), @SPName varchar(100)
select @SPName = OBJECT_NAME(@@ProcID)
--CONTENT OF SP HERE
IF NOT EXISTS (SELECT 1 FROM AffInfo with(nolock) where affid=@AffID and status = 'Approved')
 BEGIN  
    SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Update Security Question failed.(Account not approved)' + CAST(@ServerID as nvarchar(20))
        EXEC [dbo].[Aff_WriteLog]  @Creator=@AffID, @AffID=@AffID,@Details = @LogData,@Typename= 'UserInfo',@SPName=@SPName,@IP =@IP
        select @ErrMsg =    case @Language    when 'en-US' then 'Account is not approved. Please contact your administrator!'
                                when 'zh-TW' then N'帳號未核準，請聯絡管理員。'
                                when 'zh-CN' then N'账号未核准，请联络管理员'
                                when 'J' then N'Account is not approved. Please contact your administrator!'
                                when 'th-TH' then N'บัญชีของคุณไม่ได้รับการอนุมัติ กรุณาติดต่อฝ่ายบริการลูกค้า'
                                when 'es-ES' then N'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
                                when 'vi-VN' then N'Tài khoản không được chấp nhận. Vui lòng liên hệ với quản trị viên của bạn!'
                                when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
                                else N'Account is not approved. Please contact your administrator!'
                            end    ,@ErrCode=1009
        RETURN
  END 

IF EXISTS (SELECT 1 FROM AffDetail with(nolock) where affid=@AffID and not(Question is null or Question='null' or ltrim(rtrim(Question))='' or Answer is null or Answer='null' or ltrim(rtrim(Answer))=''))
  BEGIN
        SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Update Security Question failed.(Account had already had secutity question)' + CAST(@ServerID as nvarchar(20))
        EXEC [dbo].[Aff_WriteLog]  @Creator=@AffID, @AffID=@AffID,@Details = @LogData,@Typename= 'UserInfo',@SPName=@SPName,@IP =@IP
        select @ErrMsg =    case @Language    when 'en-US' then 'Account had already had secutity question. Please contact your administrator!'
                                when 'zh-TW' then N'Account had already had secutity question. Please contact your administrator!'
                                when 'zh-CN' then N'Account had already had secutity question. Please contact your administrator!'
                                when 'J' then N'Account had already had secutity question. Please contact your administrator!'
                                when 'th-TH' then N'บัญชีนี้มีคำถามตรวจสอบความปลอดภัย กรุณาติดต่อฝ่ายบริการ!'
                                when 'es-ES' then N'Ya se ha realizado la pregunta de seguridad de la cuenta. Póngase en contacto con el administrador.'
                                when 'vi-VN' then N'Tài khoản đã có câu hỏi bảo mật. Vui lòng liên hệ với quản trị viên của bạn!'
                                when 'id-ID' then N'Rekening sudah memiliki pertanyaan keamanan. Harap menghubungi administrator Anda!'
                                else N'Account had already had secutity question. Please contact your administrator!'
                            end    ,@ErrCode=1009
        RETURN
  END

UPDATE AffDetail with (rowlock, updlock)
SET Question = @Question, Answer=@Answer
WHERE affid =@AffID

SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Update Security Question Successfully. ServerID:' + dbo.Aff_ToString(@ServerID)

EXEC [dbo].[Aff_WriteLog] 
    @AffID=@AffID,
    @Details=@LogData,
    @Creator=@AffID,    
    @Typename= 'UserInfo',    
    @SPName=@SPName,
    @IP =@IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_CustomerInsMemberManually]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CustomerInsMemberManually    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE PROCEDURE [dbo].[Aff_CustomerInsMemberManually]    
    @AffUserName varchar(30),
    @Username varchar(30),    
    @DepositCustID varchar(50) = null,
    @FirstName nvarchar(50)= null,
    @LastName nvarchar(50)= null,
    @Currency varchar(6),    
    @Email nvarchar(50)= null,    
    @IBCCustID int,    
    @IBCUserName varchar(30)= null,
    @AgentID int,    
    @CreatedDate datetime = null,
    @RegisterDate datetime,
    @Btag varchar(100) = null,
    @ClickID bigint = null,
    @IP varchar(22),    
    @Language varchar(5)= 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(2000) = '' OUTPUT    
AS
/*  
    Created: 20090724@VietHoang
    Task : Add new member existing in the system to Affiliate System
    DB: DB052.Affiliate_ZZun
*/ 
SET NOCOUNT ON
Declare @AffID int

Select @AffID=AffID
from AffInfo (nolock)
where username=@AffUserName

if(@AffID is null)
BEGIN
         Select @ErrMsg = case @Language 
                                when 'en-US' then 'Invalid Affiliate''s username!'
                                when 'zh-CN' then N'無效的合作夥伴的使用者名稱!'
                                when 'zh-TW' then N'无效的合作伙伴的使用者名称！'
                                else N'Invalid Affiliate''s username!'
                            end
            , @ErrCode=1001
     return
END

if (exists (Select 1 from MemberInfo(nolock) where UserName=@Username and IsRemoved!=1))
BEGIN
     Select @ErrCode=1002
            , @ErrMsg = case @Language 
                            when 'en-US' then 'User has been existed in the system!'
                            when 'zh-CN' then N'使用者已經存在在這個系統中!'
                            when 'zh-TW' then N'使用者已经存在在这个系统中！'
                            else N'User has been existed in the system!'
                        end
     return
END

Declare @CurrencyID int 

select @CurrencyID = ExchangeID from [CurrencyConverter] Where [PartnerCurrency] = @Currency

if (exists (Select 1 from MemberInfo(nolock) where UserName=@Username and IsRemoved=1))
BEGIN
     UPDATE [dbo].[MemberInfo]
   SET [AffID] = @AffID      
      ,[RegisteredDate] = @RegisterDate
      ,[CreatedDate]=@CreatedDate
      ,[DepositCustID] = @DepositCustID
      ,[Currency] = @CurrencyID
      ,[FirstName] = @FirstName
      ,[LastName] = @LastName
      ,[Email] = @Email
      ,[IsRemoved] = 0
      ,[IBCCustID] = @IBCCustID
      ,[IBCUserName] = @IBCUserName
      ,Recommend = @AgentID
      ,Btag = @Btag
      ,ClickID = @ClickID    
    WHERE UserName = @Username
    
    Delete from dbo.MemberRemoval Where UserName = @Username

END
ELSE
BEGIN
    INSERT INTO MemberInfo (    
        AffID,
        UserName,        
        IsRemoved,
        DepositCustID,
        FirstName,
        LastName,
        Currency,    
        Email,
        RegisteredDate,
        CreatedDate,
        IBCCustID,    
        IBCUserName,
        Recommend,
        Btag,
        ClickID
    )
    VALUES( 
        @AffID,
        @UserName,
        0, 
        @DepositCustID,
        @FirstName,
        @LastName,
        @CurrencyID,
        @Email,
        @RegisterDate,
        @CreatedDate,        
        @IBCCustID,    
        @IBCUserName,
        @AgentID,
        @Btag,
        @ClickID
    )
END

Declare @LogData nvarchar(4000), @SPName varchar(100) 
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Insert new member. UserName=' + dbo.Aff_ToString(@UserName)                 
                  + '.PlayerCustID=' + dbo.Aff_ToString(@DepositCustID)
                  + '.FirstName=' + dbo.Aff_ToString(@FirstName)
                  + '.LastName=' + dbo.Aff_ToString(@LastName)
                  + '.Currency=' + dbo.Aff_ToString(@Currency)                  
                  + '.Email=' + dbo.Aff_ToString(@Email)
                  + '.RegisteredDate=' + dbo.Aff_ToString(@RegisterDate)
                  + '.CreatedDate=' + dbo.Aff_ToString(@CreatedDate)
                  + '.IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
                  + '.IBCUserName=' + dbo.Aff_ToString(@IBCUserName)
                  + '.Recommend=' + dbo.Aff_ToString(@AgentID)
                  + '.Btag=' + dbo.Aff_ToString(@Btag)
                  + '.ClickID=' + dbo.Aff_ToString(@ClickID)
EXEC [dbo].[Aff_WriteLog]
    @Creator=@AffID,    
    @AffID=@AffID,
    @Typename= 'Member',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData


GRANT EXECUTE ON [dbo].[Aff_CustomerInsMemberManually] TO [bodbadminNet]


GRANT EXECUTE ON [dbo].[Aff_CustomerInsMemberManually] TO [bodbadminNet]
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupInfoUpd]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupInfoUpd    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_GroupInfoUpd]
    @GroupID int,
    @GroupName nvarchar(50)=null,
    @GroupDesc nvarchar(50)=null,
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT,
    @UserID int,
    @IP varchar(15) = ''
AS
/*DB03.BODB02 -->DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
    RETURN
--end

IF exists (select 1 from AffGroupInfo with (NOLOCK) where system = 'AFFILIATE' and Groupname = @GroupName and GroupID <> @GroupID)
BEGIN
    Select @ErrMsg = case @Language 
                when 'en-US' then 'Error! This affiliate does not exist!'
                when 'zh-CN' then N'這個群組名稱已經被使用'
                when 'zh-TW' then N'这个群组名称已经被使用'
                else N'Error! This affiliate does not exist!'
            end, @ErrCode = 101    
    return
END 
ELSE
BEGIN
    Update AffGroupInfo set GroupName=isnull(@GroupName,GroupName),GroupDesc=isnull(@GroupDesc,GroupDesc),Modifydate=getdate(),Creator=@Userid where GroupID=@GroupID    
        
    DECLARE @SPName varchar(50), @LogData nvarchar(200)
    select @SPName = OBJECT_NAME(@@ProcID)

    SELECT @LogData = '[AFFILIATE] Update groupinfo:' + dbo.Aff_ToString(@GroupID)


    EXEC [dbo].[Aff_WriteLog]
            @Creator=@UserID,    
            @AffID=0,
            @Typename= 'UserControl',    
            @SPName=@SPName ,        
            @IP =@IP,
            @Details=@LogData    
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountryUpd]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CountryUpd    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_CountryUpd]
    @Updatedby int ,
    @CountryID nvarchar(6),
    @CountryName nvarchar(255),    
    @Description nvarchar(100)=NULL,    
    @Icon nvarchar(100)=NULL,
    @DisplayOrder smallint=1,
    @IsEnabled bit=1,
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Country
DB: DB052.Affiliate_MYM
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from Country (nolock) where CountryID=@CountryID ))
BEGIN
Select @ErrMsg = N'Error! This country does not exist!', @ErrCode = 1001
    return
END
update Country with (rowlock,updlock)
Set CountryName=@CountryName, [Description]=@Description,
Icon=coalesce(@Icon,Icon), 
DisplayOrder=coalesce(DisplayOrder,DisplayOrder),
IsEnabled =  @IsEnabled
where CountryID=@CountryID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Country. ID= ' + dbo.Aff_ToString(@CountryID) +
     '. Description=' + isnull(@Description,'')

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Country', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountryIns]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CountryIns    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_CountryIns]
    @Updatedby int ,
    @CountryID nvarchar(6),
    @CountryName nvarchar(255),    
    @Description nvarchar(100)=NULL,    
    @Icon nvarchar(100)=NULL,
    @DisplayOrder smallint=1,
    @IsEnabled bit=1,
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Insert Country
DB: DB052.Affiliate_MYM
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

INSERT INTO [Affiliate_MYM].[dbo].[Country]
           ([CountryID]
           ,[CountryName]
           ,[Description]
           ,[Icon]
           ,[DisplayOrder]
           ,[IsEnabled])
     VALUES
           (@CountryID
           ,@CountryName
           ,@Description
           ,@Icon
           ,@DisplayOrder
           ,@IsEnabled)


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Country. ID= ' + @CountryID +
     '. Description=' + isnull(@Description,'')
     

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Country', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountryDel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CountryDel    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE Procedure [dbo].[Aff_CountryDel]
    @Updatedby int ,
    @IDList varchar(max),
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:


Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

delete [dbo].[Country]
where CountryID in (select val from dbo.strsplit(@IDList, ',') )

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Country. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Country', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_CopyRateFromMarket]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CopyRateFromMarket    Script Date: 7/29/2013 1:41:24 AM ******/
CREATE PROCEDURE [dbo].[Aff_CopyRateFromMarket]
    @CustId int,
    @ExchangeIdList varchar(max)='',    
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20110223@Viet
    Task : Copy rates from market
    DB: DB052.Affiliate_ZZun
    Revisions:
        - 20110223@Viet: initialize SP
        
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@CustId,@funcname='[AffEx.Rate]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0    RETURN    

DECLARE @Date smalldatetime
SELECT @Date = Max([Date]) FROM ExchangeDaily with(nolock)
declare @TmpExchange table(exchangeid int)

insert into  @TmpExchange
select val from dbo.strsplit(@ExchangeIdList, ',')


UPDATE ExchangeDaily with(rowlock, updlock)
SET USD = USD_market,
    EUR = EUR_market,
    CNY = CNY_market,
    UUS = UUS_market,
    MYR = MYR_Market,
    SGD = SGD_Market,
    IDR = IDR_Market,
    AUD = AUD_Market,
    CHF = CHF_Market,
    GBP = GBP_Market,
    THB = THB_Market,
    VND = VND_Market
WHERE exchangeID in (select exchangeid from @TmpExchange)
    AND [Date] = @Date
        
UPDATE Exchange with(rowlock, updlock)
SET USD = USD_market,
    EUR = EUR_market,
    CNY = CNY_market,
    UUS = UUS_market,
    MYR = MYR_Market,
    SGD = SGD_Market,
    IDR = IDR_Market,
    AUD = AUD_Market,
    CHF = CHF_Market,
    GBP = GBP_Market,
    THB = THB_Market,
    VND = VND_Market
WHERE exchangeID in (select exchangeid from @TmpExchange)
        
DECLARE @LogData nvarchar(200), @SPName varchar(50)
SELECT @LogData = 'Copy Rates from Market. ExchangeId:' + isnull(@ExchangeIdList,'')
       ,@SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@CustId,        
    @TypeName= 'ExchangeRate',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupPolicyUpd]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupPolicyUpd    Script Date: 7/29/2013 1:41:10 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_GroupPolicyUpd]
    @GroupPolicys NVARCHAR(4000),
    @UserID int, 
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT,
    @IP varchar(15) = ''
AS
/*DB03.BODB02 --> DB052.Affiliate_ZZun*/
-- Update Acc_GroupPolicy
-- Format of @GroupPolicys: @GroupID,@FuncID,@Policy;@GroupID,@FuncID,@Policy; ...;
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
    
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
    RETURN
--end
    
    
    DECLARE @GroupPolicy nvarchar(4000)
    DECLARE @GroupID INT
    DECLARE @FuncID INT
    DECLARE @Policy int
    DECLARE @GroupPolicyCount int 
    DECLARE GroupPolicysCur CURSOR FOR 
        SELECT val as row_index 
          FROM dbo.strSplit(@GroupPolicys, ';')
         ORDER BY row_index
    
    OPEN GroupPolicysCur
    FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
    WHILE @@FETCH_STATUS = 0
    BEGIN

        SET @GroupID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 1)
        SET @FuncID = dbo.Aff_SplitIndex(@GroupPolicy, ',', 2)
        SET    @Policy = dbo.Aff_SplitIndex(@GroupPolicy, ',', 3)
        SET @GroupPolicyCount = (SELECT COUNT(1) FROM AffGroupPolicy with (nolock) WHERE GroupID = @GroupID AND funcid = @FuncID)

        IF(@GroupPolicyCount = 0)
            BEGIN
                INSERT INTO AffGroupPolicy 
                    (GroupID, Funcid, Policy, Createdate, Modifydate, Creator)
                Values
                    (@GroupID, @Funcid, @Policy, CURRENT_TIMESTAMP,CURRENT_TIMESTAMP, @UserID)
            END
        ELSE
            BEGIN
                UPDATE AffGroupPolicy
                   SET policy = @Policy,
                     modifydate = CURRENT_TIMESTAMP
                 WHERE GroupID = @GroupID
                   AND funcid = @FuncID
            END
        
        DECLARE @SPName varchar(50), @LogData nvarchar(200)
        select @SPName = OBJECT_NAME(@@ProcID)

        SELECT @LogData = '[AFFILIATE] UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy) + ' of Function ' + dbo.Aff_ToString(@Funcid) +  ' for Group ' + dbo.Aff_ToString(@GroupID)
        


        EXEC [dbo].[Aff_WriteLog]
                @Creator=@UserID,    
                @AffID=0,
                @Typename= 'UserControl',    
                @SPName=@SPName ,        
                @IP =@IP,
                @Details=@LogData    

        FETCH NEXT FROM GroupPolicysCur INTO @GroupPolicy
    END 
    CLOSE GroupPolicysCur
    DEALLOCATE GroupPolicysCur
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupInfoIns]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupInfoIns    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_GroupInfoIns]
    @GroupID int output,
    @GroupName nvarchar(50)='',
    @GroupDesc nvarchar(50)='',
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT,
    @UserID int,
    @IP varchar(15) = '' 
As
/*DB03.BODB02 -->DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
If @ErrCode <> 0
    RETURN
--end
IF exists (select 1 from AffGroupInfo with (NOLOCK) where system = 'AFFILIATE' and GroupName = @GroupName)
BEGIN
    Select @ErrMsg = case @Language 
                when 'en-US' then 'Error! This affiliate does not exist!'
                when 'zh-CN' then N'這個群組名稱已經被使用'
                when 'zh-TW' then N'这个群组名称已经被使用'
                else N'Error! This affiliate does not exist!'
            end, @ErrCode = 102
    return
END
BEGIN TRANSACTION
    INSERT INTO AffGroupInfo(Groupname, GroupDesc, System, CreateDate,ModifyDate,Creator)
        VALUES (@GroupName, @GroupDesc, 'AFFILIATE', getdate(),getdate(),@UserID)
    
    SELECT @GroupID=@@IDENTITY
    Insert into AffGroupPolicy(GroupID,FuncID,Policy,Createdate,ModifyDate,Creator)
        Select @GroupID as GroupID,FuncID,0 as policy,getdate() as createdate,
            getdate() as modifydate, @UserID as creator
        from AffFunctionInfo with (nolock) where system = 'AFFILIATE'
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        select @ErrMsg = case @Language 
                            when 'en-US' then 'Add group failed.'
                            when 'zh-CN' then N'Add group failed.'
                            when 'J' then N'Add group failed.'
                            else N'Add group failed.'
                        end, @ErrCode = 103
        return
    END
COMMIT TRANSACTION

    DECLARE @SPName varchar(50), @LogData nvarchar(200)
    select @SPName = OBJECT_NAME(@@ProcID)

    SELECT @LogData = '[AFFILIATE] add groupinfo:' + dbo.Aff_ToString(@GroupID)
    
    EXEC [dbo].[Aff_WriteLog]
            @Creator=@UserID,    
            @AffID=0,
            @Typename= 'UserControl',    
            @SPName=@SPName ,        
            @IP =@IP,
            @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_GroupInfoDel]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_GroupInfoDel    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_GroupInfoDel]
    @GroupID int,
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT ,
    @UserID int,
    @IP varchar(15) = ''
AS
/*DB03.BODB02 --> DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
If @ErrCode <> 0
    RETURN
--end

IF exists (select 1 from AdminUser with (NOLOCK) where GroupID = @GroupID) 
BEGIN
    Select @ErrMsg =     case @Language 
                    when 'en-US' then N' This group has customer belong to, so you cannot delete!'
                    when 'zh-CN' then N' This group has customer belong to, so you cannot delete!'
                    else N' This group has customer belong to, so you can not delete!'
            end, @ErrCode = 102
    return
END    
    
DELETE FROM AffGroupPolicy where GroupID=@GroupID
DELETE FROM AffGroupInfo where GroupID=@GroupID


    --Write log
    DECLARE @SPName varchar(50), @LogData nvarchar(200)
    select @SPName = OBJECT_NAME(@@ProcID)

    SELECT @LogData = '[AFFILIATE] Delete GroupID:' + dbo.Aff_ToString(@groupid)

    
    EXEC [dbo].[Aff_WriteLog]
            @Creator=@UserID,    
            @AffID=0,
            @Typename= 'UserControl',    
            @SPName=@SPName ,        
            @IP =@IP,
            @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminPolicyUpd]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminPolicyUpd    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_AdminPolicyUpd]
    @MemPolicys NVARCHAR(4000),
    @UserID int, 
    @Language varchar(5)= 'en-US', 
    @IP varchar(15) = '',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
--DB03.bodb02 --> DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
-- Update Acc_GroupPolicy
-- Format of @MemPolicys @CustID,@FuncID,@Policy;@CustID,@FuncID,@Policy; ...;
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
    RETURN
--end



DECLARE @MemPolicy nvarchar(4000)
DECLARE @CustID INT
DECLARE @FuncID INT
DECLARE @Policy int
DECLARE @CustPolicyCount int 
DECLARE CustPolicysCur CURSOR FOR 
    SELECT val as row_index 
      FROM dbo.strSplit(@MemPolicys, ';')
     ORDER BY row_index     


OPEN CustPolicysCur
FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
WHILE @@FETCH_STATUS = 0
BEGIN

    SET @CustID = dbo.Aff_SplitIndex(@MemPolicy, ',', 1)
    SET @FuncID = dbo.Aff_SplitIndex(@MemPolicy, ',', 2)
    SET    @Policy = dbo.Aff_SplitIndex(@MemPolicy, ',', 3)
    SET @CustPolicyCount = (SELECT COUNT(1) FROM AffMemberPolicy with (nolock) WHERE CustID = @CustID AND funcid = @FuncID)

    IF(@CustPolicyCount = 0)
        BEGIN
            INSERT INTO AffMemberPolicy 
                (CustID, Funcid, Policy, Createdate, Modifydate, Creator)
            Values
                (@CustID, @Funcid, @Policy, CURRENT_TIMESTAMP,CURRENT_TIMESTAMP, @UserID)
        END
    ELSE
        BEGIN
            UPDATE AffMemberPolicy
               SET policy = @Policy,
                 modifydate = CURRENT_TIMESTAMP
             WHERE CustID = @CustID
               AND funcid = @FuncID
        END
    
    DECLARE @SPName varchar(50), @LogData nvarchar(200)
    select @SPName = OBJECT_NAME(@@ProcID)

    SELECT @LogData = '[AFFILIATE]' + ' UPDATE (multiple) Policy = ' + dbo.Aff_ToString(@Policy) + ' of Function ' + dbo.Aff_ToString(@Funcid) +  ' for Admin ' + dbo.Aff_ToString(@CustID)


    EXEC [dbo].[Aff_WriteLog]
            @Creator=@UserID,    
            @AffID=@CustID,
            @Typename= 'UserControl',    
            @SPName=@SPName ,        
            @IP =@IP,
            @Details=@LogData    
        

    FETCH NEXT FROM CustPolicysCur INTO @MemPolicy
END 
CLOSE CustPolicysCur
DEALLOCATE CustPolicysCur
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerInsType]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerInsType    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE PROCEDURE [dbo].[Aff_BannerInsType]
    @TypeName varchar(50),
    @Value varchar(50) ,
    @UserID int,
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
--DB: DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission] 
    @custid=@UserID,@funcname='[Media]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------

IF Exists(Select 1 From BannerTypes with(nolock) Where Type=@TypeName and Value=@Value)
BEGIN
    select @ErrMsg = case @Language 
                        when 'en-US' then N'Value  already exist'
                        when 'zh-TW' then N'數值已存在。'
                        when 'zh-CN' then N'数值已存在。'
                        else N'Value  already exist'
                    end,@ErrCode=1001
    return
END
ELSE
BEGIN
    Declare @MaxOrder int
    Select @MaxOrder=max(displayorder) From BannerTypes with(nolock) where Type=@TypeName
    INSERT INTO BannerTypes(type,value,displayorder)values(@typename,@value,@maxorder+1)
    IF @@Error <> 0 
    BEGIN
        Select @Errcode=1002, @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Insert unsuccessfully.'
                        when 'zh-CN' then N'錯誤發生.插入不成功'
                        when 'zh-TW' then N'错误发生。插入不成功'
                        else N'Error occurs.Insert unsuccessfully.!'
                    end
        return
    END 
    Select @Errcode=0
END

--
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create ' + dbo.Aff_ToString(@TypeName) +' value: '+ dbo.Aff_ToString(@Value)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Banner', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerIns]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerIns    Script Date: 7/29/2013 1:41:11 AM ******/

CREATE PROCEDURE [dbo].[Aff_BannerIns]
    @BannerID int OUTPUT,
    @Content nvarchar(4000),    
    @Category smallint,
    @ImageType smallint, 
    @Currency smallint,
    @Size varchar(50)=NULL,
    @BannerType tinyint =1, /*0: Text, 1: Normal banner, 2: Media banner */
    @UserID int,    
    @IP nvarchar(15)='',
    @Language varchar(8)='en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Add a new Banner
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:

• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Unsuccessful deleting msg.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,
    @funcname='[Media]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp
if @Size = ''  
    set @Size = null

if(@Size Is Not NULL AND @BannerType >=1 and not exists(select 1 from BannerTypes (nolock) where Type='Size' and Value=@Size))
Begin
        Insert into  BannerTypes (type,value,Displayorder) values('Size',@Size,1)        
end

declare @SizeID smallint
if(@BannerType >=1)
begin
  select @SizeID=TypeID from BannerTypes (nolock) where Type='Size' and Value=@Size  
end


BEGIN TRANSACTION

INSERT INTO Banners
    (    
        [Content], 
        Category,
        [Language],
        ImageType,
        [Size],
        Currency,
        [Type],
        [LastUpdate],
        CreatedDate,
        UpdatedBy,        
        Creator,
        Version
    )
    VALUES
    (           
        @Content,        
        @Category,
        @Language,
        @ImageType,
        @SizeID,
        @Currency,
        @BannerType,        
        @CreatedDate,        
        @CreatedDate,
        @UserID,
        @UserID,
        1 
    )
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrCode = 1002
            , @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Insert unsuccessfully.'
                        when 'zh-CN' then N'錯誤發生.插入不成功'
                        when 'zh-TW' then N'错误发生。插入不成功'
                        else N'Error occurs.Insert unsuccessfully.!'
                    end
    return
END

SELECT @BannerID = @@IDENTITY

--Generate filename
--Ex: @FileName = BonusEnglishImage125x125.jpg ,@BannerID=8 => @FileName=BonusEnglishImage125x125/8.jpg
--SELECT @FileName=substring(@FileName,1,len(rtrim(@FileName))-4)+'/'+convert(varchar(20),@BannerID)+'.'+right(rtrim(@filename),3)
COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create bannerID:' + dbo.Aff_ToString(@BannerID) 
                    + ' Content:' + dbo.Aff_ToString(@Content)
                    + ' Category:' + dbo.Aff_ToString(@Category)
                    + ' Language:' + dbo.Aff_ToString(@Language)
                    + ' ImageType:' + dbo.Aff_ToString(@ImageType)
                    + ' Currency:' + dbo.Aff_ToString(@Currency)         
                    + ' Size:' + dbo.Aff_ToString(@Size)        
                    + ' Banner Type:' + dbo.Aff_ToString(@BannerType)  

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Banner', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerDelType]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerDelType    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE PROCEDURE [dbo].[Aff_BannerDelType]
    @TypeName varchar(50),
    @Value varchar(50) ,
    @UserID int,
    @IP nvarchar(15)='',
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 
DB: DB052.Affiliate_ZZun
Original:

Revisions:
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Media]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------


Delete From BannerTypes Where Type=@TypeName and Value=@Value
IF @@Error <> 0 
BEGIN
    Select @ErrMsg =     case @Language 
                    when 'en-US' then N'Error occurs.Delete unsuccessfully.'
                    when 'zh-TW' then N'出現錯誤，刪除失敗.'
                    when 'zh-CN' then N'出现错误，删除失败.'
                    else N'Error occurs.Delete unsuccessfully.'
                end,@Errcode=1001
    return
END 
    Select @Errcode=0

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete ' + dbo.Aff_ToString(@TypeName) +' value: '+ dbo.Aff_ToString(@Value)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Banner', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerDel]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerDel    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE PROCEDURE [dbo].[Aff_BannerDel]
    @ListBannerID varchar(4000)=null,
    @UserID int,    
    @IP nvarchar(15)='',
    @Language varchar(5)= 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task : Delete affiliate Banners by list of ids
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
• @ListBannerID : list of banner ids need to delete separated by a comma
• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Unsuccessful deleting msg.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Media]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
--Check list of bannerID
if(@ListBannerID is null)
begin
    Select @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Banner ID!' 
                            when 'zh-CN' then N'無效的廣告ID!'
                            when 'zh-TW' then N'无效的广告ID！'
                            else N'Invalid Banner ID!' 
                        end, @ErrCode = 101    
    return
end    

declare @bannerIDTable table(bannerid int)

insert into @bannerIDTable
select distinct val from dbo.strsplit(@ListBannerID,',')
inner join banners b with (nolock) on b.bannerid = val and COALESCE(b.totalrequest,0) = 0 

declare @count int,@countDB int
select @count=count(1) from  @bannerIDTable
select @countDB=count(1)
from Banners a (nolock)
    inner join  @bannerIDTable t on a.BannerID=t.bannerid
    
    if (@count <> @countDB)
        BEGIN
             Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, your input banner id is invalid. Please recheck it again.' 
                            when 'zh-CN' then N'抱歉,您輸入的廣告ID是無效的.請重新確認.'
                            when 'zh-TW' then N'抱歉，您输入的广告ID是无效的，请重新确认。'
                            else N'Sorry, your input banner id is invalid. Please recheck it again.' 
                        end
                    , @ErrCode = 102
            return      
        END    
--Check UserID is valid
if(not exists(select 1 from AdminUser (nolock) where custid=@UserID))
begin
     Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, Admin id is invalid. Please recheck it again.' 
                            when 'zh-CN' then N'抱歉, 管理員ID是無效的.請重新確認.'
                            when 'zh-TW' then N'抱歉，管理员ID是无效的，请重新确认。'
                            else N'Sorry, Admin id is invalid. Please recheck it again.' 
                        end,                                 
                    @ErrCode = 103
            return
end

Delete Banners with(rowlock)
WHERE BannerID in (select bannerid from  @bannerIDTable)

IF @@ERROR <> 0
BEGIN
    
    Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Banner unsuccessfully deleted!' 
                            when 'zh-CN' then N'錯誤!廣告刪除不成功'
                            when 'zh-TW' then N'错误！广告删除不成功'
                            else N'Error! Banner unsuccessfully deleted!' 
                        end, @ErrCode = 1001
    return
END

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Banners BannerIDList:' + dbo.Aff_ToString(@ListBannerID)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Banner', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeUpd]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffTypeUpd    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_AffTypeUpd]
    @Updatedby int ,
    @ID tinyint,
    @Name nvarchar(50),    
    @Description nvarchar(100)=NULL,            
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Product
DB: DB052.Affiliate_MYM
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from AffType (nolock) where TypeID=@ID ))
BEGIN
Select @ErrMsg = N'Error! This type does not exist!', @ErrCode = 1001
    return
END
update AffType with (rowlock,updlock)
Set Name=@Name, [Description]=@Description
where TypeID=@ID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update afftype. ID= ' + dbo.Aff_ToString(@ID) 
     

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'AffType', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeIns]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffTypeIns    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_AffTypeIns]
    @Updatedby int ,    
    @Name nvarchar(50),    
    @Description nvarchar(100)=NULL,        
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : Insert AffType
DB: DB052.Affiliate_MYM
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

INSERT INTO [Affiliate_MYM].[dbo].[AffType]
           (
           [Name]
           ,[Description]
           ,[Creator]
           ,[CreatedDate]
           )
     VALUES
           (
           @Name
           ,@Description
           ,@Updatedby
           ,CURRENT_TIMESTAMP
           )


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New AffType. Name= ' + dbo.Aff_ToString(@Name)
     

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'AffType', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffTypeDel]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffTypeDel    Script Date: 7/29/2013 1:41:11 AM ******/
CREATE Procedure [dbo].[Aff_AffTypeDel]
    @Updatedby int ,
    @IDList varchar(max),
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:


Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

delete [dbo].[AffType]
where TypeID in (select val from dbo.strsplit(@IDList, ',') )

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete AffType. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'AffType', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffInfo_UpdAffType]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffInfo_UpdAffType    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE PROCEDURE [dbo].[Aff_AffInfo_UpdAffType]
    @Updatedby int ,
    @AffID int,
    @AffType tinyint,        
    @IP nvarchar(15)='',    
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 

SET NOCOUNT ON

EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@Updatedby,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from AffInfo (nolock) where AffID=@AffID ))
BEGIN
Select @ErrMsg = case @Language 
                when 'en-US' then 'Error! This affiliate does not exist!'
                when 'zh-CN' then N'錯誤!這個工作夥伴不存在!'
                when 'zh-TW' then N'错误！这个工作伙伴不存在！'
                else N'Error! This affiliate does not exist!'
            end, @ErrCode = 1001
    return
END
update AffInfo with (rowlock,updlock)
Set AffType=@AffType
where AffID=@AffID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update AffInfo AffType. AffID= ' + dbo.Aff_ToString(@AffID) 
                +'AffType= ' + dbo.Aff_ToString(@AffType) 
     

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'AffInfo', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateUpdStatus]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateUpdStatus    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE PROCEDURE [dbo].[Aff_AffiliateUpdStatus]  
 @AffID int,  
 @UserID int,  
 @Status varchar(30),   
 @Password varchar(40)= NULL,    
 @GroupID int=NULL,   
 @IP varchar(20),   
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*Created: 20090825@Peter  
Task : Update affiliate status from disapproved->pending , disapproved-> approved,pending-->disapproved,pending-->approved  
DB: DB052.Affiliate_ZZun  
Original : [Aff_CustomerUpdStatus]  
Revisions:  
  
Param's Explanation:  
• @AffID : Affiliate ID  
• @userid : User update  
• @Status : Update status  
• @Password: Make a password for affiliate when approving  
• @GroupID: when approving user need to assign a new grooup  
            groupid<1000 : a common group  
            groupid>1000: a private group for this affiliate must be created before. This sp will be called from sp Aff_CommGroupIns  
                 
• @ErrCode  
• @ErrMsg  
*/  
SET NOCOUNT ON  
--Check permission-----------------------------  
EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
  
Declare @Email nvarchar(50)  
  
select @Email = Email from AffInfo with (nolock) where affid=@affid  
  
if( Exists(select 1 from AffInfo with (nolock) where affid<>@affid and Email = @Email and Status in ('approved','pending')) and @Status in ('approved','pending'))  
Begin  
 SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Email Address has been used. Please choose another one!'
                            when 'zh-CN' then N'電子郵件地址已經被使用.請選擇另一個!'
                            when 'zh-TW' then N'电子邮件地址已经被使用，请选择另一个！'
                            else N'Email Address has been used. Please choose another one!'
                        end
                , @ErrCode = 1007  
 return  
End  
  
  
if(not exists(select 1 from AffInfo with (nolock) where affid=@affid))  
begin  
 SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Affiliate!'
                            when 'zh-CN' then N'無效的工作夥伴!'
                            when 'zh-TW' then N'无效的工作伙伴！'
                            else N'Invalid Affiliate!'
                        end, @ErrCode = 1005  
   return  
end  
-----------------------------------------------  
if(@Status not in ('approved','disapproved','pending'))  
begin   
 SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid status!'
                            when 'zh-CN' then N'無效的狀態!'
                            when 'zh-TW' then N'无效的状态！'
                            else N'Invalid Affiliate!'
                        end, @ErrCode = 1006  
  return  
end  
  
  
if @Status= 'approved' --from disapproved,pending-->approved  
 Begin  
  IF Exists(Select 1  
                  From AffInfo ai with(nolock)   
                  where ai.email=(select email from AffInfo with (nolock) where affid=@affid)  
                        and ai.affid <> @affid and lower(ai.Status)='approved')  
  BEGIN  
   SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Email Address has been used. Please choose another one!'
                            when 'zh-CN' then N'電子郵件地址已經被使用.請選擇另一個!'
                            when 'zh-TW' then N'电子邮件地址已经被使用，请选择另一个！'
                            else N'Email Address has been used. Please choose another one!'
                        end, @ErrCode = 1007  
   return  
  END   
    if(not exists(select 1 from CommGroup with (nolock) where groupid=@groupid and IsDeleted=0))  
  BEGIN  
   SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid group!'
                            when 'zh-CN' then N'無效的群組!'
                            when 'zh-TW' then N'无效的群组！'
                            else N'Invalid group!'
                        end
            , @ErrCode = 1008  
   return  
  END    
  --Check Currency is valid  
  declare @Currency varchar(5)  
  Select @Currency =currency  
  from AffINfo (nolock)  
  where AffID=@AffID  
  
  
  if(not exists (Select 1 from CommGroup with (nolock) where groupid=@groupid and Currency=@Currency) )  
  begin  
   SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Currency does not match with the selected group. Please check!'
                            when 'zh-CN' then N'貨幣和所選擇的群組不相配.請確認!'
                            when 'zh-TW' then N'货币和所选择的群组不相配。请确认！'
                            else N'Currency does not match with the selected group. Please check!'
                        end
            , @ErrCode = 1009  
   return  
  end  
End  
  
Declare @GroupName nvarchar(100)  
  
Select @GroupName = GroupName from commgroup nolock where GroupId = @GroupID  
  
BEGIN TRANSACTION   
UPDATE AffInfo with(rowlock,updlock)   
SET [Password] = isnull(@Password,[Password]),  
 [Status]=@Status,  
 GroupID=isnull(@GroupID,GroupID),  
 ApprovedDate=(case when @Status in ('approved','disapproved') then current_timestamp else null end),  
 AffType = (case when @GroupName = 'Media' then 2 else AffType end)  
WHERE affid = @affid  
IF @@Error <> 0   
begin  
 SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.'
                        end
        , @ErrCode = 1008  
 ROLLBACK TRANSACTION  
 return  
end  
  
COMMIT TRANSACTION  
  
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
  
SELECT @LogData = 'Update Affiliate''s Status. '  
                  + 'Status=' + dbo.Aff_ToString(@Status)  
                  + '. Password=' + dbo.Aff_ToString(@Password)  
                  + '. GroupID=' + dbo.Aff_ToString(@GroupID)    
select @SPName=OBJECT_NAME(@@ProcID)  
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateUpdPwd]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateUpdPwd    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateUpdPwd]
    @AffID int,
    @OldPwd nvarchar(50)=null,
    @AffPwd nvarchar(50),
    @UserID int = null,
    @IP varchar(20),
    @Language varchar(20) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 200908230@DungTong
    Task : Admin Reset Password for Affiliate or Affiliate change password
    DB: DB052.Affiliate_MYM

    Revisions:
      - 20090930@VinhTrinh: Admin Change Affiliate Password
    Param's Explanation:
    • 
*/

SET NOCOUNT ON

--Check permission-----------------------------
if @OldPwd is null
BEGIN
    EXEC [dbo].[Aff_Con_CheckPermission] 
        @custid=@UserID,
        @funcname='[Affiliate]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output
        
    If @ErrCode <> 0
        RETURN
END
-----------------------------------------------
if not exists(select 1 from AffInfo with (NOLOCK) 
                where AffID = @AffID
                and (case when (@OldPwd is not null and Password = @OldPwd) or @OldPwd is null then 1 
                        else 0 end ) = 1 )
BEGIN
    Select @ErrMsg =  case @Language 
            when 'en-US' then N'Old password is incorrect' 
            when 'zh-TW' then N'舊密碼不正確.' 
            when 'zh-CN' then N'旧密码不正确' 
            when 'th-TH' then N'Old password is incorrect' 
            when 'es-ES' then N'La contraseña antigua es incorrecta' 
            when 'vi-VN' then N'Mật khẩu cũ không đúng'    
            when 'id-ID' then N'Kata sandi lama salah'
            else N'Old password is incorrect'
        end,
    @ErrCode = 1001
    RETURN 
END


UPDATE AffInfo  with (ROWLOCK, UPDLOCK)
SET Password=@Affpwd
where AffID=@AffID

declare @SPName varchar(50), @LogData nvarchar(200)
Select @LogData = 'Reset password'
select @SPName = OBJECT_NAME(@@ProcID)
select @UserID = isnull(@UserID, @AffID)

EXEC [dbo].[Aff_WriteLog]
    @Creator = @UserID,
    @AffID = @AffID,
    @Typename = 'Password', -- refer to table LogType
    @SPName = @SPName,
    @Details = @LogData,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateUpdInfo]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateUpdInfo    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE PROCEDURE [dbo].[Aff_AffiliateUpdInfo]  
 @AffId int ,  
 @userid int,  
 @firstname nvarchar(50) = NULL,  
 @lastname nvarchar(50) = NULL,  
 @Gender bit = null,  
 @country nvarchar(50) = NULL,  
 @email nvarchar(50) = NULL,  
 @password varchar(40)=NULL,  
 @phone nvarchar(50) = NULL,  
 @mobilephone nvarchar(50) = NULL,  
 @address nvarchar(80),  
 @city nvarchar(50) = NULL,   
 @state nvarchar(50) = NULL,  
 @postal nvarchar(50) = NULL,  
 @emailformat bit = null,  
 @currency smallint = null,  
 @playerCurrency nvarchar(50) = null,  
     --Add for Personalized Site  
    @IsPageEnabled bit=0,  
    @Level int=0,    
 ---------------------------------------------------------------------------------  
 -- Parameter for Affiliate info(use for update/insert data to DB03)  
 @SiteURL varchar(100)=NULL,  
 @MoreSiteURLs varchar(1000) = NULL,  
 @PreferredLanguage varchar(11)=NULL,  
 @PreferredPayment varchar(20), --Player, Neteller, Moneybookers, Wire, Cheque  
 @Player_Username varchar(30) = NULL,  
 @Neteller_AccountID varchar(50) = NULL,  
 @Moneybookers_Email varchar(50) = NULL,  
 @Wire_BankName  nvarchar(100) = NULL,  
 @Wire_BankAddress nvarchar(200) = NULL,  
 @Wire_SwiftCode  nvarchar(20) = NULL,  
 @Wire_AccountName nvarchar(100) = NULL,   
 @Wire_AccountNo  varchar(50) = NULL,  
 @Cheque_FullName nvarchar(200) = NULL,  
 @Cheque_Address  nvarchar(200) = NULL,  
 @Cheque_City  nvarchar(50) = NULL,  
 @Cheque_State  nvarchar(50) = NULL,  
 @Cheque_Postal  nvarchar(50) = NULL,  
 @Cheque_Country  varchar(50) = NULL,  
 ---------------------------------------------------------------------------------  
 @language varchar(20) = 'es-ES',  
    @IP varchar(20),  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*Updated: 20090324@VinhTrinh  
Task : Update affiliate infor.  
DB: DB052.Affiliate_ZZun  
Original : [Aff_AffiliateUpdInfo]  
Revisions:  
 Peter@20100209 : Check If Admin update Player_UserName, we must make sure there is no pending payment request.  
 Johnny@20110228 : Do not allow affiliate update player_user if they have already  
 Johnny@20130319 : Do not allow update currency  
 Long@20130911: do not check email existance in case of Kiosk
Param's Explanation:  
• @AffId : Affiliate custid  
• @userid : user update.  
• @firstname : update firstname.  
....  
*/  
  
SET NOCOUNT ON  
  
--Check permission(If AffId = userid => Affiliate update info else Admin Update Aff info)-----------------------------  
if @AffId <> @userid  
Begin  
 EXEC [dbo].[Aff_Con_CheckPermission]   
  @custid=@UserID,@funcname='[Affiliate]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output  
   
 If @ErrCode <> 0  
  RETURN  
End  
  
--Check If we change player_username  
  
if (@Player_Username Is not null AND @Player_Username <> (Select Player_UserName from AffDetail with (nolock) where AffId=@AffID)  
     and exists (Select 1 from AffPayout with (nolock) where AffID=@AffID and Status='pending')   
    )  
      
 BEGIN  
    SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'zh-TW' then N'这个帐号有一笔付款要求还在等待，请先更新这笔交易！'  
      when 'zh-CN' then N'這個帳號有一筆付款要求還在等待,請先更新這筆交易!'  
      when 'th-TH' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'es-ES' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'vi-VN' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      when 'id-ID' then N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      else N'Oops, this account is having 1 pending pay out request , please update this transaction first!'  
      end, @ErrCode = 1001  
    return  
      
 END     
-----------------------------------------------  
  
  
--Check duplicate Email 
IF (select at.Name
	from afftype at with(nolock)
		inner join affinfo ai with(nolock) on ai.AffType = at.TypeID
		where ai.AffID = @AffId) not like '%kiosk%'
BEGIN 
	IF Exists(Select 1 From AffInfo a with(nolock) where a.email=@email and a.AffId <> @AffId and a.Status <> 'Disapproved')
	BEGIN
		SELECT @ErrMsg = case @Language 
							when 'en-US' then 'Email Address has been used. Please choose another one!'
							when 'zh-TW' then N'此郵箱地址已被使用，請選用其他郵箱地址。'
							when 'zh-CN' then N'此邮箱地址已被使用，请选用其他邮箱地址。'
							when 'th-TH' then N'อีเมลล์นี้ได้ถูกใช้แล้ว กรุณาระบุข้อมูลใหม่คะ!'
							when 'es-ES' then N'Esta dirección de correo electrónico ya se ha utilizado. Escoja otra diferente.'
							when 'vi-VN' then N'Địa chỉ Email đã được sử dụng. Vui lòng chọn địa chỉ khác!'
							when 'id-ID' then N'Alamat Email sudah digunakan. Silakan pilih yang berbeda!'
							else N'Email Address has been used. Please choose another one!'
							end, @ErrCode = 1002
		return
	END	
END
/*  
-- Check Currency is Editable  
declare @CurrencyCurrent smallint  
Select @CurrencyCurrent =currency  
from AffINfo (nolock)  
where AffID=@AffID  
  
  
if(@Currency<>@CurrencyCurrent and exists (select top(1)  1 from Memberdaily (nolock) where AffID = @AffID))  
begin  
 SELECT @ErrMsg = case @Language   
      when 'en-US' then 'Cannot change the currency of this Affiliate!'  
      when 'zh-TW' then N'Cannot change the currency of this Affiliate!'  
      when 'zh-CN' then N'Cannot change the currency of this Affiliate!'  
      when 'th-TH' then N'Cannot change the currency of this Affiliate!'  
      when 'es-ES' then N'Cannot change the currency of this Affiliate!'  
      when 'vi-VN' then N'Cannot change the currency of this Affiliate!'  
      when 'id-ID' then N'Cannot change the currency of this Affiliate!'  
      else N'Cannot change the currency of this Affiliate!'  
      end, @ErrCode = 1003  
 return  
end  
*/  
Begin Transaction  
  
UPDATE AffInfo with(rowlock,updlock)   
SET firstname = isnull(@firstname,firstname),  
 lastname = isnull(@lastname,lastname),  
 email = isnull(@email,email),  
 Password = isnull(@password,Password),  
 IsPageEnabled = isnull(@IsPageEnabled,IsPageEnabled),  
 [Level] = isnull(@Level,[Level])  
 ,Currency=(case when status in ('Pending','Disapproved') then  isnull(@currency,currency) else currency end)  
   
WHERE AffId = @AffId  
  
IF @@error<>0   
BEGIN  
 SELECT @ErrMsg = CASE @Language   
      WHEN 'es-ES' THEN 'Invalid user infomation. Update process is unsuccessful!'  
      WHEN 'zh-TW' THEN N'用戶信息無效，更新失敗。'  
      WHEN 'zh-CN' THEN N'用户信息无效，更新失败。'  
      WHEN 'J' THEN N'Invalid user infomation. Update process is unsuccessful!'  
      WHEN 'th-TH' THEN N'ข้อมูลผู้ใช้ไม่ถุกต้อง อัพเดทข้อมูลไม่สำเร็จคะ!'  
      WHEN 'es-ES' THEN N'La información de usuario no es válida. No se ha podido completar el proceso de actualización.'        
      WHEN 'vi-VN' THEN N'Thông tin người dùng không hợp lệ. Quá trình cập nhật không thành công!'  
      WHEN 'id-ID' THEN N'Informasi pengguna tidak valid. Proses pembaruan tidak berhasil!'        
      ELSE N'Invalid user infomation. Update process is unsuccessful!'  
     END, @ErrCode = 1004        
 RollBack Transaction  
 RETURN  
END  
  
  
UPDATE AffDetail  with(rowlock,updlock)   
SET    
 Gender = isnull(@Gender,Gender),  
 CountryID = isnull(@country, countryID),  
 phone = isnull(@phone,phone),  
 mobilephone = isnull(@mobilephone,mobilephone),  
 address = isnull(@address,address),  
 city = isnull(@city,city),  
 state = isnull(@state,state),  
 postal = isnull(@postal,postal),  
 SiteURL=isnull(@SiteURL,SiteURL),    
 MoreSiteURLs=@MoreSiteURLs,    
 PreferredLanguage = isnull(@PreferredLanguage, PreferredLanguage),  
 PreferredPayment=@PreferredPayment,   
 --Player_IBCCustID=@Player_IBCCustId,   
 Player_Username=case when @AffId <> @UserId then @Player_Username else isnull(Player_Username, @Player_Username) end,    
 Player_Currency = @playerCurrency,  
 Neteller_AccountID=@Neteller_AccountID,    
 Moneybookers_Email=@Moneybookers_Email,    
 Wire_BankName=@Wire_BankName,    
 Wire_BankAddress=@Wire_BankAddress,    
 Wire_SwiftCode=@Wire_SwiftCode,    
 Wire_AccountName=@Wire_AccountName,    
 Wire_AccountNo=@Wire_AccountNo,    
 Cheque_FullName=@Cheque_FullName,    
 Cheque_Address=@Cheque_Address,    
 Cheque_City=@Cheque_City,    
 Cheque_State=@Cheque_State,    
 Cheque_Postal=@Cheque_Postal,    
 Cheque_Country=@Cheque_Country ,  
 MailOption = @EmailFormat   
where AffId = @AffId  
  
IF @@Error <> 0  
BEGIN   
 SELECT @ErrMsg = CASE @Language   
      WHEN 'es-ES' THEN 'Error occurs. Update process is unsuccessful!'  
       WHEN 'zh-TW' THEN N'出現錯誤，更新程序失敗。'  
       WHEN 'zh-CN' THEN N'出现错误，更新程序失败。'  
       WHEN 'J' THEN N'Error occurs. Update process is unsuccessful!'  
       WHEN 'th-TH' THEN N'มีความผิดพลาดเกิดขึ้น อัพเดทข้อมูลไม่สำเร็จคะ!'  
       WHEN 'es-ES' THEN N'Se ha producido un error. No se ha podido completar el proceso de actualización.'  
       WHEN 'vi-VN' THEN N'Xảy ra lỗi. Quá trình cập nhật không thành công!'  
       WHEN 'id-ID' THEN N'Terjadi kesalahan. Proses pembaruan tidak berhasil!'  
       ELSE N'Error occurs. Update process is unsuccessful!'  
     END, @ErrCode = 1006  
 Rollback Transaction  
 RETURN  
END  
Commit Transaction  
  
--Update succeeded  
  
declare @SPName varchar(50), @Detail nvarchar(4000)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
Select @Detail = 'Update Affifilate''s Info   
firstname='+ dbo.Aff_ToString(@firstname) + ',  
lastname='+ dbo.Aff_ToString(@lastname) + ',  
Gender='+ dbo.Aff_ToString(@Gender) + ',  
country='+ dbo.Aff_ToString(@country) + ',  
email='+ dbo.Aff_ToString(@email) + ',  
password='+ dbo.Aff_ToString(@password) + ',  
phone='+ dbo.Aff_ToString(@phone) + ',  
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',  
address='+ dbo.Aff_ToString(@address) + ',  
city='+ dbo.Aff_ToString(@city) + ',  
state='+ dbo.Aff_ToString(@state) + ',  
postal='+ dbo.Aff_ToString(@postal) + ',  
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',  
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',  
PreferredPayment='+ dbo.Aff_ToString(@PreferredPayment) + ',  
PreferredLanguage='+ dbo.Aff_ToString(@PreferredLanguage) + ',  
Player_Username='+ dbo.Aff_ToString(@Player_Username) + ',  
Player_Currency='+ @playerCurrency + ',  
Neteller_AccountID='+ dbo.Aff_ToString(@Neteller_AccountID) + ',  
Moneybookers_Email='+ dbo.Aff_ToString(@Moneybookers_Email) + ',  
Wire_BankName='+ dbo.Aff_ToString(@Wire_BankName) + ',  
Wire_BankAddress='+ dbo.Aff_ToString(@Wire_BankAddress) + ',  
Wire_SwiftCode='+ dbo.Aff_ToString(@Wire_SwiftCode) + ',  
Wire_AccountName='+ dbo.Aff_ToString(@Wire_AccountName) + ',  
Wire_AccountNo='+ dbo.Aff_ToString(@Wire_AccountNo) + ',  
Cheque_FullName='+ dbo.Aff_ToString(@Cheque_FullName) + ',  
Cheque_Address='+ dbo.Aff_ToString(@Cheque_Address) + ',  
Cheque_City='+ dbo.Aff_ToString(@Cheque_City) + ',  
Cheque_State='+ dbo.Aff_ToString(@Cheque_State) + ',  
Cheque_Postal='+ dbo.Aff_ToString(@Cheque_Postal) + ',  
Cheque_Country='+ dbo.Aff_ToString(@Cheque_Country) + ',  
IsPageEnabled='+ dbo.Aff_ToString(@IsPageEnabled) + ',  
Level='+ dbo.Aff_ToString(@Level) + ',  
Currency'+ dbo.Aff_ToString(@Currency) + ',  
language='+ dbo.Aff_ToString(@language)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@Detail   
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerUpdType]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerUpdType    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE PROCEDURE [dbo].[Aff_BannerUpdType]
    @TypeName varchar(50),
    @DisplayOrder tinyint,
    @Value varchar(50) ,
    @UserID int,
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
SET NOCOUNT ON
--DB052.Affiliate_ZZun
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission] 
    @custid=@UserID,@funcname='[Media]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------

IF Exists(Select 1 From BannerType with(nolock) Where Type=@TypeName and Value=@Value and displayorder<>@displayorder)
BEGIN
    select @ErrMsg = case @Language 
                when 'en-US' then 'Value  already exist'
                when 'zh-CN' then N'數值已存在。'
                when 'zh-TW' then N'数值已存在。'
                else N'Value  already exist'
            end,@ErrCode=1001
    return
END
ELSE
BEGIN
    Update BannerType with(rowlock,updlock) set value=@value
    Where type=@TypeName and DisplayOrder=@DisplayOrder
    IF @@Error <> 0 
    BEGIN
        Select @ErrMsg = case @Language 
                when 'en-US' then 'Error occurs.Update unsuccessfully.'
                when 'zh-CN' then N'出現錯誤，更新失敗'
                when 'zh-TW' then N'出现错误，更新失败'
                else N'Error occurs.Update unsuccessfully.'
            end,@ErrCode=1002
        return
    END 
    Select @ErrCode=0
END

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update ' + dbo.Aff_ToString(@TypeName)+' value: '+dbo.Aff_ToString(@Value)
EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Banner', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail
GO
/****** Object:  StoredProcedure [dbo].[Aff_BannerUpd]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_BannerUpd    Script Date: 7/29/2013 1:41:12 AM ******/


CREATE Procedure [dbo].[Aff_BannerUpd]
    @BannerID int ,
    @Content nvarchar(4000)=null,
    @Category smallint=null,
    @Language varchar(8)='en-US',
    @ImageType smallint=null,
    @Size varchar(50)=null,
    @Currency smallint=null,
    @BannerType tinyint,
    @UserID int,    
    @IP nvarchar(15)='',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090331@DungTong
Task :Update affiliate Banners
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:

• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Unsuccessful deleting msg.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission] 
    @custid=@UserID,@funcname='[Media]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
if @Size = ''
    set @Size = null
if(@Size is not null and @BannerType >=1 and not exists(select 1 from BannerTypes (nolock) where Type='Size' and Value=@Size))
Begin
        Insert into  BannerTypes (type,value,Displayorder) values('Size',@Size,1)        
end

declare @SizeID smallint
if(@BannerType >=1)
begin
  select @SizeID=TypeID from BannerTypes (nolock) where Type='Size' and Value=@Size  
end


UPDATE Banners with(rowlock,updlock)
SET     
    LastUpdate = getdate(),
    UpdatedBy=@UserID,
    [Content]=coalesce(@Content,Content),
    Category=coalesce(@Category,Category),
    Language=coalesce(@Language,Language),
    ImageType=coalesce(@ImageType,ImageType),
    Size=coalesce(@SizeID,Size),
    Currency=coalesce(@Currency,Currency),
    Type=coalesce(@BannerType,Type)
WHERE BannerID=@BannerID
IF @@Error <> 0 
BEGIN
    Select @ErrMsg = N'Error occurs.Update unsuccessfully.', @Errcode=1001
    return
END 
    Select @Errcode=0

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update bannerID:' + dbo.Aff_ToString(@BannerID) 
                  +  ' Content:' + dbo.Aff_ToString(@Content)
                  +  ' Category:' + dbo.Aff_ToString(@Category)
                  +  ' Language:' + dbo.Aff_ToString(@Language)
                  +  ' ImageType:' + dbo.Aff_ToString(@ImageType)
                  +  ' Size:' + dbo.Aff_ToString(@Size)
                  +  ' Currency:' + dbo.Aff_ToString(@Currency)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Banner', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateUnlockMultiple]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateUnlockMultiple    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateUnlockMultiple]  
 @UserId int,   
 @AffIDList varchar(max),      
 @IP varchar(20),  
    @Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT,  
 @RefNo bigint = null OUTPUT  
AS  
/*  
Created: 20090719@DungTong  
Task : Unlock/Lock for multiple Affilites   
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID   
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
 @custid=@UserID,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
if(@ErrMsg<>'')  
  return  
  
  
--Check AffIDList  
/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/  
declare @NoAff int  
BEGIN TRY  
    select @NoAff=sum(1)  
 from AffInfo with(nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
   and status='approved' -- and IsClosed=0  
      
 if(@NoAff<> (select sum(1) from dbo.strsplit(@AffIDList, ',')))  
 begin  
  select @ErrCode=102,@ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Affiliate List. Please check.'
                            when 'zh-CN' then N'無效的工作夥伴名單.請確認.'
                            when 'zh-TW' then N'无效的工作伙伴名单，请确认。'
                            else N'Invalid Affiliate List. Please check.'
                        end       
  return  
 end   
  
ENd TRY  
BEGIN CATCH  
 select @ErrCode=103,@ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Affiliate List. Please check.'
                            when 'zh-CN' then N'無效的工作夥伴名單.請確認.'
                            when 'zh-TW' then N'无效的工作伙伴名单，请确认。'
                            else N'Invalid Affiliate List. Please check.'
                        end       
    return  
END CATCH  
  
update AffInfo with (rowlock,updlock)  
set IsLocked=~isnull(IsLocked,0)  
where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
UPDATE AffDetail with (rowlock, updlock)  
SET logincount = 0  
WHERE AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ','))  
  
 --Write the log   
DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
    
SELECT @LogData = N'Lock/Unlock Affiliate.AffIDList=' + isnull(@AffIDList,' ')     
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=0,  
 @Typename= 'Affiliate',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @RefNo = @RefNo OUTPUT,   
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminGroupUpd]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminGroupUpd    Script Date: 7/29/2013 1:41:12 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_AdminGroupUpd    Script Date: 7/11/2009 1:17:56 PM ******/
CREATE PROCEDURE  [dbo].[Aff_Con_AdminGroupUpd]
    @CustID int,
    @UserID int,
    @GroupID int,
    @IP varchar(15) = '',
    @Language varchar(5)= 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*called by sp Aff_Con_AdminUpd */
/*DB03.bodb02*/--->/*DB052.Affiliate_ZZun*/

/*
    -- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
*/

SET NOCOUNT ON
Begin
IF EXISTS(SELECT 1 FROM AffGroupInfo with(nolock) where groupid=@groupid)
    BEGIN 
        IF EXISTS(SELECT 1 FROM AdminUser ac with(nolock) WHERE custid=@custid and groupid <> @groupID) 
        BEGIN
            BEGIN TRANSACTION
                UPDATE AdminUser with (ROWLOCK, UPDLOCK) SET groupid=@groupid WHERE custid = @custid                            
            COMMIT TRANSACTION
            
            DECLARE @SPName varchar(50), @LogData nvarchar(200)
            select @SPName = OBJECT_NAME(@@ProcID)

            SELECT @LogData = 'Update Group for Admin custid:' + dbo.Aff_ToString(@custid) + ' GroupID:' + dbo.Aff_ToString(@GroupID)
            
            EXEC [dbo].[Aff_WriteLog]
                    @Creator=@UserID,    
                    @AffID=@CustID,
                    @Typename= 'UserControl',    
                    @SPName=@SPName ,        
                    @IP =@IP,
                    @Details=@LogData    
        
        END
    END
    ELSE
    BEGIN
        SELECT @ErrMsg =  case @Language
                            when 'en-US' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
                            when 'zh-CN' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
                            when 'J' then N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
                            else N'This groupid '+convert(varchar(20),@groupid) +' is invalid.'
                        end, @ErrCode = 103
        return 
    END


End
GO
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupUpd]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupUpd    Script Date: 7/29/2013 1:41:12 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupUpd]  
 @UserId int,  
 @GroupId int,  
 @Currency varchar(5),  
 @QualifiedAmount money,  
 @GroupName nvarchar(100),  
 @Description nvarchar(100),  
 @ProductIDList varchar(MAX),  
 @DeductionList varchar(MAX),  
 @DeductedPercentageList varchar(MAX),  
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
if(@ErrMsg<>'')  
  return  
if (not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
  select @ErrCode=101,
        @ErrMsg = case @Language 
                            when 'en-US' then 'The group ID ' +  cast(@GroupId as varchar(10)) + ' is not existed. Please check.' 
                            when 'zh-CN' then N'這個群組ID ' +  cast(@GroupId as varchar(10)) + '已經不再存在.請確認.'
                            when 'zh-TW' then N'这个群组ID ' +  cast(@GroupId as varchar(10)) + '已经不再存在。请确认。'
                            else N'The group ID ' +  cast(@GroupId as varchar(10)) + ' is not existed. Please check.' 
                        end        
    return  
  end  
  
if(@GroupName is null or LTRIM(RTRIM(@GroupName))='')  
  begin  
 select @ErrCode = 10030, 
        @ErrMsg = case @Language 
                            when 'en-US' then 'Group name is empty. Please choose a name!' 
                            when 'zh-CN' then N'群組名稱是空白.請選擇一個名稱!'
                            when 'zh-TW' then N'群组名称是空白。请选择一个名称！'
                            else N'Group name is empty. Please choose a name!' 
                        end    
 return  
 end  
  
   
if (@GroupID<1000 and exists (select 1 from CommGroup where GroupID<>@GroupID and  GroupName = @GroupName  and IsDeleted=0))  
begin  
 select @ErrCode = 10031, 
        @ErrMsg = case @Language 
                            when 'en-US' then 'Group name existed. Please choose another name!' 
                            when 'zh-CN' then N'群組名稱已經存在.請選擇另一個名稱!'
                            when 'zh-TW' then N'群组名称已经存在，请选择另一个名称！'
                            else N'Group name existed. Please choose another name!' 
                        end    
 return  
end  
  
--Check Currency Is different -> do not allow to update when have an Affiliate Assign to this group  
  
if(Exists (select 1 from CommGroup (nolock) where GroupID=@GroupID and currency<>@Currency)   
 and (Exists(select top(1) 1 from AffCommission(nolock) where GroupID=@GroupID)   
  or Exists(select top(1) 1 from AffInfo ai (nolock) where ai.GroupID=@GroupID)   
  )  
)  
  
begin  
 select @ErrCode = 10091, 
        @ErrMsg = case @Language 
                            when 'en-US' then 'The group has been used. Cannot change the currency. Please check!' 
                            when 'zh-CN' then N'這個群組已經被使用.無法改變貨幣.請確認!'
                            when 'zh-TW' then N'这个群组已经被使用，无法改变货币。请确认！'
                            else N'The group has been used. Cannot change the currency. Please check!' 
                        end    
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
    
  Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Deduction Setting!' 
                            when 'zh-CN' then N'錯誤!無效的扣除設定!'
                            when 'zh-TW' then N'错误！无效的扣除设定！'
                            else N'Error! Invalid Deduction Setting!' 
                        end    
            , @ErrCode = 10032  
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
         Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Tier List!' 
                            when 'zh-CN' then N'錯誤!無效的一線層名單!'
                            when 'zh-TW' then N'错误！无效的一线层名单！'
                            else N'Error! Invalid Tier List!' 
                        end    
                    , @ErrCode = 10035  
         return  
         end  
         if(@NTier>50)  
          begin  
             ROLLBACK TRANSACTION  
          Select @ErrMsg = case @Language 
                            when 'en-US' then 'Oops, maximum of 50 tiers are allowed!' 
                            when 'zh-CN' then N'允許最多50層'
                            when 'zh-TW' then N'允许最多50层'
                            else N'Oops, maximum of 50 tiers are allowed!' 
                        end, @ErrCode = 10085  
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
           Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when inserting tier setting.' 
                            when 'zh-CN' then N'當設定層級時,出現錯誤.'
                            when 'zh-TW' then N'当设定层级时，出现错误。'
                            else N'There was an error when inserting tier setting.' 
                        end, @ErrCode = 10037  
           return    
        end    
           end  
         else  
           begin          
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Setting Data(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                            when 'zh-CN' then N'誤!無效的資料設定(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                            when 'zh-TW' then N'错误！无效的资料设定(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                            else N'Error! Invalid Setting Data(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                        end
                        , @ErrCode = 10037  
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
 Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Setting Data (ProductIDList) !' 
                            when 'zh-CN' then N'錯誤!無效的資料設定 (ProductIDList) !' 
                            when 'zh-TW' then N'错误！无效的资料设定 (ProductIDList) !' 
                            else N'Error! Invalid Setting Data (ProductIDList) !' 
                        end, @ErrCode = 10033  
 return   
  end      
  
--Checking again  
 if (not exists (select 1 from @GroupSetting))  
    begin  
       Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Setting Data!' 
                            when 'zh-CN' then N'錯誤!無效的資料設定 !' 
                            when 'zh-TW' then N'错误！无效的资料设定 !' 
                            else N'Error! Invalid Setting Data !' 
                        end, @ErrCode = 10039  
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
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 10040  
     return   
   end  
     
         
    delete DeductionSetting where GroupID=@GroupID  
      
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 10041  
     return   
   end  
          
    insert into DeductionSetting(GroupID,DeductionID,DeductedPercentage)  
    select GroupID,DeductionID,DeductedPercentage from @DeductionSetting  
  
    if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 10042  
     return   
   end   
     
   delete GroupSetting where GroupID=@GroupID  
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 10043  
     return   
   end  
   Insert into GroupSetting(GroupID,ProductID,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)  
   select GroupID,ProductID,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission  
   from @GroupSetting  
     
   if(@@ERROR <> 0 or @@ROWCOUNT<> (select count(1) from @GroupSetting))  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 10044  
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
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupDel]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupDel    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupDel]  
 @UserId int,  
 @GroupId int,  
 @IP varchar(20),  
 @Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT   
AS  
/*  
Created: 20090719@DungTong  
Task : Delete a Commission Group   
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
*/  
SET NOCOUNT ON  
--Check permission  
EXEC [dbo].[Aff_Con_CheckPermission]  
 @custid=@UserID,@funcname='[CommissionGroup]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
if(@ErrMsg<>'')  
  return  
if (not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
   select @ErrCode=101,
        @ErrMsg = case @Language 
                            when 'en-US' then 'The group ID=' +  cast(@GroupId as varchar(10)) + ' is no longer existed. Please check.'
                            when 'zh-CN' then N'這個群組ID ' +  cast(@GroupId as varchar(10)) + '已經不再存在.請確認.'
                            when 'zh-TW' then N'这个群组ID ' +  cast(@GroupId as varchar(10)) + '已经不再存在。请确认。'
                            else N'The group ID=' +  cast(@GroupId as varchar(10)) + ' is no longer existed. Please check.'
                        end
    return  
  end  
--Check this group has 0 of affilliate assigment   
declare @noOfAff int  
select @noOfAff=sum(1)  
from AffInfo i with (nolock) where i.GroupID=@GroupID  
  
if(@noOfAff>0)    
  begin  
    select @ErrCode=101,
            @ErrMsg = case @Language 
                            when 'en-US' then 'At least 1 affiliate was assigned to this group. You cannot delete it.'
                            when 'zh-CN' then N'至少一個工作夥伴被安排到這個群組.您無法刪除.'
                            when 'zh-TW' then N'至少一个工作伙伴被安排到这个群组。您无法删除。'
                            else N'At least 1 affiliate was assigned to this group. You cannot delete it.'
                        end
    return  
  end  
    
  
update CommGroup with (rowlock, updlock)  
set isDeleted = 1  
where GroupId = @GroupId  
--Write the log   
DECLARE @LogData nvarchar(200), @AffID int,@SPName varchar(100)  
if (@GroupID>1000)  
  select @AffID=@GroupID  
else  
  select @AffID=0    
SELECT @LogData = 'Delete commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'CommissionGroup',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupAssign]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupAssign    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupAssign]  
 @UserId int,  
 @GroupId int,  
 @AffIDList nvarchar(4000),      
 @IP varchar(20),  
    @Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT,  
 @RefNo bigint = null OUTPUT  
AS  
/*  
Created: 20090719@DungTong  
Task : Assign a commission group (GroupID<1000) for multiple Affilites   
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID separated by semi colon.Maximum of 200 AffIDs are assiged each time                  
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
*/  
Declare @AffId int  
  
select @AffId = AffID  
from (select top 1 cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';')) tmp  
  
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
  
   
if(@ErrMsg<>'')  
  return  
  
if (@GroupID>1000 or  not exists (select 1 from CommGroup(nolock) where GroupID=@GroupID and IsDeleted=0))  
  begin  
   select @ErrCode=101,
            @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Group. Please check.'
                            when 'zh-CN' then N'無效的群組.請確認.'
                            when 'zh-TW' then N'无效的群组请确认。'
                            else N'Invalid Group. Please check.'
                        end
    return  
  end  
  
  
--Check AffIDList  
/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/  
declare @NoAff int, @CountCurrency int  
BEGIN TRY  
    select @NoAff=sum(1)  
 from AffInfo with(nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';'))  
   and status='approved' -- and IsClosed=0  
      
 if(@NoAff<> (select sum(1) from dbo.strsplit(@AffIDList, ';')))  
 begin  
  select @ErrCode=102,
        @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Affiliate List. Please check.'
                            when 'zh-CN' then N'無效的工作夥伴名單.請確認.'
                            when 'zh-TW' then N'无效的工作伙伴名单，请确认。'
                            else N'Invalid Affiliate List. Please check.'
                        end
  return  
 end   
  
 --Check Currency of Group and Currency of Match   
 Set @CountCurrency=0  
 Select @CountCurrency=count(distinct currency)  
 from AffInfo (nolock)  
 where AffID in (select cast(val as int) as AffID from dbo.strsplit(@AffIDList, ';'))  
    
 if(isnull(@CountCurrency,0) > 1)  
 begin  
  Select @ErrCode=104,
        @ErrMsg = case @Language 
                            when 'en-US' then 'Currency of the group does not match with affiliate''s currency. Please check.'
                            when 'zh-CN' then N'貨幣的群組與工作夥伴的群組不相配.請確認.'
                            when 'zh-TW' then N'货币的群组与工作伙伴的群组不相配。请确认。'
                            else N'Currency of the group does not match with affiliate''s currency. Please check.'
                        end
                        
  return  
 end  
  
ENd TRY  
BEGIN CATCH  
 select @ErrCode=103,@ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Affiliate List. Please check.'
                            when 'zh-CN' then N'無效的工作夥伴名單.請確認.'
                            when 'zh-TW' then N'无效的工作伙伴名单，请确认。'
                            else N'Invalid Affiliate List. Please check.'
                        end    
    return  
END CATCH  
  
  
--BEGIN TRANSACTION AFTER CHECKING VALID INPUT DATA  
BEGIN TRANSACTION    
  --Delete GroupID>1000 where GroupID in AffiliateID list and already assigned before  
  Delete DeductionSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end   
                        , @ErrCode = 105  
     return   
   end  
     
  Delete GroupSetting  
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                      and AffID=GroupID  
    )   
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 106  
     return   
   end   
    
  Delete CommGroup     
  where GroupID in (  
               select GroupID  
               from AffInfo (nolock)  
               where AffID in (select cast(val as int) from dbo.strsplit(@AffIDList, ';'))         
                       and AffID=GroupID  
    )   
        
  
  if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 107  
     return   
   end  
  
  Update AffInfo with (rowlock,updlock)  
  set GroupID=@GroupID        
  where AffID in (select cast(val as int)  as AffID from dbo.strsplit(@AffIDList, ';'))         
     
   if(@@ERROR <> 0)  
   begin  
        ROLLBACK TRANSACTION  
        Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when updating data.Please try again!'
                            when 'zh-CN' then N'當在更新資料時,會有錯誤.請重新再試一次!'
                            when 'zh-TW' then N'当在更新资料时，会有错误，请重新再试一次！'
                            else N'There was an error when updating data.Please try again!'
                        end, @ErrCode = 108  
     return   
   end  
          
commit transaction  
 --Write the log   
DECLARE @LogData nvarchar(4000), @SPName varchar(100)  
if ((select count(1) from dbo.strsplit(@AffIDList, ';'))=1)  
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
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoUpd]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoUpd    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_FuncInfoUpd]
    @FuncId int,
    @FuncName nvarchar(50),
    @FuncNote nvarchar(2000) = null,
    @FuncDesc nvarchar(50) = '',
    @FileNames nvarchar(2000),    
    @Language varchar(5)= 'en-US',
    @IP varchar(15) = '',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT,
    @UserId int
AS
/*DB03.BODB02-->DB052.Affiliate_ZZun */
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
    --Check permission
    EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
    If @ErrCode <> 0
        RETURN
    IF exists (select 1 from AffFunctionInfo with (NOLOCK) where system ='AFFILIATE' and FuncName = @FuncName and FuncId <> @FuncId)
    BEGIN
        Select @ErrMsg =     case @Language 
                            when 'en-US' then N'This function name is already used.'
                            when 'zh-CN' then N'This function name is already used.'
                            else N'This function name is already used.'
                    end, @ErrCode = 101    
        return
    END 
        
    update AffFunctionInfo with (rowlock)
    set FuncName = @FuncName, FuncNote = @FuncNote, FuncDesc = @FuncDesc, ModifyDate = getdate(), FileNames = @FileNames
    where FuncID = @FuncId
    
    --Write log
    DECLARE @SPName varchar(50), @LogData nvarchar(200)
    select @SPName = OBJECT_NAME(@@ProcID)

    SELECT @LogData = '[AFFILIATE] Update functioninfo:' + dbo.Aff_ToString(@FuncId)    
    
    
    EXEC [dbo].[Aff_WriteLog]
            @Creator=@UserID,    
            @AffID=0,
            @Typename= 'UserControl',    
            @SPName=@SPName ,        
            @IP =@IP,
            @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoIns]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoIns    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_FuncInfoIns]
    @FuncId int output,
    @FuncName nvarchar(50),
    @FuncNote nvarchar(2000) = null,
    @FuncDesc nvarchar(50) = '',
    @DisplayOrder int = 1,
    @ParentId int = null,
    @FileNames nvarchar(2000),
    @IP varchar(15) = '',
    @Language varchar(5)= 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT,
    @UserID int 
AS
/*DB03.BODB02-->DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
    --Check permission for account site
    EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output, @System = 'AFFILIATE'
    If @ErrCode <> 0
        RETURN
    --end
    --Check funcname
    if exists (select 1 from AffFunctionInfo with (nolock) where System = 'AFFILIATE' and FuncName = @FuncName)
        begin
            Select @ErrMsg =     case @Language 
                    when 'en-US' then N'This function name is already used.'
                    when 'zh-CN' then N'This function name is already used.'
                    when 'zh-TW' then N'This function name is already used.'
                    else N'This function name is already used.'
            end, @ErrCode = 102
            return
        end
    if @ParentId is not null
        begin
            if not exists (select 1 from AffFunctionInfo with (nolock) where FuncId = @ParentId and FuncId = ParentId)
            begin
                Select @ErrMsg =     case @Language 
                    when 'en-US' then N'Parent function does not exist or is invalid.'
                    when 'zh-CN' then N'Parent function does not exist or is invalid.'
                    when 'zh-TW' then N'Parent function does not exist or is invalid.'
                    else N'Parent function does not exist or is invalid.'
                end, @ErrCode = 102
                return
            end
        end
        
    BEGIN TRANSACTION
        if @ParentId is not null
            select @DisplayOrder = max(DisplayOrder)+1 from AffFunctionInfo with (nolock) where ParentID = @ParentId
        else
            select @DisplayOrder = 1

        insert into AffFunctionInfo(FuncName, FuncNote, FuncDesc, FuncRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentId, FileNames, System)
        values (@FuncName, @FuncNote, @FuncDesc, 3, getdate(), getdate(), @DisplayOrder, @UserId, isnull(@ParentId, ident_current('AffFunctionInfo')), @FileNames,'AFFILIATE')    


        
        select @FuncId = @@IDENTITY
        --Insert data to acc_grouppolicy table
        if @ParentId is not null
            begin            
                --Insert into AffGroupPolicy and AccCustomer
                insert into AffGroupPolicy(FuncId, GroupId, Policy, CreateDate, ModifyDate, Creator)
                select @FuncId, GroupId, Policy, getdate(), getdate(), @UserId
                from AffGroupPolicy with (nolock)
                where FuncId = @ParentId
                --add list custid is used on parentid
                insert into AffMemberPolicy(CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
                select custid, @FuncId, policy, getdate(), getdate(), @UserID
                from AffMemberPolicy with (nolock)
                where funcId = @ParentId
            end
        else
            begin
                insert into AffGroupPolicy(FuncId, GroupId, Policy, CreateDate, ModifyDate, Creator)
                Select @FuncId, GroupId, 0, getdate(), getdate(), @UserId
                from AffGroupInfo grp with (nolock)
                where System = 'AFFILIATE'            
                
                insert into AffMemberPolicy(CustId, FuncId, Policy, CreateDate, ModifyDate, Creator)
                            select custid, @FuncId, 0, getdate(), getdate(), @UserID
                            from AdminUser with (nolock)
                

            end
        
    IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        select @ErrMsg = case @Language 
                            when 'en-US' then 'Add function failed.'
                            when 'zh-CN' then N'Add function failed.'
                            when 'zh-TW' then N'Add function failed.'
                            when 'J' then N'Add function failed.'
                            else N'Add function failed.'
                        end, @ErrCode = 103
        return
    END
    COMMIT TRANSACTION
    
    --Write log data
    DECLARE @SPName varchar(50), @LogData nvarchar(200)
    select @SPName = OBJECT_NAME(@@ProcID)

    SELECT @LogData = '[AFFILIATE] add functioninfo:' + dbo.Aff_ToString(@FuncId)    
    
    
    EXEC [dbo].[Aff_WriteLog]
            @Creator=@UserID,    
            @AffID=0,
            @Typename= 'UserControl',    
            @SPName=@SPName ,        
            @IP =@IP,
            @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_FuncInfoDel]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_FuncInfoDel    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_FuncInfoDel]
    @FuncID int,
    @Language varchar(5)= 'en-US', 
    @IP varchar(15) = '',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT ,
    @UserID int
AS
/*DB03.BODB02 --> DB052.Affiliate_ZZun*/
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
    RETURN
--end

if exists (select 1 from AffFunctionInfo with (nolock) where ParentId = @FuncId and ParentId <> FuncId)
BEGIN
    Select @ErrMsg =     case @Language 
                    when 'en-US' then N'Error occurs. This function has sub function belong to, so you can not delete!'
                    when 'zh-CN' then N'Error occurs. This function has sub function belong to, so you can not delete!'
                    else N'Error occurs. This function has sub function belong to, so you can not delete!'
            end, @ErrCode = 102
    return
END
BEGIN TRANSACTION
    DELETE FROM AffGroupPolicy where FuncId=@FuncId
    DELETE FROM AffMemberPolicy where FuncId=@FuncId
    DELETE FROM AffFunctionInfo where FuncId=@FuncId
    IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRANSACTION
            select @ErrMsg = case @Language 
                        when 'en-US' then 'Delete function failed.'
                        when 'zh-CN' then N'Delete function failed.'
                        when 'J' then N'Delete function failed.'
                        else N'Delete function failed.'
                    end, @ErrCode = 103
            return
        END
COMMIT TRANSACTION
    
DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = '[AFFILIATE] Delete FunctionID:' + dbo.Aff_ToString(@FuncId)


EXEC [dbo].[Aff_WriteLog]
        @Creator=@UserID,    
        @AffID=0,
        @Typename= 'UserControl',    
        @SPName=@SPName ,        
        @IP =@IP,
        @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminPolicyIns]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminPolicyIns    Script Date: 7/29/2013 1:41:13 AM ******/
/****** Object:  Stored Procedure dbo.Aff_Con_AdminPolicyIns    Script Date: 7/11/2009 1:17:56 PM ******/
CREATE Procedure  [dbo].[Aff_Con_AdminPolicyIns]
    @CustID int, 
    @UserID int,
    @GroupID int,
    @IP varchar(15) = ''    
AS
/*
called by sp Aff_Con_AdminIns
DB03.bodb02 --> DB052.Affiliate_MYM
Revisions:
    - VinhTrinh@20100507: insert closed field to table AdminUser
    - 20100713@Peter : Remove Write Log on IBC DB
    -- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
*/
SET NOCOUNT ON


INSERT INTO AffMemberPolicy(CustID,FuncID,Policy,CreateDate,ModifyDate,Creator) 
    SELECT @Custid as custid,FuncID,
        -- 0 is default value of the member policy  when create new admin
        0 as Policy, getdate() as Createdate, getdate() as ModifyDate,@UserID as Creator 
    FROM AffGroupPolicy with(nolock)
    WHERE GroupId=@GroupID

DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Insert Admin policy custid:' + dbo.Aff_ToString(@custid) + ' GroupID:' + dbo.Aff_ToString(@GroupID)


EXEC [dbo].[Aff_WriteLog]
        @Creator=@UserID,    
        @AffID=@CustID,
        @Typename= 'UserControl',    
        @SPName=@SPName ,        
        @IP =@IP,
        @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_TextDel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TextDel    Script Date: 7/29/2013 1:41:13 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextDel_xpre    Script Date: 4/3/2012 3:07:15 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextDel    Script Date: 2/24/2012 10:17:35 AM ******/

CREATE Procedure [dbo].[Aff_TextDel]
    @ListBannerID varchar(4000)=null,
    @UserID int,    
    @IP nvarchar(15)='',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Media]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
--Check list of bannerID
if(@ListBannerID is null)
begin
    Select @ErrMsg = 'Invalid Banner ID!', @ErrCode = 101    
    return
end    

declare @bannerIDTable table(bannerid int)

insert into @bannerIDTable
select distinct val from dbo.strsplit(@ListBannerID,',')

declare @count int,@countDB int
select @count=count(1) from  @bannerIDTable
select @countDB=count(1)
from Banners a (nolock)
    inner join  @bannerIDTable t on a.BannerID=t.bannerid
    
    if (@count <> @countDB)
        BEGIN
             Select @ErrMsg ='Sorry, your input banner id is invalid. Please recheck it again.',                                 
                    @ErrCode = 102
            return      
        END    
--Check UserID is valid
if(not exists(select 1 from dbo.AdminUser (nolock) where custid=@UserID))
begin
     Select @ErrMsg ='Sorry, Admin id is invalid. Please recheck it again.',                                 
                    @ErrCode = 103
            return
end

Delete Banners with(rowlock)
WHERE BannerID in (select bannerid from  @bannerIDTable)

IF @@ERROR <> 0
BEGIN
    
    Select @ErrMsg = N'Error! Banner unsuccessfully deleted!', @ErrCode = 1001
    return
END

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Banners BannerIDList:' + dbo.Aff_ToString(@ListBannerID)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'Banner', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductDel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductDel    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_ProductDel]
    @Updatedby int ,
    @IDList varchar(max),
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:


Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

delete [dbo].[Product]
where ProductID in (select val from dbo.strsplit(@IDList, ',') )

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Product. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Product', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_PreferLangUpd]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PreferLangUpd    Script Date: 7/29/2013 1:41:13 AM ******/
CREATE Procedure [dbo].[Aff_PreferLangUpd]  
 @affid int,  
 @userid int,  
 @PreferredLanguage varchar(5),    
 @IP varchar(20),  
 @Language varchar(5) = 'en-US',    
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
  
/*Created: 20090822@Peter  
Task : [description of SP]  
DB: DB052.Affiliate_ZZun  
Original : [Aff_PreferLangUpd]  
Revision:s  
  
Param's Explanation:  
• @custid : Affiliate custid  
• @userid : User update  
• @PreferredLanguage : Preferred language update.  
*/  
SET NOCOUNT ON  
/*EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,  
 @funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output*/  
   
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
   
if(not exists(select 1 from AffInfo(nolock) where affid=@affid))  
begin  
         SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Affiliate!'
                            when 'zh-CN' then N'無效的工作夥伴!'
                            when 'zh-TW' then N'无效的工作伙伴！'
                            else N'Invalid Affiliate!'
                        end, @ErrCode = 1005  
   return  
end  
   
Update AffDetail with(rowlock,updlock)  
set PreferredLanguage = @PreferredLanguage  
where affid = @affid  
  
IF @@error<>0   
Begin  
 SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Error occurs. Update process is unsuccessful!'
                            when 'zh-CN' then N'出現錯誤.更新過程不成功!'
                            when 'zh-TW' then N'出现错误。更新过程不成功！'
                            else N'Error occurs. Update process is unsuccessful!'
                        end, @ErrCode = 1005  
 RETURN  
END  
  
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
SELECT @LogData = 'Update Affiliate''s Prefered Languague. '  
                  + 'PreferredLanguage=' +  dbo.Aff_ToString(@PreferredLanguage)  
  
select @SPName=OBJECT_NAME(@@ProcID)  
   
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_PaymentRequestUpd]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PaymentRequestUpd    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_PaymentRequestUpd]   
    @TransID bigint,   
    @Status nvarchar(50),  
    @AdminDesc nvarchar(300) = null,  
    @AffDesc nvarchar(300) = null,  
    @PreferredLanguage varchar(20)='en-US' OUTPUT,  
    @MailOption bit = 0 OUTPUT,  
    @UserID int,   
    @IP varchar(15) = '',  
    @RefNo bigint=0,  
    @language varchar(20) = 'en-US',  
    @IbcRefNo bigint = 0,  
    @IbcTransId bigint = 0,  
    @IBCUsername varchar(50) = '',  
    @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
-- DB: DB052.Affiliate_MYM  
/*  
Creator : Peter@20090910  
Task : Update Payment status ('Approved','Rejected','Cancelled')  
  
Input   
    1) @AffId (For Double check)   
    2) @RefID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )  
    3) @Status Status of transaction  
    3) @AdminDesc Description for this payment from Admin  
    4) @AffDesc Description visible for Affiliate  
    5) @userid ID of Admin update this payment  
    6) @IP IP update payment  
     
Revisions:  
  
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
• @ErrMsg: Error description.  
*/  
  
  
--Check whether this is pending payment request   
SET NOCOUNT ON  
Declare @AffID int, @RefID bigint , @TransType int  
Select @TransType = 202  
Select @AffID=AffID,@RefID=RefID  
from AffTrans (nolock)  
where TransID=@TransID and TransType= @TransType and Status='pending'  
  
if(@AffID is null or @RefID is null)  
BEGIN  
           Select @ErrMsg = case @language   
        when 'en-US' then 'This transaction is not a withdrawal.'   
        when 'zh-TW' then N'此次交易不是提款操作。'  
        when 'zh-CN' then N'此次交易不是提款操作。'  
        when 'th-TH' then N'รายการที่แจ้งไม่ใช่รายการถอน คะ'   
        when 'es-ES' then N'La transacción no es una retirada de fondos.'   
        when 'vi-VN' then N'Giao dịch này không phải là giao dịch rút tiền.'   
        when 'id-ID' then N'Transaksi ini bukan penarikan dana.'   
        else  N'This transaction is not a withdrawal.'     
       end,   
   @ErrCode = 4001  
 return  
END  
  
/*Check Condition to excute this sp  
  + From Affiliate Site : @UserID=@AffID and  @Status='Cancelled'  
  + From AffAdmin Site: @UserID<> @AffID and Status in ('Approved','Rejected')   
*/  
if( @UserID<>@AffID)  
BEGIN  
 --Check permission-----------------------------  
 EXEC [dbo].[Aff_Con_CheckPermission]  
  @custid=@UserID,@funcname='[Payment]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output    
 If @ErrCode <> 0  
  RETURN  
     if(@Status not in ('Approved','Rejected'))  
  BEGIN  
       Select @ErrMsg = case @language   
          when 'en-US' then 'Oops, You do not have permission to update this transaction.'  
          when 'zh-TW' then N'Oops, You do not have permission to update this transaction.'  
          when 'zh-CN' then N'Oops, You do not have permission to update this transaction.'  
          else  N'Oops, You do not have permission to update this transaction.'     
         end,   
     @ErrCode = 4003  
   return  
  END  
END  
  
if(@UserID=@AffID and  @Status<>'Cancelled')  
BEGIN  
           Select @ErrMsg = case @language   
        when 'en-US' then 'Oops, You do not have permission to update this transaction.'  
        when 'zh-TW' then N'Oops, You do not have permission to update this transaction.'  
        when 'zh-CN' then N'Oops, You do not have permission to update this transaction.'  
        else  N'Oops, You do not have permission to update this transaction.'     
       end,   
   @ErrCode = 4002  
 return  
END  
  
  
  
BEGIN TRANSACTION  
BEGIN TRY  
    declare @CompletedDate datetime  
     Select @PreferredLanguage=PreferredLanguage  
   , @MailOption = MailOption  
     from AffDetail (nolock)  
     where AffID=@AffID   
       
    Select @CompletedDate=current_timestamp  
    Update  AffPayout with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        AdminDesc=isnull(@AdminDesc,AdminDesc),  
        AffDesc=isnull(@AffDesc,AffDesc),  
      IbcRefNo = @IbcRefNo,  
      IbcTransId = @IbcTransId
      ,IBCUsername = (case when isnull(IBCUsername, '') = '' then @IBCUsername else IBCUsername end)  
    where RefID=@RefID and AffID=@AffID  
      
    Update  AffTrans with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        Creator=@UserID  
    where TransID=@TransID and AffID=@AffID       
END TRY  
  
BEGIN CATCH  
 rollback transaction   
    Select @ErrMsg = case @language   
       when 'en-US' then 'Insert transaction failed.'   
       when 'zh-TW' then N'插入交易失敗'  
       when 'zh-CN' then N'插入交易失败'  
       when 'th-TH' then N'ระบุรายการเลขที่ไม่ถูกต้อง คะ'   
       when 'es-ES' then N'No se ha podido completar la transacción.'   
       when 'vi-VN' then N'Chèn giao dịch không thành công.'   
       when 'id-ID' then N'Gagal menyisipkan transaksi.'   
       else  N'Insert transaction failed.'     
      end,  
  @ErrCode = 4004  
 return  
    RETURN  
END CATCH  
  
COMMIT TRANSACTION   
  
  
declare @SPName varchar(50), @LogData nvarchar(4000)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
Select @LogData =  'Update status for payout Request. TransID = ' + dbo.Aff_ToString(@TransID) + '. Status = ' + dbo.Aff_ToString(@Status)  
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserID,   
 @AffID=@AffID,  
 @Typename= 'Payout',   
 @SPName=@SPName ,  
 @RefNo=@RefNo,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_PaymentRequestIns]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_PaymentRequestIns    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE PROCEDURE [dbo].[Aff_PaymentRequestIns]  
	@AffID int,  
	@Player_UserName varchar(30), 	
	@Player_IBCUserName varchar(30), 	
	@Player_Currency varchar(5),	
	@Amount money,   
	@IP varchar(20),   
	@language varchar(20) = 'en-US',  
	@PreferredLanguage varchar(5)='en-US' OUTPUT,  
	@TransDate datetime=null OUTPUT,  
	@TransID bigint =0 OUTPUT,  
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
begin  
/*  
Created: 20130314@Johnny  
Task : Insert an payment request from Affiliate  
DB: DB052.Affiliate_ZZun  
Original:   
  
Revisions:  
	- 20130805@Don: Fixed bug "User able request an invalid amount which is lager than Balance Brought Forward"
  
Param's Explanation:  
.@AffID: Affiliate id,  
.@Amount : Amount to withdraw  
.@IP: ip of computer sent,  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert unsuccessful.  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
Declare @TransType int  
select @TransType=202  
--Checking Affiliate ID  
if(not exists (select 1 from AffInfo (nolock) where affid=@AffID and Status='approved' and IsClosed=0 ))  
 begin  
 Select @ErrMsg = case @language   
        when 'en-US' then 'Oops, Your account is not existed or closed. Please contact administrator.'   
        when 'zh-TW' then N'Oops, Your account is not existed or closed. Please contact administrator.'  
        when 'zh-CN' then N'Oops, Your account is not existed or closed. Please contact administrator.'  
        when 'th-TH' then N'Oops, Your account is not existed or closed. Please contact administrator.'   
        when 'es-ES' then N'Oops, Your account is not existed or closed. Please contact administrator.'   
        when 'vi-VN' then N'Oops, Your account is not existed or closed. Please contact administrator.'   
        else  N'Oops, Your account is not existed or closed. Please contact administrator.'      
       end,   
   @ErrCode = 3001  
      return   
 end  
--Checking Amount  
if(@Amount<=0)  
begin  
  Select @ErrMsg = case @language   
        when 'en-US' then 'Sorry, amount is invalid.'   
        when 'zh-TW' then N'????,?????'  
        when 'zh-CN' then N'????,?????'  
        when 'th-TH' then N'?????? ???????????????????.'   
        when 'es-ES' then N'La cantidad no es válida.'   
        when 'vi-VN' then N'Xin l?i, s? ti?n không h?p l?.'   
        when 'id-ID' then N'Maaf, jumlah tidak valid.'   
        else  N'Sorry, amount is invalid.'      
       end,   
   @ErrCode = 3002  
          return  
end  
-- Checking whether this account has a pending request.  
if Exists(Select 1 from AffPayout with(nolock) where AffID = @AffID and status = 'Pending')  
Begin  
 Select @ErrMsg = case @language   
        when 'en-US' then 'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'  
        when 'zh-TW' then N'???????“?????”,????????,??????????????,????????????'  
        when 'zh-CN' then N'???????“?????”,????????,??????????????,????????????'  
        when 'th-TH' then N'?????????????????????????????? ???????????????????????????? ???????????????????????????????????????????.'  
        when 'es-ES' then N'Tiene una solicitud pendiente. Para crear una nueva solicitud, debe cancelar la que tiene pendiente o esperar hasta que se haya procesado.'  
        when 'vi-VN' then N'B?n có m?t yêu c?u dang ch? x? lý. Ð? t?o m?t yêu c?u m?i, hãy h?y yêu c?u dang ch? x? lý ho?c d?i cho d?n khi yêu c?u dó du?c x? lý.'  
        when 'id-ID' then N'Ada permintaan Anda yang tertunda. Agar dapat membuat permintaan baru, harap batalkan permintaan yang tertunda, atau tunggu sampai permintaan sudah diproses.'  
        else  N'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'     
       end,   
 @ErrCode = 3003  
 return  
End  
  
--Checking Balance Brought Forward  
DECLARE @AffBalance money
SET @AffBalance = dbo.Aff_GetAffBalance(@AffID)
if((@AffBalance<=0) OR (@Amount > @AffBalance))
begin  
   Select @ErrMsg = case @language   
        when 'en-US' then 'Sorry, this Affiliate does not have enough money to withdraw.'  
        when 'zh-TW' then N'????,???????????????'  
        when 'zh-CN' then N'????,???????????????'  
        when 'th-TH' then N'?????? ????????????????????????????????????????????????.'  
        when 'es-ES' then N'El saldo del afiliado es insuficiente, por lo que no puede retirar fondos.'  
        when 'vi-VN' then N'Xin l?i, H?i viên này không có d? ti?n d? rút.'  
        when 'id-ID' then N'Maaf, Afiliasi ini tidak mempunyai cukup uang untuk ditarik.'  
        else  N'Sorry, this Affiliate does not have enough money to withdraw.'  
       end,   
      @ErrCode = 3004      
  return    
end  
  
--Get all related info and Check Preferred Payment  
declare @PreferredPayment varchar(20),@AffCurrencyID smallint, @AffCurrency varchar(5), @Member_ExRate float  

Select  @PreferredPayment= PreferredPayment, @PreferredLanguage=PreferredLanguage  
from AffDetail (nolock)  
where AffID=@AffID   
   
 IF @PreferredPayment <> 'Player' --Just support transfer to player account  
 BEGIN  
  Select @ErrMSg = case @language   
         when 'en-US' then 'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
         when 'zh-TW' then N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
         when 'zh-CN' then N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
         when 'th-TH' then N'??????! ?????????????? [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] ?????????????????? ??????????????????????????????????? '+ ''' ???????????? '+ ''' ?????????? ???????????????????????????????????'  
         when 'es-ES' then N'Lo sentimos. El método de pago [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] no está disponible. En este momento, el único método de pago válido es mediante la cuenta de jugador. Haga clic aquí para realizar cambios.'  
         when 'vi-VN' then N'R?t ti?c! Phuong pháp thanh toán [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] không kh? d?ng. T?i th?i di?m này, ch? có phuong pháp '+ '''Tài kho?n Ngu?i choi'+''' du?c h? tr?. Hãy nh?p vào dây d? th?c hi?n thay d?i.'  
         when 'id-ID' then N'Maaf! Metode pembayaran [Neteller, Transfer Bank,.. - affiliate'+'''s chosen one] tidak tersedia. Pada saat ini, hanya metode '+ '''Rekening Pemain'+''' yang didukung. Silakan klik di sini untuk membuat perubahan.'  
         else  N'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
        end,  
      @ErrCode = 3005     
  return  
 END  
  
 --Check supported player's currency
declare @SupportedCurrencies varchar(100)

Select @SupportedCurrencies=SValue
from SystemSettings (nolock)
where Type='Meta' and SName='SupportedBaseCurrencies' 
 
 
 if(@SupportedCurrencies not like '%' + @Player_Currency + '%') 
 begin
	  Select @ErrMsg = case @language   
       when 'en-US' then 'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + '.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'zh-TW' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'zh-CN' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'th-TH' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'es-ES' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'vi-VN' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       when 'id-ID' then N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
       else  N'We do not support the currency ' +   dbo.Aff_ToString(@Player_Currency) + N'.Only these currencies below are supported:' + dbo.Aff_ToString(@SupportedCurrencies)
      end,  
	@ErrCode = 3008  
	return 	
 end
 
declare @Player_ExRate float, @Player_CurrencyId int
  
   Select  @AffCurrencyId=Currency  
   from AffInfo (nolock)  
   where AffID=@AffID   
	
	Select @Player_CurrencyId = ExchangeId
	From CurrencyConverter nolock
	where PartnerCurrency = @Player_Currency

	--Get player's Exchange rate (row is aff currency, column is player currency)
   Select @Player_ExRate=dbo.Aff_GetExchangeRate(@AffCurrencyId, @Player_CurrencyId, default)
  

-- check min amount for withdrawing  
 DECLARE @SName varchar(50),@MinAmount money   
 SELECT @MinAmount=cast(SValue as money)   
    from SystemSettings with(nolock)   
    where SName = 'AFF_Min'+ @PreferredPayment + @AffCurrency  
  
 IF @MinAmount is not null  and @Amount < @MinAmount   
 BEGIN  
  Select @ErrMSg = case @language   
        when 'en-US' then 'Invalid balance account or either the currency or payment method is not supported.'  
        when 'zh-TW' then N'????????????????????'  
        when 'zh-CN' then N'???????????????????'  
        when 'th-TH' then N'????????? ???? ???????? ????????????????? ??.'  
        when 'es-ES' then N'El saldo de la cuenta no es válido o la moneda o método de pago no están permitidos.'  
        when 'vi-VN' then N'Tài kho?n s? du không h?p l? ho?c lo?i ti?n t? hay phuong th?c thanh toán không du?c h? tr?.'  
        when 'id-ID' then N'Rekening saldo tidak valid, atau mata uangnya, atau metode pembayaran tidak didukung.'  
        else  N'Invalid balance account or either the currency or payment method is not supported.'   
       end,  
   @ErrCode = 3006    
  return  
 END  
 
 Declare @SysCurrency varchar(5), @SysCurrencyId smallint, @SysExRate float
 
 Select @SysCurrency=SValue
 from SystemSettings (nolock)
 where Type='Meta' and SName='SystemCurrency'

 Select @SysCurrencyId = ExchangeId
 From Exchange nolock
 where Code = @SysCurrency
 
	Select @SysExRate=dbo.Aff_GetExchangeRate(@AffCurrencyId, @SysCurrencyId, default)


If (Exists(Select 1 From AffDetail nolock where AffId = @AffId and Player_Currency is null))
Begin--Update Player currency if it is null
	update AffDetail with(rowlock, updlock)
	Set Player_Currency = @Player_Currency
	where AffId = @AffId
End
  

BEGIN TRANSACTION  
BEGIN TRY  
    declare @RefNo bigint  
	Select @TransDate=current_timestamp

    --Insert into AffPayout(AffID,IBCCustID,UserName,IBCUserName,AffCurrency,Amount,MemberCurrency,MemberExRate,AffPayout,SysCurrency,SysExRate,TransDate,Status)  
    --values(@AffID,@Player_IBCCustID,@Player_UserName,@Player_IBCUserName,@AffCurrency,-@Amount,@Player_Currency,@Player_ExRate,-@Amount * @Player_ExRate,@SysCurrency,@SysExRate,@TransDate,'pending')   

	Insert into AffPayout(AffID, UserName, IBCUserName, AffCurrency, Amount, MemberCurrency, MemberExRate, AffPayout, SysCurrency, SysExRate, TransDate, Status)  
    values(@AffID, @Player_UserName, @Player_IBCUserName, @AffCurrencyId, -@Amount, @Player_CurrencyId, @Player_ExRate, -@Amount * @Player_ExRate, @SysCurrencyId, @SysExRate, @TransDate, 'pending')   
    
    Select @RefNo= SCOPE_IDENTITY()  
    
    insert into AffTrans(AffID, TransDate, Amount, Status, Description, Creator, AffCurrency, SysCurrency, SysExRate, TransType, RefID)  
	values(@AffID, @TransDate, -@Amount, 'pending', 'Request payout', @AffID, @AffCurrencyId, @SysCurrencyId, @SysExRate, @TransType, @RefNo)  
    select @TransID=SCOPE_IDENTITY()  
END TRY    
BEGIN CATCH  
	rollback transaction   
	select @@Error
    Select @ErrMsg = case @language   
       when 'en-US' then 'Insert transaction failed.'  
       when 'zh-TW' then N'??????'  
       when 'zh-CN' then N'??????'  
       when 'th-TH' then N'?????????????????????????? ??.'  
       when 'es-ES' then N'No se ha podido completar la transacción.'  
       when 'vi-VN' then N'Chèn giao d?ch không thành công.'  
       when 'id-ID' then N'Gagal menyisipkan transaksi.'  
       else  N'Insert transaction failed.'   
      end,  
	@ErrCode = 3007  
    RETURN  
END CATCH  
  
COMMIT TRANSACTION   
         
  
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
SELECT @LogData = 'Affiliate request payout. Amount=' +  dbo.Aff_ToString(@Amount)         
  
select @SPName=OBJECT_NAME(@@ProcID)  
   
EXEC [dbo].[Aff_WriteLog]  
	@Creator=@AffID,   
	@AffID=@AffID,  
	@Typename= 'Payout',   
	@SPName=@SPName ,  
	@IP =@IP,  
	@Details=@LogData   
  
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberUpdIBCInfo]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberUpdIBCInfo    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_MemberUpdIBCInfo]
    @UserName varchar(30),
    @IBCCustID int,    
    @IBCUserName varchar(30),
    @AgentID int,    
    @IP varchar(22),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20090910@Peter
Task : Update IBC Info for a member when member first transfer/deposit and inserted to IBC DB
DB: DB05.Affiliate_MYM
Original: 

Revisions:

Param's Explanation:
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.
• @ErrMsg: Error description.
Write Log on the website
*/
begin
 SET NOCOUNT ON
 if (not exists (Select 1 from MemberInfo(nolock) where UserName=@Username))
  BEGIN
     Select @ErrCode=1001,@ErrMsg=N'User does not exist in the system!!!'
     return
  END

Declare @CreatedDate datetime
set @CreatedDate=current_timestamp

 begin try
  update MemberInfo with (rowlock,updlock)
  Set IBCCustID=@IBCCustID,
      IBCUserName=@IBCUserName,
      Recommend=@AgentID,
      CreatedDate=@CreatedDate
  where UserName=@UserName
  
 end try
 begin catch        
        SELECT @ErrMsg ='Update failed!', @ErrCode = 1002  
        return
 end catch 
end

Declare @LogData nvarchar(max), @SPName varchar(100) 
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'Update Info member. UserName=' + dbo.Aff_ToString(@UserName)                 
                  + '.IBCCustID=' + dbo.Aff_ToString(@IBCCustID)
                  + '.IBCUserName=' + dbo.Aff_ToString(@IBCUserName)
                  + '.AgentID=' + dbo.Aff_ToString(@AgentID)
                  + '.CreatedDate=' + dbo.Aff_ToString(@CreatedDate)                  
                  
EXEC [dbo].[Aff_WriteLog]
    @Creator=8,    
    @AffID=0,
    @Typename= 'Member',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberDomainUpd]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberDomainUpd    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE PROC [dbo].[Aff_MemberDomainUpd]
    @DomainID int,
    @DomainName nvarchar(50),     
    @UserID int,    
    @IP nvarchar(15)='',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Update a AffDomain
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
BEGIN TRANSACTION
UPDATE [MemberDomain] with (rowlock,updlock)
SET
    [ModifyDate] = getdate(),
    [DomainName] = @DomainName,              
    [Creator] = @UserID    
WHERE DomainID = @DomainID

IF @@Error <> 0 
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = N'Error occurs.Update unsuccessfully.', @Errcode=1001
    return
END     

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                    

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomain', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberDomainIns]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberDomainIns    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE PROC [dbo].[Aff_MemberDomainIns]
    @DomainID int OUTPUT,
    @DomainName nvarchar(50),     
    @UserID int,        
    @IP nvarchar(15)='',
    @Language varchar(5) = 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Add a new 12Bet domain
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
If Exists(select 1 from [MemberDomain] nolock where DomainName = @DomainName)
Begin
    select @ErrCode = 1001,
            @ErrMsg = case @Language 
                        when 'en-US' then N'This member domain has been existed!'
                        when 'zh-TW' then N'这个会员网域已经存在！'
                        when 'zh-CN' then N'這個會員網域已經存在!'
                        else N'This member domain has been existed!'
                    end
    return
End

declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp

BEGIN TRANSACTION
INSERT INTO [MemberDomain]
   (    
        [DomainName]
       ,[CreateDate]
       ,[ModifyDate]
       ,[Creator]       
    )
    VALUES
    (            
        @DomainName,                
        @CreatedDate,
        @CreatedDate,
        @UserID        
    )
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Insert unsuccessfully.'
                        when 'zh-CN' then N'錯誤發生.插入不成功'
                        when 'zh-TW' then N'错误发生。插入不成功'
                        else N'Error occurs.Insert unsuccessfully.!'
                    end, @ErrCode = 1002
    return
END

SELECT @DomainID = @@IDENTITY

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                    

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomain', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberDomainDel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberDomainDel    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_MemberDomainDel]
    @DomainID int OUTPUT,
    @DomainName nvarchar(50),     
    @UserID int,    
    @IP nvarchar(15)='',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@ThaiTran
Task : Del a AffDomain
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
If Exists(select 1 from AffDomainControl nolock where AffDomainID = @DomainID)
Begin
    select @ErrCode = 1001,
            @ErrMsg = 'This 12Bet domain has been used!'
    return
End
delete [MemberDomain]
where DomainID = @DomainID
print 'test'

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete DomainID:' + dbo.Aff_ToString(@DomainID)                     
                    + ' DomainName:' + dbo.Aff_ToString(@DomainName)                                        

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomain', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberDel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_MemberDel    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE PROCEDURE [dbo].[Aff_MemberDel]
    @UserName varchar(30),
    @UserID int,    
    @IP varchar(20),    
    @AffID int=null OUTPUT,
    @RefNo bigint=0 OUTPUT,    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
begin
/*
Created: 20090910@Peter
Task : Remove a member  from Affiliate
DB: DB052.Affiliate_ZZun
Original: 

Revisions:
          Peter@20100413 : Remove the calling to sp [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]
                           coz AffiliateID in custinfo will be removed.  
          Johnny@20100512: Re-calculate AffDaily if member is removed.
          Peter@20100927 : Add OddsFee column for AffDetail

Param's Explanation:
.@IP: ip of computer sent,
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.
• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------

EXEC [dbo].[Aff_Con_CheckPermission] 
    @custid=@UserID,@funcname='[Affiliate]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
--Check IBCCustID

select @AffId=AffId from MemberInfo(nolock) where UserName=@UserName and IsRemoved = 0
if(@AffID is null)
begin
    SELECT @ErrMsg ='This member does not exist or be removed before!', @ErrCode = 1001
    RETURN
end

DECLARE @LogData nvarchar(4000),@SPName varchar(100), @FirstDayOfTheMonth datetime
SELECT @LogData = 'Remove member. UserName=' + dbo.Aff_ToString(@UserName)
        , @FirstDayOfTheMonth = dbo.Aff_GetFirstDayOfMonth(Current_Timestamp) 
begin transaction
 begin try
   
  update MemberInfo with (rowlock,updlock)
  set IsRemoved = 1
  where UserName=@UserName

  INSERT INTO [MemberDailyRemoved]
           ([UserName]
           ,[WinlostDate]
           ,[ProductID]
           ,[AffID]
           ,[IBCCustID]
           ,[Currency]
           ,[AffCurrency]
           ,[AffExRate]
           ,[SysCurrency]
           ,[SysExRate]
           ,[Deposit]
           ,[Withdrawal]
           ,[Bonus]
           ,[Adjustment]
           ,[Turnover]
           ,[Outstanding]
           ,[Winlost]
           ,[DrawGame]
           ,[PSP]
           ,[Marketing]
           ,[MemWinlostFake]
           ,[MemOddsFee]
           ,[MemPLayTechFee]
           ,[AffTransfer]
           ,[Transfer3rd]
           ,[BetCount]
           ,[PlayerComm])
           
  select   [UserName]
           ,[WinlostDate]
           ,[ProductID]
           ,[AffID]
           ,[IBCCustID]
           ,[Currency]
           ,[AffCurrency]
           ,[AffExRate]
           ,[SysCurrency]
           ,[SysExRate]
           ,[Deposit]
           ,[Withdrawal]
           ,[Bonus]
           ,[Adjustment]
           ,[Turnover]
           ,[Outstanding]
           ,[Winlost]
           ,[DrawGame]
           ,[PSP]
           ,[Marketing]
           ,[MemWinlostFake]
           ,[MemOddsFee]
           ,[MemPLayTechFee]
           ,[AffTransfer]
           ,[Transfer3rd]
           ,[BetCount]
           ,[PlayerComm]
  from MemberDaily with (nolock)
  where UserName=@UserName and datediff(m,winlostdate,current_timestamp)=0 
  
  Delete MemberDaily
  where UserName=@UserName and datediff(m,winlostdate,current_timestamp)=0
  
--Update AFFDaily here
DELETE FROM AffDaily 
WHERE AffId = @AffId
    and datediff(m,winlostdate,current_timestamp)=0

INSERT INTO AffDaily
        ([AffID]
        ,[MemCurrency]
        ,[Winlostdate]
        ,[ProductID]
        ,[AffCurrency]
        ,[AffExRate]
        ,[SysCurrency]
        ,[SysExRate]
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
        ,[MemAffTransfer]
        ,[MemTransfer3rd]
        ,[MemBetCount]
        ,[MemPlayerComm])

select m.[AffID]
        ,m.[Currency] as [MemCurrency]
        ,m.[WinlostDate]
        ,m.[ProductID]
        ,m.[AffCurrency]
        ,m.[AffExRate]
        ,m.[SysCurrency]
        ,m.[SysExRate]
        ,Sum(Deposit) as MemDeposit
        ,Sum(Withdrawal) as MemWithdrawal
        ,Sum(Turnover) as MemTurnover
        ,Sum(Bonus) as MemBonus
        ,Sum(Adjustment) as MemAdjustment
        ,Sum(Marketing) as MemMarketing    
        ,Sum(PSP) as MemPSP
        ,Sum(Winlost) as MemWinlost
        ,0 as AffWinlost
        ,-Sum(Winlost)  as HouseWinlost
        ,0 as AffNetWinlost
        ,0 as HouseNetWinlost
        ,Sum(MemWinlostFake) as MemWinlostFake
        ,Sum(MemOddsFee) as MemOddsFee                     
        ,Sum(MemPLayTechFee) as MemPLayTechFee
        ,Sum([AffTransfer])
        ,Sum([Transfer3rd])
        ,Sum([BetCount])
        ,Sum([PlayerComm])
from MemberDaily(nolock) as m
where m.WinlostDate >= @FirstDayOfTheMonth
     and m.AffID=@AffId
group by m.AffID
    ,m.Winlostdate
    ,m.ProductID
    ,m.Currency
    ,m.[AffCurrency]
    ,m.[AffExRate]
    ,m.[SysCurrency]
    ,m.[SysExRate]

update AffDaily with (rowlock,updlock)    
set 
    HouseNetWinLost=HouseWinLost  
         - isnull(MemBonus,0) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',Winlostdate),0)     
         -isnull(MemAdjustment,0)  
         -isnull(MemPSP,0)* isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',Winlostdate),0)  
         - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',Winlostdate),0)  
         - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',Winlostdate),0)
         - abs(isnull(MemWinlost,0)) * isnull(dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',Winlostdate),0)  
where AffId = @AffId
   and WinlostDate >= @FirstDayOfTheMonth
      
DELETE AffDailySummary 
WHERE AffId = @AffId
    and WinlostDate >= @FirstDayOfTheMonth    

--Update [AffDailySummary] table
INSERT INTO [dbo].[AffDailySummary]  
    ([AffID]  
    ,[Winlostdate]  
    ,[ProductID]
    ,[AffCurrency]
    ,[SysCurrency]   
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
    ,[MemPLayTechFee]
    ,[MemWinlostFake]
    ,[MemDeposit_aff]
    ,[MemWithdrawal_aff]
    ,[MemTurnover_aff]
    ,[MemBonus_aff]
    ,[MemAdjustment_aff]
    ,[MemMarketing_aff]
    ,[MemPSP_aff]
    ,[MemWinlost_aff]
    ,[AffWinlost_aff]
    ,[HouseWinlost_aff]
    ,[AffNetWinlost_aff]
    ,[HouseNetWinlost_aff]
    ,[MemOddsFee_aff]
    ,[MemWinlostFake_aff]
    ,[MemPLayTechFee_aff]
    ,MemAffTransfer
    ,MemTransfer3rd
    ,MemBetCount
    ,MemPlayerComm
    ,MemAffTransfer_aff
    ,MemTransfer3rd_aff
    ,MemPlayerComm_aff

     )  
  
select [AffID]  
    ,[Winlostdate]  
    ,[ProductID]
    ,[AffCurrency]
    ,[SysCurrency]  
    ,Sum([MemDeposit] * SysExRate) as [MemWithdrawal]
    ,Sum([MemWithdrawal] * SysExRate) as [MemWithdrawal]
    ,Sum([MemTurnover] * SysExRate) as [MemTurnover]
    ,Sum([MemBonus] * SysExRate) as   [MemBonus]
    ,Sum([MemAdjustment] * SysExRate) as   [MemAdjustment]
    ,Sum([MemMarketing] * SysExRate) as  [MemMarketing] 
    ,Sum([MemPSP] * SysExRate) as   [MemPSP]
    ,Sum([MemWinlost] * SysExRate) as   [MemWinlost]
    ,Sum([AffWinlost] * SysExRate) as [AffWinlost]  
    ,-Sum([MemWinlost] * SysExRate) as  [HouseWinlost] 
    ,0 as  [AffNetWinlost] 
    ,0 as  [HouseNetWinlost] 
    ,Sum([MemOddsFee] * SysExRate) as   [MemOddsFee]
    ,Sum([MemPLayTechFee] * SysExRate) as [MemPLayTechFee]
    ,0 as [MemWinlostFake]
    ,Sum([MemDeposit] * AffExRate) as [MemDeposit_aff]
    ,Sum([MemWithdrawal] * AffExRate) as [MemWithdrawal_aff]
    ,Sum([MemTurnover] * AffExRate) as [MemTurnover_aff]
    ,Sum([MemBonus] * AffExRate) as [MemBonus_aff]
    ,Sum([MemAdjustment] * AffExRate) as [MemAdjustment_aff]
    ,Sum([MemMarketing] * AffExRate) as [MemMarketing_aff]
    ,Sum([MemPSP] * AffExRate) as [MemPSP_aff]
    ,Sum([MemWinlost] * AffExRate) as [MemWinlost_aff]
    ,0 as [AffWinlost_aff]
    ,-Sum([MemWinlost] * AffExRate) as [HouseWinlost_aff]
    ,0 as [AffNetWinlost_aff]
    ,0 as [HouseNetWinlost_aff]
    ,Sum([MemOddsFee] * AffExRate) as [MemOddsFee_aff]
    ,Sum([MemWinlostFake] * AffExRate) as [MemWinlostFake_aff]
    ,Sum([MemPLayTechFee] * AffExRate) as [MemPLayTechFee_aff]
    ,sum(MemAffTransfer * SysExRate)
    ,sum(MemTransfer3rd * SysExRate)
    ,sum(MemBetCount)
    ,sum(MemPlayerComm * SysExRate)
    ,sum(MemAffTransfer * AffExRate)
    ,sum(MemTransfer3rd * AffExRate)
    ,sum(MemPlayerComm * AffExRate)
from AffDaily(nolock)
where AffId = @AffId
    and WinlostDate >= @FirstDayOfTheMonth 
group by AffID, Winlostdate, ProductID, AffCurrency, SysCurrency

update AffDailySummary with (rowlock,updlock)  
set 
     /*MemWinlostFake=  -(-MemWinlost  
          - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
          - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
          - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)
          - MemPSP * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)) ,      
     */
      HouseNetWinlost=(  
          -MemWinlost  
          -MemBonus * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)  
          -MemAdjustment  
          -MemPSP * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)  
          - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
          - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
          - abs(MemWinlost) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)  
          ) ,
          
          HouseNetWinlost_aff=(  
          -MemWinlost_aff  
          -MemBonus_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Bonus',WinlostDate)  
          -MemAdjustment_aff  
          -MemPSP_aff * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PSP',WinlostDate)  
          - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Marketing',WinlostDate)  
          - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'Odds Fee',WinlostDate)  
          - abs(MemWinlost_aff) * dbo.Aff_GetDeductionPercent(AffID,ProductID,'PlayTech Royalties',WinlostDate)  
          )   

     
  where AffId = @AffId
    and WinlostDate >= @FirstDayOfTheMonth 
  
  Insert Into MemberRemoval(UserName,RemovedDate,RemovedBy)
  values(@UserName,current_timestamp,@UserID)

 end try
 begin catch        
        rollback transaction        
        SELECT @ErrMsg =ERROR_MESSAGE(), @ErrCode = ERROR_NUMBER()  
        return
 end catch 
COMMIT TRANSACTION    

--Write the log 

select @SPName=OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog]
    @Creator=@UserID,    
    @AffID=@AffID,
    @Typename= 'Member',    
    @SPName=@SPName ,
    @RefNo=@RefNo,
    @IP =@IP,
    @Details=@LogData    

end
GO
/****** Object:  StoredProcedure [dbo].[Aff_Logout]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Logout    Script Date: 7/29/2013 1:41:14 AM ******/
CREATE Procedure [dbo].[Aff_Logout]  
 @On_UserID int,  
 @ServerID int = NULL,  
 @UserName varchar(30) = NULL  
AS  
/*  
Created:   
Task : Admin logout  
DB: DB052.Affiliate_MYM
Original:  
  
Revisions:  
    - 20090915@Hung: Create to process logout of admin on Affiliate admin site.  
  
Param's Explanation:  
*/  
  
SET NOCOUNT ON  
--Write log to record user logout  
Declare @CustID int, @Creator int, @LoginIP varchar(20), @TypeName varchar(20), @Role varchar(20),  @SubAccID int 
Select @CustID = custid, @ServerID = coalesce(@ServerID,ServerID,''), @LoginIP = IP, @SubAccID=subaccid   
From On_User (nolock) where on_userid = @On_UserID  
  
select @ServerID=null

SELECT @TypeName = case when @SubAccID=6 then 'LogoutAdmin' else 'LogoutAffiliate' end
  

Delete from On_User where on_userid = @On_UserID  

--Write log
declare @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)
SELECT @LogData =  case when @SubAccID=6 then 'Admin' else 'Affiliate' end + case when isnull(@UserName,'') = '' then cast(isnull(@custid,'') as varchar(30)) else isnull(@Username,'') end + ' IP:' + isnull(@LoginIP,'') + ' Logout ServerID:' + CAST(isnull(@ServerID,'') as nvarchar(20))    


select @Creator = case when @SubAccID < 0 then abs(@SubAccID) else @CustID end

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Creator,
    @AffID = @CustID,
    @Typename = @TypeName, -- refer to table LogType
    @SPName = @SPName,
    @Details = @LogData,
    @IP = @LoginIP
GO
/****** Object:  StoredProcedure [dbo].[Aff_LoginAffiliate]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_LoginAffiliate    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_LoginAffiliate]
    @UserName [varchar](50),
    @UserPwd [varchar](50),
    @LoginIP [varchar](20),
    @ServerID [int],
    @CustID [int] OUTPUT,
    @FirstName [nvarchar](50) = '' OUTPUT,
    @LastName [nvarchar](50) = '' OUTPUT,
    @Email [nvarchar](50) = '' OUTPUT,
    @Language [varchar](2) = 'E',
    @ErrCode [int] = 0 OUTPUT,
    @ErrMsg [nvarchar](4000) = '' OUTPUT,
    @HasSecurityQuestion [bit] = 1 OUTPUT
WITH EXECUTE AS CALLER
AS
/*
 *    Created: 20090720@Ken
 *    Task : Login to Affiliate
 *    DB: DB052.Affiliate_MYM
 *
 *    Revisions:            
*/
SET NOCOUNT ON
declare @LogData nvarchar(200)

Declare @db_custid int, @db_userpwd nvarchar(50), @db_roleid tinyint, @failedcount int
Declare @closed bit, @status varchar(30)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 



SELECT @db_custid = i.affID, @db_userpwd = Password, @failedcount = LoginCount,
    @FirstName = firstname,@LastName = lastname,@Email = Email, @closed = IsClosed, @Status = Status
FROM AffInfo i with (nolock)
    INNER JOIN AffDetail d with(nolock) on i.AffID = d.affID
WHERE i.username = @UserName    
    
-- user not found
IF @@ROWCOUNT = 0
BEGIN
    SELECT @LogData = 'Failed login attempt (wrong username), ServerID:' + dbo.ToString(@ServerID) + ', [' + @UserName + ']'
    EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
    select @ErrMsg = case @Language    when 'E' then 'Wrong username or password.'
                                    when 'CT' then N'用戶名或密碼錯誤'
                                    when 'CS' then N'用户名或密码错误'
                                    when 'J' then N'Wrong username or password.'
                                    when 'TH' then N'Wrong username or password.'
                                    else N'Wrong username or password.'
                                end    ,@ErrCode=1006                        
    return
END

--check closed 
IF IsNull(@closed, 1) = 1
BEGIN
    SELECT @LogData = 'Failed login attempt (account is closed), ServerID:' + dbo.ToString(@ServerID)
    EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
    select @ErrMsg =    case @Language    when 'E' then 'Your account is closed. Please contact your administrator!'
                            when 'CT' then N'帳號關閉. 請聯絡管理員.'
                            when 'CS' then N'账号关闭，请联络管理员'
                            when 'J' then N'Your account is closed. Please contact your administrator!'
                            when 'TH' then N'Your account is closed. Please contact your administrator!'
                            else N'Your account is closed. Please contact your administrator!'
                        end    ,@ErrCode=1008
    return
END

--check pending or expired
IF @status <> 'Approved'    
BEGIN  
    SELECT @LogData = 'Failed login attempt (account is not approved), ServerID:' + dbo.ToString(@ServerID)
    EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
    
    SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Account not approved.' + dbo.ToString(@ServerID)
        EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @Details = @LogData
        select @ErrMsg =    case @Language    when 'E' then 'Account is not approved. Please contact your administrator!'
                                when 'CT' then N'帳號未核準，請聯絡管理員。'
                                when 'CS' then N'账号未核准，请联络管理员'
                                when 'J' then N'Account is not approved. Please contact your administrator!'
                                when 'TH' then N'Account is not approved. Please contact your administrator!'
                                else N'Account is not approved. Please contact your administrator!'
                            end    ,@ErrCode=1009
        RETURN
END 

IF @db_userpwd <> @UserPWD
    BEGIN
        SELECT @LogData = 'Failed login attempt (wrong password), ServerID:' + dbo.ToString(@ServerID)
        EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData        
        
        SELECT @failedcount = @failedcount + 1        
        IF @failedcount > 5            
        BEGIN
            UPDATE AffInfo with(rowlock, updlock) SET IsClosed = 1 WHERE AffID = @db_custid

            SELECT @LogData = 'The A/C is closed due to 5 wrong password attempts'
            EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData                        
        END
        UPDATE AffDetail with(rowlock, updlock) SET logincount = @failedcount WHERE AffID = @db_custid

        select @ErrMsg =    case @Language    when 'E' then 'Wrong username or password.'
                                when 'CT' then N'用戶名或密碼錯誤'
                                when 'CS' then N'用户名或密码错误'
                                when 'J' then N'Wrong username or password.'
                                when 'TH' then N'Wrong username or password.'
                                else N'Wrong username or password.'
                            end    ,@ErrCode=1005
        return
    END

-- Successful
SELECT @CustID = @db_custid
 
UPDATE AffDetail with (rowlock, updlock)
SET logincount = 0, LastLoginIP = @LoginIP, LastLoginDate = CURRENT_TIMESTAMP
WHERE AffID = @db_custid

SELECT @LogData = 'Successful login, ServerID:' + dbo.ToString(@ServerID)
EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageUpd]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_LanguageUpd    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_LanguageUpd]
    @Updatedby int ,
    @LanguageID varchar(8),
    @LanguageName nvarchar(50),    
    @CountryID varchar(8),            
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Language
DB: DB052.Affiliate_MYM
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error CountryID.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from Language (nolock) where LanguageID=@LanguageID ))
BEGIN
Select @ErrMsg = N'Error! This Language does not exist!', @ErrCode = 1001
    return
END
update Language with (rowlock,updlock)
Set LanguageName=@LanguageName, [CountryID]=@CountryID
where LanguageID=@LanguageID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Language. ID= ' + @LanguageID +     
    '.LanguageName=' + @LanguageName + 
     '.CountryID=' + @CountryID

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Language', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageIns]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_LanguageIns    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE PROCEDURE [dbo].[Aff_LanguageIns]
	@Updatedby int ,
	@LanguageID varchar(8),
	@LanguageName nvarchar(50),	
	@CountryID varchar(8),		
	@IP nvarchar(15)='',	
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : Insert Language
DB: DB052.Affiliate_ZZun
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@Updatedby,@funcname='[SystemSettings]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
	
If @ErrCode <> 0
	RETURN
	
If( Exists (Select 1 from Language (nolock) where LanguageID=@LanguageID ))
BEGIN
Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! This Language is existed!' 
					when 'zh-CN' then N'錯誤!這個語言已經存在!'
					when 'zh-TW' then N'错误！这个语言已经存在！'
					else N'Error! This Language is existed!' 
				end, @ErrCode = 1001
	return
END

Declare @Order smallint

select @Order = MAX([Order]) from [Language]
INSERT INTO [Language]
           ([LanguageID]
           ,[LanguageName]
           ,[CountryID]
           ,Creator
           ,CreatedDate
		   ,[Order])
     VALUES
           (@LanguageID
           ,@LanguageName           
           ,@CountryID
           ,@Updatedby
           ,CURRENT_TIMESTAMP
		   ,@Order+1)


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Language. ID= ' + dbo.Aff_ToString(@LanguageID) +	
	 '.CountryID=' + @CountryID

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Language', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageDel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_LanguageDel    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_LanguageDel]
    @Updatedby int ,
    @IDList varchar(max),
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:


Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

delete [dbo].[Language]
where LanguageID in (select val from dbo.strsplit(@IDList, ',') )

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Language. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Language', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_HotNewsUpd]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HotNewsUpd    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE PROCEDURE [dbo].[Aff_HotNewsUpd]
	@ID int,
	@important bit,
	@xml xml,	
	@IP varchar(20),
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090310@TrangLe
Task : Update affiliate hot news by message id
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20140225@Joseph : Use xml data to update
- 20130815@Joseph : Insert data to RefResources if they are not exist when updating

Param's Explanation:
• @ID : message id input
• @xml: xml data
• @important: message important or not
• @UserID: user updating msg, will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Update unsuccessful.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[HotNews]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
if not exists (select 1 from [dbo].[News]  with (nolock) where  msgid=@ID)
BEGIN
	Select @ErrMsg = 'Invalid message ID!', @ErrCode = 101		
	return
END
/*
UPDATE [News] with(rowlock,updlock)
   SET [message_en] = Coalesce(@MsgEN,[message_en])
      ,[message_cn] = Coalesce(@MsgCN,[message_cn])
      ,[message_tw] = Coalesce(@MsgTW,[message_tw])
      ,[message_es] = Coalesce(@MsgES,[message_es])
      ,[message_th] = Coalesce(@MsgTH,[message_th])
      ,[message_vi] = Coalesce(@MsgVI,[message_vi])
      ,[message_id] = Coalesce(@MsgID,[message_id])
      ,[important] = Coalesce(@important,[important])
      ,[updatedby]=Coalesce(@UserID,[updatedby])
      ,updateddate=current_timestamp
WHERE msgid=@ID
*/
UPDATE [News] with(rowlock,updlock)
   SET Message_En =  Coalesce(@xml.value('(/root/item[code="en-US"]/value)[1]','nvarchar(4000)'),Message_En)
		,[important] = Coalesce(@important,[important])
      ,[updatedby]=Coalesce(@UserID,[updatedby])
      ,updateddate=current_timestamp
WHERE msgid=@ID


update RefResources with(rowlock,updlock)
set ResourceValue = temp.Value
FROM RefResources r
INNER JOIN (
 select Tab.item.value('code[1]','varchar(100)') as Code		
		,Tab.item.value('value[1]','nvarchar(4000)') as Value
 from @xml.nodes('/root/item') Tab(item)
 ) temp ON r.LanguageCode = temp.Code
WHERE r.RefID = 'News' AND r.ResourceKey = cast(@ID as varchar(10))
 
 
 INSERT INTO [RefResources]
           ([ResourceID]
           ,[RefID]
           ,[LanguageCode]
           ,[ResourceKey]
           ,[ResourceValue])
  select newid()
		,'News'
		,Tab.item.value('code[1]','varchar(100)')
		,@ID
		,Tab.item.value('value[1]','nvarchar(4000)')
 from @xml.nodes('/root/item') Tab(item)
 where NOT EXISTS(select 1 from RefResources where RefID = 'News' AND LanguageCode =  Tab.item.value('code[1]','varchar(100)')  AND ResourceKey = cast(@ID as varchar(10)))
 
IF @@ERROR <> 0
BEGIN
	
	Select @ErrMsg = N'Error! Message unsuccessfully updated!', @ErrCode = 1001
	return
END


 --Write the log 
DECLARE @LogData nvarchar(4000)
SELECT @LogData = 'Update Affiliate_News MsgID:' + dbo.Aff_ToString(@ID)                         

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator = @UserId,	
	@TypeName = 'Message',	
	@SPName = @SPName,
	@IP = @IP,
	@Details = @LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_HotNewsIns]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HotNewsIns    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE PROCEDURE [dbo].[Aff_HotNewsIns]        
        @important bit,
        @xml xml,
        @IP varchar(20),
        @UserID int,
        @ErrCode int = 0 OUTPUT,
        @ErrMsg nvarchar(4000) = '' OUTPUT
AS
begin
/*
Created: 20090310@TrangLe

Task : Insert message for Affiliate News
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20130225@Joseph : Insert data into RefResources table
Param's Explanation:
• @important: message important or not
• @xml: data containing all messages that will be inserted
• @UserID: user inserting msg,creator, will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[HotNews]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
BEGIN TRANSACTION
           
INSERT INTO [dbo].[News]
           (Message_En
           ,[creator]
           ,[posteddate]
           ,[important])
     VALUES
           (@xml.value('(/root/item[code="en-US"]/value)[1]','nvarchar(4000)')
           ,@UserID
           ,getdate()
           ,@important)
           
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = N'Error! Insert message unsuccessfully!', @ErrCode = 1001
    return
END

DECLARE @ID int 
SELECT @ID = SCOPE_IDENTITY()
           
INSERT INTO [RefResources]
           ([ResourceID]
           ,[RefID]
           ,[LanguageCode]
           ,[ResourceKey]
           ,[ResourceValue])
  select newid()
        ,'News'
        ,Tab.item.value('code[1]','varchar(100)')        
        ,@ID
        ,Tab.item.value('value[1]','nvarchar(4000)')
 from @xml.nodes('/root/item') Tab(item)
      
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = N'Error! Insert data into refresouces unsuccessfully!', @ErrCode = 1002
    return
END

COMMIT TRANSACTION



 --Write the log 
DECLARE @LogData nvarchar(4000)
SELECT @LogData = 'Insert into Affiliate_News MsgID:' + dbo.Aff_ToString(@ID)       

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator = @UserId,    
    @TypeName = 'Message',    
    @SPName = @SPName,
    @IP = @IP,
    @Details = @LogData
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_HotNewsDel]    Script Date: 07/30/2013 04:21:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_HotNewsDel    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE PROCEDURE [dbo].[Aff_HotNewsDel]
    @listmsgid varchar(4000)=null,
    @UserID int,
    @IP varchar(20),
    @Language varchar(5)= 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090624@VinhTrinh
Task : Delete affiliate hot news by message id
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:
• @listmsgid : list of message ids need to delete separated by a comma
• @UserID: user deleting msg will be logged
• @ErrCode:
= 0: Transaction recorded successfully.
101: Invalid message ID.
1001: Unsuccessful deleting msg.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[HotNews]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
--Check list of messageid
if(@listmsgid is null)
begin
    Select @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid message ID!' 
                            when 'zh-CN' then N'無效的訊息ID!'
                            when 'zh-TW' then N'无效的讯息ID！'
                            else N'Invalid message ID!' 
                        end, @ErrCode = 101    
    return
end    

declare @msgidTable table(msgid int)
 insert into  @msgidTable
         select distinct val from dbo.strsplit(@listmsgid,',')
 declare @count int,@countDB int
  select @count=count(1) from @msgidTable
    select @countDB=count(1)
          from News a  (nolock)
               inner join @msgidTable t on a.msgid=t.msgid
    
    if (@count <> @countDB)
        BEGIN
             Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, your input message id is invalid. Please recheck it again.' 
                            when 'zh-CN' then N'抱歉,您輸入的訊息ID是無效的.請重新確認.'
                            when 'zh-TW' then N'抱歉，您输入的讯息ID是无效的，请重新确认。'
                            else N'Sorry, your input message id is invalid. Please recheck it again.' 
                        end,                                 
                    @ErrCode = 102
            return      
        END    
--Check UserID is valid
if(not exists(select 1 from AdminUser (nolock) where custid=@UserID))
begin
     Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, Admin id is invalid. Please recheck it again.' 
                            when 'zh-CN' then N'抱歉, 管理員ID是無效的.請重新確認.'
                            when 'zh-TW' then N'抱歉，管理员ID是无效的，请重新确认。'
                            else N'Sorry, Admin id is invalid. Please recheck it again.' 
                        end,                                 
                    @ErrCode = 103
            return
end

Delete News with(rowlock)
WHERE msgid in (select msgid from @msgidTable)

IF @@ERROR <> 0
BEGIN
    
    Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Message unsuccessfully deleted!' 
                            when 'zh-CN' then N'錯誤發生.插入資料不成功.'
                            when 'zh-TW' then N'错误发生。插入资料不成功。'
                            else N'Error! Message unsuccessfully deleted!' 
                        end, @ErrCode = 1001
    return
END

 --Write the log 
DECLARE @LogData nvarchar(4000)
SELECT @LogData = 'Delete News MsgIDList:' + dbo.Aff_ToString(@listmsgid)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog]
    @Creator=@UserId,    
    @TypeName= 'Message',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_ExchangeAutoRefreshUpd]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ExchangeAutoRefreshUpd    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_ExchangeAutoRefreshUpd]
    @CustId int,
    @ExchangeId int,    
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
    Created: 20110223@Viet
    Task : Enable/disable auto refresh rate (daily)
    DB: DB052.Affiliate_MYM
    Revisions:
        - 20110223@Viet: initialize SP
        
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@CustId,@funcname='[AffEx.Rate]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0    RETURN    

UPDATE exchange with(rowlock, updlock)
SET isautorefresh = ~isnull(isautorefresh,0)
WHERE ExchangeId = @ExchangeId
        
DECLARE @LogData nvarchar(200), @SPName varchar(50)
SELECT @LogData = 'Enable/disable auto refresh rate (daily). ExchangeId:' + dbo.Aff_ToString(@ExchangeId)
       ,@SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@CustId,        
    @TypeName= 'ExchangeRate',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_EmailHistoryIns]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_EmailHistoryIns    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE Procedure [dbo].[Aff_EmailHistoryIns]
    @MID int OUTPUT,
    @creator int=-1,
    @content nvarchar(4000),
    @sender nvarchar(100),
    @affiliate varchar(30)=null,
    @email nvarchar(50),
    @subject nvarchar(2000),
    @ip nvarchar(15),
    @browser nvarchar(100),
    @sessionid nvarchar(100),
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
begin
/*
Created: 20090626@VinhTrinh
Task : Insert new email for EmailHistory
DB: DB052.Affiliate_MYM
Original:

Revisions:


Param's Explanation:
.@MID: OUTPUT of mail id,
.@creator : id of customer sent this email
.@content: content of this email,
.@sender: sender name,
.@affiliate: name of affiliate in the system,
.@email: email of sender,
.@subject: email subject,
.@ip: ip of computer sent,
.@browser: name of browser,
.@sessionid: ASP.NET session id,
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

--check all of parameter is valid.
declare @affiliateid int,@maximumPer10minutes int --maximum of 20 emails per 10 minutes for each session

select @affiliateid=-1,@maximumPer10minutes=20
--Check creator name
if(@creator<>-1 and not exists(select 1 from AffInfo with (nolock) where AffId=@creator))
begin
    begin 
            select @ErrMsg='Invalid creator!',@ErrCode=101
            return
      end 
end
--check affiliate username
if(@affiliate is not null)
begin
     select @affiliateid=AffID
     from AffInfo  with (nolock)  
     where username=@affiliate
    if (@@rowcount<>1)
      begin 
            select @affiliateid=-1            
      end           
end

--check content
if (isnull(@content,'')='')
  begin
      select @ErrMsg='Invalid mail content!',@ErrCode=102
            return
  end
--check sender name
 if (isnull(@sender,'')='')
  begin
      select @ErrMsg='Invalid sender name!',@ErrCode=103
            return
  end
 
--check email
if (isnull(@email,'')='')
  begin
      select @ErrMsg='Invalid  email address!',@ErrCode=104
            return
  end

--check mail subject
if (isnull(@subject,'')='')
  begin
      select @ErrMsg='Invalid  mail subject!',@ErrCode=105
            return
  end

--check ip
if (isnull(@ip,'')='')
  begin
      select @ErrMsg='Invalid sender ip!',@ErrCode=106
            return
  end

--check browser
if (isnull(@browser,'')='')
  begin
      select @ErrMsg='Invalid browser name!',@ErrCode=107
            return
  end

--check session id
if (isnull(@sessionid,'')='')
  begin
      select @ErrMsg='Invalid ASP.NET session id!',@ErrCode=108
            return
  end
--Check is allow to send email (just allow to send maximum of @maximumPer10minutes per 10 minutes)
--if (@affiliateid<>-1)
--begin
    declare @count int
    select @count=count(1) from [EmailHistory] with (nolock)
    where sessionid=@sessionid and datediff(mi,createddate,current_timestamp)<=10

    if(@count>@maximumPer10minutes)
    begin
            select @ErrMsg='You are just allowed to send maximum of ' + cast(@maximumPer10minutes as varchar(5)) + ' emails per 10 minutes!',@ErrCode=102
                return
    end
--end
BEGIN TRANSACTION
INSERT INTO [dbo].[EmailHistory]
           ([content]
           ,[sender]
           ,[creator]
           ,[AffID]
           ,[affname]
           ,[email]
           ,[subject]
           ,[createddate]
           ,[ip]
           ,[browser]
           ,[sessionid]
           )
     VALUES
           (@content
           ,@sender
           ,@creator
           ,@affiliateid
           ,@affiliate
           ,@email
           ,@subject
           ,getdate()
           ,@ip
           ,@browser
           ,@sessionid)
           
IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = N'Error! Insert email unsuccessfully!', @ErrCode = 1001
    return
END

SELECT @MID = SCOPE_IDENTITY()
COMMIT TRANSACTION

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Insert into EmailHistory MID:' + dbo.Aff_ToString(@MID)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@creator,    
    @AffID = @affiliateid, 
    @TypeName= 'Email',    
    @SPName=@SPName,
    @IP =@IP,
    @Details=@LogData
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_EmailHistoryDel]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_EmailHistoryDel    Script Date: 7/29/2013 1:41:15 AM ******/
CREATE PROCEDURE [dbo].[Aff_EmailHistoryDel]  
  @listmid varchar(4000)=null,  
  @UserID int,  
  @IP varchar(20),  
    @Language varchar(5)= 'en-US', 
  @ErrCode int = 0 OUTPUT,  
  @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
/*  
Created: 20090626@VinhTrinh  
Task : Delete affiliate email by list of mail id  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
  
Param's Explanation:  
• @listmid : list of mail id separated by a comma  
• @UserID: user deleting mid will be logged  
• @ErrCode:  
= 0: Transaction recorded successfully.  
101: Invalid message ID.  
1001: Unsuccessful deleting msg.  
  
• @ErrMsg: Error description.  
*/  
-----------------------------------------------  
SET NOCOUNT ON  
--Check permission(If AffId = userid => Affiliate update info else Admin Update Aff info)-----------------------------  
  
EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,  
 @funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
  
If @ErrCode <> 0  
 RETURN  
  
--Check list of mail id  
if(@listmid is null)  
begin  
 Select @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid mail ID!' 
                            when 'zh-CN' then N'無效的電子郵件ID!'
                            when 'zh-TW' then N'无效的电子邮件ID！'
                            else N'Invalid mail ID!' 
                        end, @ErrCode = 101   
 return  
end   
  
declare @midTable table(mid int)  
 insert into  @midTable  
         select distinct val from dbo.strsplit(@listmid,',')  
 declare @count int,@countDB int  
  select @count=count(1) from @midTable  
    select @countDB=count(1)  
          from EmailHistory a  (nolock)  
               inner join @midTable t on a.mid=t.mid  
      
    if (@count <> @countDB)  
  BEGIN  
    Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, the selected email(s) are invalid. Please recheck them again.' 
                            when 'zh-CN' then N'抱歉,所選的電子郵件是無效的.請重新確認.'
                            when 'zh-TW' then N'抱歉，所选的电子邮件是无效的，请重新确认。'
                            else N'Sorry, the selected email(s) are invalid. Please recheck them again.' 
                        end,           
        @ErrCode = 102  
         return        
        END      
--Check UserID is valid  
if(not exists(select 1 from AdminUser (nolock) where custid=@UserID))  
begin  
  Select @ErrMsg = case @Language 
                            when 'en-US' then 'Sorry, Admin id is invalid. Please recheck it again.' 
                            when 'zh-CN' then N'抱歉, 管理員ID是無效的.請重新確認.'
                            when 'zh-TW' then N'抱歉，管理员ID是无效的，请重新确认。'
                            else N'Sorry, Admin id is invalid. Please recheck it again.' 
                        end,           
     @ErrCode = 103  
         return  
end  
  
  
Delete EmailHistory with(rowlock)  
WHERE mid in (select mid from @midTable)  
  
IF @@ERROR <> 0  
BEGIN  
   
 Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Email unsuccessfully deleted!' 
                            when 'zh-CN' then N'錯誤!電子郵件刪除不成功!'
                            when 'zh-TW' then N'错误！电子邮件删除不成功！'
                            else N'Error! Email unsuccessfully deleted!' 
                        end, @ErrCode = 1001  
 return  
END  
  
DECLARE @LogData nvarchar(200)  
SELECT @LogData = 'Delete EmailHistory Mail ID list:' + dbo.Aff_ToString(@listmid)  
  
declare @SPName varchar(50)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @TypeName= 'Email',   
 @SPName=@SPName,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_DomainControlUpd]    Script Date: 07/30/2013 04:21:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_DomainControlUpd    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE PROCEDURE [dbo].[Aff_DomainControlUpd]
    @ID int,
    @AffDomainID int,
    @MemberDomainID int,
    @CountryID nvarchar(10),
    @Status bit = 1,    
    @UserID int,    
    @IP nvarchar(15)='',
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Update Domain control info
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
    @custid=@UserID,@funcname='[Domain]',
    @System = 'AFFILIATE',
    @ErrCode=@ErrCode output,
    @ErrMsg=@ErrMsg output
    
If @ErrCode <> 0
    RETURN
-----------------------------------------------
If Exists(select 1 from AffDomainControl nolock where ID <> @ID and AffDomainID = @AffDomainID and [MemberDomainID] = @MemberDomainID and CountryID = @CountryID)
Begin
    select @ErrCode = 1001,
            @ErrMsg = case @Language 
                    when 'en-US' then 'Your domain setting is duplicate with other setting. Please check!' 
                    when 'zh-CN' then N'您的網域設定和另一個設定重複.請確認!'
                    when 'zh-TW' then N'您的网域设定和另一个设定重复。请确认！'
                    else N'Your domain setting is duplicate with other setting. Please check!' 
                end
    return
End

BEGIN TRANSACTION
Update [AffDomainControl] with (rowlock, updlock)
set
    [AffDomainID]    = @AffDomainID
    ,[MemberDomainID]= @MemberDomainID
    ,[CountryID]        = @CountryID
    ,[ModifyDate]    = current_timestamp
    ,[Status]        = @Status
    ,[Creator]        = @UserID
where ID = @ID

IF @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error occurs when update data.' 
                    when 'zh-CN' then N'更新資料發生錯誤'
                    when 'zh-TW' then N'更新资料发生错误'
                    else N'Error occurs when update data.' 
                end, @ErrCode = 1002
    return
END

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                     
                    + ' MemberDomainID:' + dbo.Aff_ToString(@MemberDomainID)                    
                    + ' CountryID:' + dbo.Aff_ToString(@CountryID)                    

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @UserID,
    @Typename = 'AffDomainControl', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourcesTranslationInsOrUpdate]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourcesTranslationInsOrUpdate    Script Date: 7/29/2013 1:41:16 AM ******/
-------------------------------------------------------------------------------------------------------------

CREATE Procedure [dbo].[Aff_ResourcesTranslationInsOrUpdate]
    @Updatedby int ,
    @Key varchar(50),
    @Value nvarchar(max),
    @Type varchar(50),
    @LanguageCode varchar(8),
    @Description nvarchar(100)= '',
    @IP nvarchar(15)='',
    @ID uniqueidentifier='00000000-0000-0000-0000-000000000000' OUTPUT,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[Resources]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
        
    IF @ErrCode <> 0
        RETURN
    
    DECLARE @SPName varchar(50), @Detail nvarchar(4000)
    SELECT @SPName = OBJECT_NAME(@@ProcID)
    DECLARE @TempID uniqueidentifier
 
    SELECT @TempID=ResourceID FROM RefResources (NOLOCK) 
                            WHERE RefID=@Type 
                            AND [LanguageCode]=@LanguageCode 
                            AND [ResourceKey]=@Key
    
    IF(@TempID IS NOT NULL)
        BEGIN
            UPDATE [dbo].[RefResources]
            SET [ResourceValue] = @Value
            WHERE [ResourceID] = @TempID

            SELECT @Detail = 'Update ResourceID:' + CAST(@TempID AS VARCHAR(40)) 
                    +  '\n RefID:'            + dbo.Aff_ToString(@Type)
                    +  '\n LanguageCode:'    + dbo.Aff_ToString(@LanguageCode)
                    +  '\n ResourceKey:'    + dbo.Aff_ToString(@Key)
                    +  '\n ResourceValue:'    + isnull(@Value,'')
                    +  '\n Description:'    + dbo.Aff_ToString(@Description)
        END
    ELSE
        BEGIN
                SELECT @ID = newid()
                    
                INSERT INTO [dbo].[RefResources]
                       ([ResourceID],
                        [RefID],
                        [LanguageCode],
                        [ResourceKey],
                        [ResourceValue],
                        [Description] )
                VALUES (@ID,@Type,@LanguageCode,@Key,@Value,@Description)    
                
                SELECT @Detail = 'Add new Resource. ID=' + dbo.Aff_ToString(@ID) + '.Key=' + dbo.Aff_ToString(@Key) + '.Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type) + '.Language=' + dbo.Aff_ToString(@LanguageCode)
                                + '.Description=' + dbo.Aff_ToString(@Description)

        END
        EXEC [dbo].[Aff_WriteLog] 
                @Creator = @Updatedby,
                @AffID = @Updatedby,
                @Typename = 'Resources',
                @SPName = @SPName,
                @Details = @Detail,
                @IP = @IP
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsIns]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsIns    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE PROCEDURE [dbo].[Aff_SystemSettingsIns]
    @Updatedby int ,
    @Key varchar(50),
    @Value nvarchar(max),
    @Type varchar(50)='',
    @Description nvarchar(100),    
    @IP nvarchar(15)='',
    @ID int=0 OUTPUT,
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Exists (Select 1 from SystemSettings (nolock) where SName=@key and Type=@Type))
BEGIN
Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error! This setting key is existed!' 
                    when 'zh-CN' then N'錯誤!這個設定金鑰已經存在!'
                    when 'zh-TW' then N'错误！这个设置金者已经存在！'
                    else N'Error! This setting key is existed!' 
                end, @ErrCode = 1001
    return
END
if (@Type in ('CustomerDomainList','AffiliateLinkDomainList','BannerDomainList'))
BEGIN
    INSERT INTO [dbo].[SystemSettings]
               ([SName]
               ,[SValue]
               ,[Type]
               ,[Description])
               
    Select     ResourceKey,@Value,@Type,@Description
    from(
        Select distinct ResourceKey
        From RefResources (nolock)
        Where RefID='CountryCode'   
    
    )a
    
    SELECT @ID = SCOPE_IDENTITY()
END
ELSE
BEGIN
    INSERT INTO [dbo].[SystemSettings]
               ([SName]
               ,[SValue]
               ,[Type]
               ,[Description])
         VALUES(@Key,@Value,@Type,@Description)

    SELECT @ID = SCOPE_IDENTITY()
END
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add new Sytem Setting. ID=' + dbo.Aff_ToString(@ID) + '.Key=' + dbo.Aff_ToString(@Key) + '.Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type)  + '. Description=' + isnull(@Description,'') 

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'SystemSettings', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsDel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsDel    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_SystemSettingsDel]
    @Updatedby int ,
    @IDList varchar(max),
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    

delete [dbo].[SystemSettings]
where SID in (select val from dbo.strsplit(@IDList, ',') ) and Type <> 'Meta'

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete Sytem Setting. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'SystemSettings', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourceKeyUpd]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourceKeyUpd    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE PROCEDURE [dbo].[Aff_ResourceKeyUpd]
    @Updatedby int ,
    @ID uniqueidentifier,
    @Value nvarchar(max),
    @Description nvarchar(100),    
    @IP nvarchar(15)='',    
    @Language varchar(5)= null, 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[Resources]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from RefResources (nolock) where ResourceID=@ID))
BEGIN
Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error! This key does not exists!' 
                    when 'zh-CN' then N'錯誤!這個金鑰不存在!'
                    when 'zh-TW' then N'错误！这个金者不存在！'
                    else N'Error! This key does not exists!' 
                end, @ErrCode = 1001
    return
END
if @Language is not null 
BEGIN
    update RefResources with (rowlock,updlock)
    Set ResourceValue=@Value, [Description]=@Description
    where ResourceID=@ID
END
ELSE -- update All language
BEGIN
    declare @Key varchar(50),@Type varchar(50)
    select @Key = ResourceKey, @Type = RefID from 
        dbo.RefResources where ResourceID=@ID
        
    update RefResources with (rowlock,updlock)
    Set ResourceValue=@Value, [Description]=@Description
    where RefID=@Type and [ResourceKey]=@Key
END
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update a Resource. ID= ' + dbo.Aff_ToString(@ID) + '. Value=' + isnull(@Value,'') + '. Description=' + isnull(@Description,'') 

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Resources', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourceKeyIns]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourceKeyIns    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_ResourceKeyIns]
    @Updatedby int ,
    @Key varchar(50),
    @Value nvarchar(max),
    @Type varchar(50),
    @LanguageCode varchar(8)=null,
    @Description nvarchar(100),
    @IP nvarchar(15)='',
    @ID uniqueidentifier='00000000-0000-0000-0000-000000000000' OUTPUT,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[Resources]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN

--Check Type
--Check LanguageCode
--Check Key
--Check Value
    
If(Exists (Select 1 from RefResources (nolock) where RefID=@Type and 
    (@LanguageCode is null or [LanguageCode]=@LanguageCode) and [ResourceKey]=@Key))
BEGIN
Select @ErrMsg = N'Error! This key is existed!', @ErrCode = 1001
    return
END

if @LanguageCode is not null 
BEGIN
    SELECT @ID = newid()
    INSERT INTO [dbo].[RefResources]
               ([ResourceID],
                [RefID],
                [LanguageCode],
                [ResourceKey],
                [ResourceValue],
                [Description] )
    values (@ID,@Type,@LanguageCode,@Key,@Value,@Description)            
END

INSERT INTO [dbo].[RefResources]
           ([ResourceID],
            [RefID],
            [LanguageCode],
            [ResourceKey],            
            [ResourceValue],
            [Description] )
Select newid(),@Type,[LanguageID] as LanguageCode,@Key,@Value,@Description            
from Language a (nolock) 
where (@LanguageCode is null or [LanguageID] <> @LanguageCode)
      and not exists (Select 1 from RefResources(nolock)
                        where RefID=@Type
                              and LanguageCode = a.LanguageID
                              and [ResourceKey]=@Key    
                     )
            

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add new Resource. Key=' + dbo.Aff_ToString(@Key) + '.Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type) + '.Language=' + dbo.Aff_ToString(@LanguageCode)
                + '.Description=' + dbo.Aff_ToString(@Description)

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Resources', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourceKeyDel]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourceKeyDel    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_ResourceKeyDel]
    @Updatedby int ,
    @IDList varchar(max),
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Delete unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[Resources]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
/*
Declare @Temp table(RefID varchar(50),ResourceKey varchar(50))
Insert into @Temp(RefID,ResourceKey)
Select distinct RefID,ResourceKey
from [dbo].[RefResources] (nolock)
where ResourceID in (select val from dbo.strsplit(@IDList, ',') )
*/
Delete r
From [dbo].[RefResources] r (nolock)
WHERE ResourceID in (select val from dbo.strsplit(@IDList, ','))
--inner join @Temp t on t.RefID=r.RefID and t.ResourceKey=r.ResourceKey

declare @SPName varchar(50), @Detail nvarchar(max) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Delete a Resource. IDList=' + isnull(@IDList,0)


EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Resources', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductUpd]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductUpd    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_ProductUpd]
    @Updatedby int ,
    @ProductID tinyint,
    @ProductName nvarchar(50),    
    @Description nvarchar(100)=NULL,        
    @BettypeList nvarchar(255),
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130122@Joseph
Task : Update Product
DB: DB052.Affiliate_MYM
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from Product (nolock) where ProductID=@ProductID ))
BEGIN
Select @ErrMsg = N'Error! This Product does not exist!', @ErrCode = 1001
    return
END
update Product with (rowlock,updlock)
Set ProductName=@ProductName, [Description]=@Description,
BettypeList =  @BettypeList
where ProductID=@ProductID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Product. ID= ' + dbo.Aff_ToString(@ProductID) +     
     '.BettypeList=' + @BettypeList

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Product', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductIns]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ProductIns    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_ProductIns]
    @Updatedby int ,
    @ProductName nvarchar(50),    
    @Description nvarchar(100)=NULL,    
    @BettypeList nvarchar(255)=NULL,    
    @IP nvarchar(15)='',    
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20130123@Joseph
Task : Insert Product
DB: DB052.Affiliate_MYM
Original:

Revisions:

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN

INSERT INTO [Product]
           (
           [ProductName]
           ,[Description]
           ,[Creator]
           ,[CreatedDate]
           ,[BettypeList])
     VALUES
           (
           @ProductName
           ,@Description
           ,@Updatedby
           ,CURRENT_TIMESTAMP
           ,@BettypeList)


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add New Product. ID= ' + dbo.Aff_ToString(SCOPE_IDENTITY()) +    
     '.BettypeList=' + @BettypeList

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'Product', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsUpd]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_SystemSettingsUpd    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE PROCEDURE [dbo].[Aff_SystemSettingsUpd]
    @Updatedby int ,
    @ID int,
    @Value nvarchar(max),
    @Type varchar(50)=NULL,
    @Description nvarchar(100),    
    @IP nvarchar(15)='',    
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_ZZun
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[SystemSettings]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
    
If @ErrCode <> 0
    RETURN
    
If(Not Exists (Select 1 from SystemSettings (nolock) where SID=@ID))
BEGIN
Select @ErrMsg = case @Language 
                    when 'en-US' then 'Error! This setting key does not exist!' 
                    when 'zh-CN' then N'錯誤!這個設定金鑰不存在!'
                    when 'zh-TW' then N'错误！这个设置金者不存在！'
                    else N'Error! This setting key does not exist!' 
                end, @ErrCode = 1001
    return
END
update SystemSettings with (rowlock,updlock)
Set SValue=@Value, Type=coalesce(@Type,Type), [Description]=@Description
where SID=@ID 


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update Sytem Setting. ID= ' + dbo.Aff_ToString(@ID) + '. Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type)  + '. Description=' + isnull(@Description,'') 

EXEC [dbo].[Aff_WriteLog] 
    @Creator = @Updatedby,
    @AffID = @Updatedby,
    @Typename = 'SystemSettings', -- refer to table LogType
    @SPName = @SPName,
    @Details = @Detail,
    @IP = @IP
    
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_StatementHistorySel]    Script Date: 07/30/2013 04:21:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_StatementHistorySel    Script Date: 7/29/2013 1:41:16 AM ******/
CREATE Procedure [dbo].[Aff_StatementHistorySel]    
 @AffId int,    
 @TransType int = -1,     
 @FDate smalldatetime = null,    
 @TDate smalldatetime = null,    
 @PageSize int=50,    
 @PageIndex int=1,    
 @TotalPages int=0 OUTPUT,    
 @NRows int=0 OUTPUT    
AS    
/*Created: 20090901@Peter  
Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)  
DB:   
Original: [Aff_CustomerSelStatementHistory]    
Revisions:     
Param's Explanation:    
• @AffID : Affiliate custid    
• @TransType :   
             + 201 : Monthly Winlost  
             + 202 : Payment Request  
             + 203 : Adjustment    
             + -1 : Get all   
• @FDate : search From date (null: get all)  
• @TDate : search To date    (null: get all)  
• @PageSize : Size of page  
• @PageIndex : current page  
• @TotalPages : number of pages  
• @NRows : number of rows  
*/    
SET NOCOUNT ON  
if (@FDate is not null and @TDate is not null and @FDate>@TDate)  
  return   
if(@TDate>current_timestamp)  
  select @TDate=current_timestamp  
    
if @FDate is not null  
  set @FDate=dbo.Aff_GetStartDate(@FDate)  
  
if  @TDate is not null  
  set @TDate= dbo.Aff_GetEndDate(@TDate)  
    
    
declare @AffTrans table(TransId bigint, MonthDate SmallDatetime, TransType int, Amount money, Status varchar(20), Creator nvarchar(50), Description nvarchar(300))  
declare @Month int,  
       @Year int,  
       @Amount money,   
       @Currentdate datetime,  
       @NetPercentReceived float  
  select @NetPercentReceived=1.0,@CurrentDate=current_timestamp        
  
if (@FDate is null or @TDate is null or @Currentdate between @FDate and @TDate)  
begin  
exec [dbo].[Aff_CalMonthlyEarningCurrent]   
@AffID =@AffID,  
@Amount=@Amount OUTPUT  
  
insert into @AffTrans  
select 0 as TransID,current_timestamp as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'Current Month Statistics' as Description                
  
end  
  
--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc  
if(not exists (select top(1) 1 from AffCommission with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0) and   
  datediff(m,(select ApprovedDate from AffInfo with (nolock) where AffID=@AffID),@CurrentDate) >=1  
  and exists (select top(1) 1 from AffDailySummary with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0)  
   and (@FDate is null or @TDate is null or dateadd(m,-1,@CurrentDate) between @FDate and @TDate)  
  )  
BEGIN  
  select @Month=month(dateadd(m,-1,@CurrentDate)),@Year=Year(dateadd(m,-1,@CurrentDate))  
  exec [dbo].[Aff_CalMonthlyEarning]   
  @AffID =@AffID,  
  @Month=@Month,  
  @Year=@Year,  
  @Amount=@Amount OUTPUT  
  
  insert into @AffTrans  
  select 0 as TransID,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(m,-1,@CurrentDate))+1,0)) as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'UnCalculated Month' as Description   
END  
  
  
  
insert into @AffTrans  
 select a.TransID, a.TransDate as MonthDate, a.TransType,(case when transtype=202 then abs(a.Amount) else a.Amount end) as Amount,(case when transtype=201 or transtype=203 then 'B/F' else a.Status end) as  Status, isnull(i.username,'System') as Creator, (
case when transtype=202 then ap.AdminDesc else a.Description end)  
     from AffTrans a (nolock)  
     left join AffPayout ap (nolock) on ap.RefID=a.RefID  
     left join AdminUser i with (nolock) on i.custid=a.Creator     
       
where a.AffID=@AffID  
  and (@TransType=-1 or TransType=@TransType)  
  and (@FDate is null or @TDate is null or (case when TransType=201 or a.CompletedDate Is null then a.TransDate else a.CompletedDate end ) between @FDate and @TDate)  
 and a.status in ('pending','approved','completed')  
  ORDER BY (case when a.status='pending' then 1 else 2 end), a.CompletedDate desc,a.TransType desc, a.TransID desc  
    
    
  
select @NRows=count(*) from @AffTrans  
--Add more row if the month is completed but not transfer yet  
     
DECLARE @RowStart int, @RowEnd int   
  
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,  
@PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1     
    
select TransId, MonthDate, TransType, Amount, Status, Creator, Description  
from    
 (  
  select ROW_NUMBER() OVER(ORDER BY MonthDate desc) AS TheCount,   
   TransId, MonthDate, TransType, Amount, Status, Creator, Description  
  from @AffTrans  
 )m    
where m.TheCount between @RowStart and @RowEnd  order by monthdate desc
GO
/****** Object:  StoredProcedure [dbo].[Aff_ResourcesTranslationInsOrUpdateXML]    Script Date: 07/30/2013 04:21:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_ResourcesTranslationInsOrUpdateXML    Script Date: 7/29/2013 1:41:17 AM ******/
----------------------------------------------------------------------------------------------------
/*Insert Or Update Translation Resource from excel file*/

CREATE Procedure [dbo].[Aff_ResourcesTranslationInsOrUpdateXML]
    @Updatedby int ,
    @XmlData XML,--<root><res><key></key><type></type><value></value><code></code><des></des></res></root>
    @IP nvarchar(15)='',
    @ID uniqueidentifier='00000000-0000-0000-0000-000000000000' OUTPUT,
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(4000) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    
    EXEC [dbo].[Aff_Con_CheckPermission]
        @custid=@Updatedby,@funcname='[Resources]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output,
        @ErrMsg=@ErrMsg output    
        
    IF @ErrCode <> 0
        RETURN
    IF(@XmlData IS NULL)
        BEGIN
            SELECT @ErrMsg = N'Error! Data xml is empty!', @ErrCode = 1002
            RETURN
        END
    DECLARE @ResourceKey VARCHAR(50)
    DECLARE @ResourceValue NVARCHAR(MAX)
    DECLARE @RefID VARCHAR(50)
    DECLARE @LanguageCode VARCHAR(8)
    DECLARE @Description NVARCHAR(100)
    
    DECLARE @HandleID INT
    EXEC sp_xml_preparedocument @HandleID OUTPUT, @XmlData
    
    DECLARE XmlCursor CURSOR FOR
    SELECT * FROM OPENXML (@HandleID, '/root/res', 3) 
    WITH 
      (ResourceKey VARCHAR(50) 'key',
       ResourceValue NVARCHAR(MAX) 'value',
       RefID VARCHAR(50) 'type',
       LanguageCode VARCHAR(8) 'code',
       Description NVARCHAR(100) 'des'
      )

    OPEN XmlCursor
    FETCH NEXT FROM XmlCursor INTO @ResourceKey,@ResourceValue,@RefID,@LanguageCode,@Description

    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC Aff_ResourcesTranslationInsOrUpdate @Updatedby,@ResourceKey,@ResourceValue,@RefID,@LanguageCode,@Description,@IP,@ID OUTPUT,@ErrCode OUTPUT,@ErrMsg OUTPUT
        IF (@ErrCode <> 0)
        BEGIN
            CLOSE XmlCursor
            DEALLOCATE XmlCursor
            EXEC sp_xml_removedocument @HandleID
            RETURN 
        END
        FETCH NEXT FROM XmlCursor INTO @ResourceKey,@ResourceValue,@RefID,@LanguageCode,@Description
    END

    CLOSE XmlCursor
    DEALLOCATE XmlCursor
    EXEC sp_xml_removedocument @HandleID
    
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminIns]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminIns    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_AdminIns] 
    @FirstName nvarchar(50),
    @LastName nvarchar(50),    
    @UserName nvarchar(50),
    @UserPwd nvarchar(50) = '',
    @CustID int OUTPUT,
    @UserID int,
    @GroupID int,    
    @IP varchar(15) = '',
    @Language varchar(5)= 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS
--Used to create AccAdmin
--In DB02.bodb02 --> DB052.Affiliate_ZZun
SET NOCOUNT ON

/*
Created: 
Task : Add account in User control 
DB: DB02.bodb02
Original:

Revisions:
    - 20080213@Phuc: Check permission for account site
    - 20090218@PhuongDao: Check username2 
    - 20100713@Peter : Remove Write Log on IBC DB
    - 20101112@Henry: add Maxperball161
    - 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
Param's Explanation:
• @ErrCode:
    = 0: super create master successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

--Check permission for account site: @phuc20080213
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@userid,@funcname='[UserControl]',@System = 'AFFILIATE', @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
    RETURN
--end


Declare @pwdexpiry datetime, @roleid int, @closed bit

Select @RoleID = 6,
    @pwdexpiry =  DATEADD(month,1,CURRENT_TIMESTAMP),
    @closed = 0
    
if exists(select 1 from AdminUser with (NOLOCK) where username=@username) 
BEGIN
    SELECT @ErrMsg = case @Language 
                        when 'en-US' then 'This username is not available.'
                        when 'zh-CN' then N'這個使用者名稱不存在'
                        when 'zh-TW' then N'这个使用者名称不存在'
                        else N'This username is not available.'
                    end, @ErrCode = 102
    return
END

BEGIN TRANSACTION

    INSERT INTO AdminUser (username, UserPwd, roleid, firstname, lastname, creator, pwdexpiry,closed,GroupId,createdate) 
    VALUES (@username, @userpwd, @roleid, @firstname, @lastname, @UserID, @pwdexpiry,@closed,@GroupID,getdate()) 

    Select @CustID = @@IDENTITY

    
    if @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        select @ErrMsg = case @Language 
                        when 'en-US' then 'Add customer failed.'
                        when 'zh-CN' then N'這個使用者名稱不存在'
                        when 'zh-TW' then N'这个使用者名称不存在'
                        else N'Add customer failed.'
                    end, @ErrCode = 103    
        return
    END

COMMIT TRANSACTION     

EXEC dbo.Aff_Con_AdminPolicyIns @CustID=@Custid,@Userid=@UserID,@GroupID=@GroupID,@IP=@IP


DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'NEW AFFILIATE Admin custid:' + dbo.Aff_ToString(@custid) + ' username:' + @UserName + ' GroupID:' + dbo.Aff_ToString(@GroupID)


EXEC [dbo].[Aff_WriteLog]
        @Creator=@UserID,    
        @AffID=@CustID,
        @Typename= 'UserControl',    
        @SPName=@SPName ,        
        @IP =@IP,
        @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_CommGroupIns]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_CommGroupIns    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_CommGroupIns]  
 @UserId int,  
 @GroupId int =-1 Output,  
 @Currency varchar(5),  
 @QualifiedAmount money,  
 @GroupName nvarchar(100),  
 @Description nvarchar(100),  
 @ProductIDList varchar(300),  
 @DeductionList varchar(300),  
 @DeductedPercentageList varchar(300),  
 @TierList varchar(300),  
 @MinAmountList varchar(5000),  
 @MaxAmountList varchar(5000),  
 @MinQMList varchar(5000),  
 @MaxQMList varchar(5000),  
 @CommissionList varchar(5000),  
 @IsApproved bit=0,  --used for approved a user with a private group  
    @Password varchar(40)=null,  
 @IP varchar(20),  
 @MailOption bit = false OUTPUT,  
 @AffType tinyint = 1 output,
 @Language varchar(5)= 'en-US',
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT   
AS  
/*  
Created: 20090719@DungTong  
Task : Add a new Commission Group  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
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
     .@IsApproved: 1 if we want to approved this aff and create a new group  
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
if(@ErrMsg<>'')  
  return  
  
if (@GroupId>1000)  
begin  
   if(exists (select 1 from CommGroup (nolock) where GroupID=@GroupID and IsDeleted=0))  
    begin  
      select @ErrCode=101,@ErrMsg = case @Language 
                            when 'en-US' then 'The group ID ' +  cast(@GroupId as varchar(10)) + ' is not existed. Please check.' 
                            when 'zh-CN' then N'這個群組ID ' +  cast(@GroupId as varchar(10)) + '已經不再存在.請確認.'
                            when 'zh-TW' then N'这个群组ID ' +  cast(@GroupId as varchar(10)) + '已经不再存在。请确认。'
                            else N'The group ID ' +  cast(@GroupId as varchar(10)) + ' is not existed. Please check.' 
                        end        
      return  
    end  
   else if(@IsApproved=0 and not exists (select 1 from AffInfo (nolock) where AffID=@GroupID and status='approved'))  
     begin  
  select @ErrCode = 102, 
        @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Group ID. Please check.' 
                            when 'zh-CN' then N'無效的 Group ID ' +  cast(@GroupId as varchar(10)) + '. 請確認.'
                            when 'zh-TW' then N'无效的 Group ID ' +  cast(@GroupId as varchar(10)) + '请确认。'
                            else N'Invalid Group ID. Please check.' 
                        end     
  return   
     end  
    else if(@IsApproved=1 and not exists (select 1 from AffInfo (nolock) where AffID=@GroupID and status in ('disapproved','pending') and currency=@currency))  
        begin  
    select @ErrCode = 103, @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid Group ID. Please check.' 
                            when 'zh-CN' then N'無效的 Group ID ' +  cast(@GroupId as varchar(10)) + '. 請確認.'
                            when 'zh-TW' then N'无效的 Group ID ' +  cast(@GroupId as varchar(10)) + '请确认。'
                            else N'Invalid Group ID. Please check.' 
                        end      
    return   
         end   
end   
  
if(@GroupName is null or LTRIM(RTRIM(@GroupName))='')  
  begin  
 select @ErrCode = 10030, @ErrMsg = case @Language 
                            when 'en-US' then 'Group name is empty. Please choose a name!' 
                            when 'zh-CN' then N'群組名稱是空白.請選擇一個名稱!'
                            when 'zh-TW' then N'群组名称是空白。请选择一个名称！'
                            else N'Group name is empty. Please choose a name!' 
                        end    
 return  
 end  
  
   
if (@GroupID=-1 and exists (select 1 from CommGroup where GroupName = @GroupName  and IsDeleted=0))  
begin  
 select @ErrCode = 10031, @ErrMsg = case @Language 
                            when 'en-US' then 'Group name existed. Please choose another name!' 
                            when 'zh-CN' then N'群組名稱已經存在.請選擇另一個名稱!'
                            when 'zh-TW' then N'群组名称已经存在，请选择另一个名称！'
                            else N'Group name existed. Please choose another name!' 
                        end      
 return  
end  
  
--Check Qualified Amount  
if(@QualifiedAmount<0)  
  begin  
 select @ErrCode = 10032, 
        @ErrMsg = case @Language 
                            when 'en-US' then 'Invalid qualified amount. Please check.' 
                            when 'zh-CN' then N'無效的合格的總數. 請確認.'
                            when 'zh-TW' then N'无效的合格的总数. 请确认。    '
                            else N'Invalid qualified amount. Please check.' 
                        end     
 return  
 end  
  
  
declare @Identity int   
select @Identity=max(GroupID) from CommGroup (nolock) where GroupID<1000   
if(@Identity is null)  
     select @Identity=100          
 if(@Identity=999 and (@GroupID<0 or @GroupID is null))  
 begin  
 select @ErrCode = 102, 
        @ErrMsg = case @Language 
                            when 'en-US' then 'There is no room for a new Group! Please contact to administrator' 
                            when 'zh-CN' then N'無效的合格的總數. 請確認.'
                            when 'zh-TW' then N'无效的合格的总数. 请确认。    '
                            else N'There is no room for a new Group! Please contact to administrator' 
                        end      
 return  
 end  
  
  
Begin transaction               
    --For Special Group   
     
 /*   if(@GroupID>1000)  
    begin              
           
 SET IDENTITY_INSERT CommGroup ON         
   insert into CommGroup([GroupID],[GroupName], [CreatedDate], [Creator], [IsDeleted], [Description])  
   values(@GroupID,@GroupName, current_timestamp, @UserId, 0, @Description)     
   SET IDENTITY_INSERT CommGroup OFF       
      DBCC checkident('CommGroup', RESEED, @Identity) -- reset the identity number start from the max of groupID<1000  
  
  
 end  
 else --For Normal Group  
  begin              
  insert into CommGroup([GroupName], [CreatedDate], [Creator], [IsDeleted], [Description])  
   values(@GroupName, current_timestamp, @UserId, 0, @Description)   
   SELECT @GroupId = SCOPE_IDENTITY()  
         
  end*/  
    if(@GroupID<=0)  
    begin    
  set @GroupID=@Identity + 1  
 end   
  
    insert into CommGroup([GroupID],[GroupName], [CreatedDate], [Creator], [IsDeleted], [Description],QualifiedAmount,Currency)  
     values(@GroupID,@GroupName, current_timestamp, @UserId, 0, @Description,@QualifiedAmount,@Currency)     
  
 IF @@ERROR <> 0  
 BEGIN  
  ROLLBACK TRANSACTION  
  Select @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Insert unsuccessfully.'
                        when 'zh-CN' then N'錯誤發生.插入不成功'
                        when 'zh-TW' then N'错误发生。插入不成功'
                        else N'Error occurs.Insert unsuccessfully.!'
                    end, @ErrCode = 10031  
  return  
 END  
   
 --Insert Deduction Setting  
  if(len(@DeductionList)>0)  
    begin  
        Insert into DeductionSetting(GroupID,DeductionID,DeductedPercentage)  
  select @GroupID,cast(t.val as tinyint),cast(p.val as float)  
  from dbo.strsplit(@DeductionList, ',') t  
      inner join dbo.strsplit(@DeductedPercentageList, ',') p on p.rank=t.rank      
   inner join DeductionType d with (nolock) on d.DTypeID=cast(t.val as tinyint)      
    
  IF @@Rowcount<>(select count(1) from dbo.strsplit(@DeductionList, ',')) or @@ERROR <> 0  
  BEGIN  
   ROLLBACK TRANSACTION  
   Select @ErrMsg = case @Language 
                        when 'en-US' then 'Error! Insert Deduction Setting unsuccessfully!'
                        when 'zh-CN' then N'錯誤發生.插入不成功'
                        when 'zh-TW' then N'错误发生。插入不成功'
                        else N'Error! Insert Deduction Setting unsuccessfully!'
                    end, @ErrCode = 10032  
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
             ROLLBACK TRANSACTION  
          Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Tier List!' 
                            when 'zh-CN' then N'錯誤!無效的一線層名單!'
                            when 'zh-TW' then N'错误！无效的一线层名单！'
                            else N'Error! Invalid Tier List!' 
                        end, @ErrCode = 10035  
          return  
          end  
          if(@NTier>50)  
          begin  
             ROLLBACK TRANSACTION  
          Select @ErrMsg = case @Language 
                            when 'en-US' then 'Oops, maximum of 50 tiers are allowed!' 
                            when 'zh-CN' then N'允許最多50層'
                            when 'zh-TW' then N'允许最多50层'
                            else N'Oops, maximum of 50 tiers are allowed!' 
                        end, @ErrCode = 10085  
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
               Insert into GroupSetting(GroupID,ProductID,TierID,MinAmount,MaxAmount,MinQM,MaxQM,Commission)  
               values (@GroupID,@ProductID,@i,@MinAmount,@MaxAmount,@MinQM,@MaxQM,@Commission)  
         --Neu khong dong nao duoc insert thi Rollback <=> @@ROWCOUNT<>1   
         if(@@ROWCOUNT<>1)  
         begin  
            ROLLBACK TRANSACTION  
            Select @ErrMsg = case @Language 
                            when 'en-US' then 'There was an error when inserting tier setting.' 
                            when 'zh-CN' then N'當設定層級時,出現錯誤.'
                            when 'zh-TW' then N'当设定层级时，出现错误。'
                            else N'There was an error when inserting tier setting.' 
                        end, @ErrCode = 10037  
            return    
         end    
            end  
          else  
            begin  
         ROLLBACK TRANSACTION  
         Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Setting Data(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                            when 'zh-CN' then N'誤!無效的資料設定(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                            when 'zh-TW' then N'错误！无效的资料设定(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                            else N'Error! Invalid Setting Data(ProductID=' + cast(@ProductID as nvarchar(5)) + '.TierID=' + cast(@i as nvarchar(5)) +  ')!' 
                        end, @ErrCode = 10037  
         return    
             end    
                  --Increase @i by 1   
                  select @i=@i + 1                                     
         end --end inner while  
             
         select @rank=min(rank) from dbo.strsplit(@ProductIDList, ';') where rank>@rank  
        END TRY  
        BEGIN CATCH  
       ROLLBACK TRANSACTION  
       Select @ErrMsg = ERROR_MESSAGE(), @ErrCode = 10034  
       return   
        END CATCH  
        
     end --end outer while  
  end --end if  
    else ---Invalid Setting Data  
      begin  
  ROLLBACK TRANSACTION  
  Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Invalid Setting Data (ProductIDList) !' 
                            when 'zh-CN' then N'錯誤!無效的資料設定 (ProductIDList) !' 
                            when 'zh-TW' then N'错误！无效的资料设定 (ProductIDList) !' 
                            else N'Error! Invalid Setting Data (ProductIDList) !' 
                        end, @ErrCode = 10033  
  return   
      end      
--Approved user if @IsApproved=1  
if(@IsApproved=1 and @GroupID>1000)  
begin  
 exec dbo.[Aff_AffiliateUpdStatus]  
 @AffID =@GroupID,  
 @UserID =@UserId,  
 @Status ='approved',   
 @Password=@Password,    
 @GroupID =@GroupID,   
 @IP =@IP,   
 @ErrCode = @ErrCode OUTPUT,  
 @ErrMsg = @ErrMsg OUTPUT  
   if(@ErrCode<>0)  
 begin  
  ROLLBACK TRANSACTION  
  return  
 end    
 Select @MailOption = MailOption,@AffType = AffType 
 From AffDetail ad with(nolock) 
    inner join AffInfo ai with (nolock) on ad.AffId = ai.AffId
 where ai.AffId = @GroupID-- Get relevant Email Format  
end  
--Assign Group for Affiliate if GroupID>1000  
else if(@GroupID>1000)  
begin  
 update AffInfo with (rowlock,updlock)  
    set GroupID=@GroupID  
    where AffID=@GroupID  
    IF @@ERROR <> 0  
 BEGIN  
   ROLLBACK TRANSACTION  
   Select @ErrMsg = case @Language 
                            when 'en-US' then 'Error! Assign group for Affiliate unsuccessfully!' 
                            when 'zh-CN' then N'錯誤!安排給工作夥伴的群組不成功!' 
                            when 'zh-TW' then N'错误！安排给工作伙伴的群组不成功！' 
                            else N'Error! Assign group for Affiliate unsuccessfully!' 
                        end, @ErrCode = 10042  
   return  
 END  
end  
  
commit transaction  
 --Write the log   
DECLARE @LogData nvarchar(4000), @AffID int,@SPName varchar(100)  
if (@GroupID>1000)  
  select @AffID=@GroupID  
else  
  select @AffID=0    
SELECT @LogData = N'Add a commission group.GroupID=' + dbo.Aff_ToString(@GroupID)  
                  + '\n GroupName=' + dbo.Aff_ToString(@GroupName)  
                  + '\n Currency' + dbo.Aff_ToString(@Currency)  
                  + '\n QualifiedAmount=' + dbo.Aff_ToString(@QualifiedAmount)  
                  + '\n Description=' + dbo.Aff_ToString(@Description)  
                  + '\n ProductIDList=' + dbo.Aff_ToString(@ProductIDList)  
                  + '\n DeductionList=' + dbo.Aff_ToString(@DeductionList)  
                   + '\n DeductedPercentageList=' + dbo.Aff_ToString(@DeductedPercentageList)  
                  + '\n TierList=' + dbo.Aff_ToString(@TierList)  
                  + '\n MinAmountList=' + dbo.Aff_ToString(@MinAmountList)  
                  + '\n MaxAmountList=' + dbo.Aff_ToString(@MaxAmountList)  
                  + '\n MinQMList=' + dbo.Aff_ToString(@MinQMList)  
                  + '\n MaxQMList=' + dbo.Aff_ToString(@MaxQMList)  
                  + '\n CommissionList=' + dbo.Aff_ToString(@CommissionList)  
                    
             
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'CommissionGroup',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateUpdClosedStatus]    Script Date: 07/30/2013 04:21:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateUpdClosedStatus    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE Procedure [dbo].[Aff_AffiliateUpdClosedStatus]  
 @affid int,  
 @userid int,  
 @closed bit,  
 @ip varchar(20),  
    @Language varchar(5)= 'en-US', 
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS    
/*Created: 20090321@Peter  
Task : [description of SP]  
DB: DB052.Affiliate_ZZun  
Original : [Aff_AffiliateUpdClosedStatus]  
Revisions:  
Param's Explanation:  
• @affid : Affiliate id  
• @userid : User update  
• @closed : Status of affiliate.  
. @ip : Ip of Admin user  
*/  
SET NOCOUNT ON  
/*EXEC [dbo].[Aff_Con_CheckPermission]   
 @custid=@UserID,@funcname='[Affiliate]',  
 @System = 'AFFILIATE',  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output*/  
   
EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@UserID,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
   
If @ErrCode <> 0  
 RETURN  
--this is use for change to noncommission group when close affiliate.  
--20100904@Johnny: no need to use this anymore, SP: "Aff_CommGroupAssign" is assign funcname: "affiliate"  
/*if @Closed = 1  
Begin  
 --Check permission whether this user has [CommissionGroup] right  
 EXEC [dbo].[Aff_Con_CheckPermission]  
  @custid=@UserID,@funcname='[CommissionGroup]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output  
 If @ErrCode <> 0  
    RETURN  
end*/  
  
Declare @LoginCount int, @Old_Closed bit, @RefNo bigint  
select @LoginCount = LoginCount    
from AffDetail with (nolock)    
where AffID = @affid    
    
select @Old_Closed=IsClosed  
from AffInfo with (nolock)    
where AffID = @AffID   
  
--This account is closed because last try to login failed more than 5 times    
--So no need top update this just temporarily lock  
IF @Old_Closed = @Closed and @LoginCount > 5    
  return    
  
Update AffInfo with(rowlock,updlock) set [IsClosed]=@closed where affid=@affid  
IF @@error<>0   
Begin  
 SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Error occurs. Update process is unsuccessful!'
                            when 'zh-CN' then N'出現錯誤.更新過程不成功!'
                            when 'zh-TW' then N'出现错误。更新过程不成功！'
                            else N'Error occurs. Update process is unsuccessful!'
                        end, @ErrCode = 1005  
 RETURN  
END  
  
if @Closed = 1  
Begin  
 Declare @NoCommGroupId int, @AffList nvarchar(200)  
 select @NoCommGroupId = GroupId from CommGroup with (nolock) where GroupName = 'NoCommission'  
   
 select @AffList = cast(@affid as nvarchar(20))  
  
 Exec Aff_CommGroupAssign  
  @UserId = @userid,  
  @GroupId = @NoCommGroupId,  
  @AffIDList = @AffList,      
  @IP = @ip,  
  @ErrCode = @ErrCode OUTPUT,  
  @ErrMsg = @ErrMsg OUTPUT,  
  @RefNo = @RefNo OUTPUT  
    
 IF @@error<>0   
  RETURN  
End  
  
--admin allow to loginable again  
IF @Old_Closed = 1 and @Closed = 0 and @LoginCount > 5    
begin  
  update AffDetail with (ROWLOCK, UPDLOCK) set LoginCount = 0    
  where affid = @affid  
  IF @@error<>0   
      BEGIN  
     SELECT @ErrMsg = case @Language 
                            when 'en-US' then 'Error occurs. Update process is unsuccessful!'
                            when 'zh-CN' then N'出現錯誤.更新過程不成功!'
                            when 'zh-TW' then N'出现错误。更新过程不成功！'
                            else N'Error occurs. Update process is unsuccessful!'
                        end, @ErrCode = 1006  
   RETURN  
  END  
 end  
   
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
SELECT @LogData = 'Update Affiliate''s Closed Status. '  
                  + 'IsClosed=' + dbo.Aff_ToString(@Closed)  
  
select @SPName=OBJECT_NAME(@@ProcID)  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserId,   
 @AffID=@AffID,  
 @Typename= 'UserInfo',   
 @SPName=@SPName ,  
 @IP =@IP,  
 @RefNo = @RefNo,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_Con_AdminUpd]    Script Date: 07/30/2013 04:21:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_Con_AdminUpd    Script Date: 7/29/2013 1:41:17 AM ******/
CREATE PROCEDURE [dbo].[Aff_Con_AdminUpd]
    @CustID int,
    @FirstName nvarchar(50),
    @LastName nvarchar(50),
    @UserID int,
    @GroupID int,
    @IP varchar(15) = '',
    @Language varchar(5)= 'en-US',
    @ErrCode int = 0 OUTPUT,
    @ErrMsg nvarchar(200) = '' OUTPUT
AS

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
--DB02.BODB02 -->  DB052.Affiliate_ZZun
-- 20101214@Peter : Move this SP to DB DB052.Affiliate_ZZun
EXEC [dbo].[Aff_Con_CheckPermission] @custid=@UserID,@funcname='[UserControl]',@System='AFFILIATE',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
    RETURN
--end
EXEC dbo.Aff_Con_AdminGroupUpd @CustID=@CustID,@UserID=@UserID,@GroupID=@GroupID,@Language=@Language,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
IF @ErrCode<> 0
    RETURN 
    
BEGIN TRANSACTION
UPDATE AdminUser with (ROWLOCK, UPDLOCK) SET firstname = @FirstName, LastName = @LastName WHERE custid = @custid
IF  @@ERROR <> 0
BEGIN
    ROLLBACK TRANSACTION
    select @ErrMsg = case @Language 
                        when 'en-US' then 'Error occurs.Update unsuccessfully.'
                        when 'zh-CN' then N'Error occurs.Update unsuccessfully.'
                        when 'J' then N'Error occurs.Update unsuccessfully.'
                        else N'Error occurs.Update unsuccessfully.'
                    end, @ErrCode = 102
    RETURN
END
COMMIT TRANSACTION



DECLARE @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)

SELECT @LogData = 'AFFILIATE UPDATE AccAdmin custid:' + dbo.Aff_ToString(@custid) + ' Name:' + dbo.Aff_ToString(@firstname) + ' '  + dbo.Aff_ToString(@lastname) + ' GroupID:' + dbo.Aff_ToString(@groupid)


EXEC [dbo].[Aff_WriteLog]
        @Creator=@UserID,    
        @AffID=@CustID,
        @Typename= 'UserControl',    
        @SPName=@SPName ,        
        @IP =@IP,
        @Details=@LogData
GO
GRANT EXECUTE ON [dbo].[Aff_AddAffCurrencies] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AddAffCurrencies] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AddExchanges] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AddExchanges] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdjustmentIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdjustmentIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminLogin] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminLogin] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminLogin] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminLogin] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminNoteUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminNoteUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSelDBTime] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSelDBTime] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSelDBTime] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminSelDBTime] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSupportedLanguagesSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSupportedLanguagesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminSupportedLanguagesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminSupportedLanguagesSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AdminUpdPwd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AdminUpdPwd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCommReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateCommReport] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCurrenciesSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCurrenciesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCurrenciesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateCurrenciesSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateForgotPwd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateForgotPwd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateInsClickStatistics] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInternalLogin] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateInternalLogin] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateLinkDomainSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateLinkDomainSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateLinkDomainSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateLinkDomainSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateLogin] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateLogin] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateLogin] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateRecoverPwd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateReport] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateReportDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateReportDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelAffInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelAffInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelAffInfo] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelAffInfo] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelEditInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelEditInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelEditInfo] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelEditInfo] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelFavorite] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelFavorite] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelGeneralInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelGeneralInfo] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelLog] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelLog] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelLogType] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelLogType] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelMemberList] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelMemberList] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelMemberList] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelMemberList] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelTrackingCode] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatementHistorySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatementHistorySel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatementHistorySel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatementHistorySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatistics] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatistics] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatisticsDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatisticsDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateStatisticsDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateStatisticsDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSupportedLanguagesSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSupportedLanguagesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSupportedLanguagesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSupportedLanguagesSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUnlockMultiple] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUnlockMultiple] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUnlockMultiple] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdClosedStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdClosedStatus] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdInfo] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdPwd] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdPwd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdPwd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdStatus] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffInfo_UpdAffType] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffInfo_UpdAffType] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffInfo_UpdAffType] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffInfo_UpdAffType] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffSelDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffSelDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffSelDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffSelDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffTypeSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSelAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSelAll] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSelAll] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffTypeSelAll] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSelByID] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSelByID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeSelByID] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffTypeSelByID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffTypeUpd] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffTypeUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerDel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerDelType] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerIns] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerIns] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerInsType] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelInfo] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelInfo] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelType] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelType] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelType] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelType] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerUpd] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerUpdateStatistic] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerUpdateStatistic] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerUpdateStatistic] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerUpdateStatistic] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerUpdType] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrenciesSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrenciesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_BaseCurrenciesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BaseCurrenciesSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarning] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarning] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarning] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CalMonthlyEarning] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CalMonthlyEarningCurrent] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckIn] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckIn] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckMemberExist] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckMemberExist] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckNickname] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckPermissionOnAff] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckPermissionReadOnAff] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckPermissionReadOnAff] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CheckPermissionReadOnAff] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckPermissionReadOnAff] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ClickStatisticsDetailBySite] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelByPage] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ClickStatisticsSelByPage] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ClickStatisticsSelBySite] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ClickStatisticsSelBySite] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupAssign] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupAssign] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelCommonSetting] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelCommonSetting] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelListNormal] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelListNormal] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelListNormal] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelListNormal] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminGroupUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminGroupUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicyIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminPolicyIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicySelByCustID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminPolicySelByCustID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminPolicyUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminPolicyUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminSelByCustID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminSelByCustID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminSelByGroupID] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminSelByGroupID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_AdminUpdClosed] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_AdminUpdClosed] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_Batch_AdminPolicySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_Batch_AdminPolicySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_CheckPermission] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_CheckPermission] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_CheckPermissionRead] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_CheckPermissionRead] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_FuncInfoIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoIns] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoSelByFuncID] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoSelParent] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_FuncInfoUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupInfoDel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupInfoIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupInfoSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupInfoSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupInfoUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupPolicySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupPolicySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupPolicyUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupPolicyUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Con_GroupPolicyUpd] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Con_GroupPolicyUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CopyRateFromMarket] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CopyRateFromMarket] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CopyRateFromMarket] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CopyRateFromMarket] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CountrySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySelAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySelAll] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CountrySelAll] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CountrySelAll] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyListSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyListSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CurrencyListSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CurrencyListSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerInsMemberManually] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerInsMemberManually] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelAffUsename] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerSelBalBF] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelBalBF] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerSelOnline] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerUdpSecurityQuestion] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DeductedPercentSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffClientSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffClientSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffClientSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffClientSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainAffUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainAffUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDaily] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EarningSelDaily] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EarningSelDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EarningSelDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistoryDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EmailHistoryDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistoryIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EmailHistoryIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistorySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistorySel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_EmailHistorySel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_EmailHistorySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeAutoRefreshUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeAutoRefreshUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeUpdate] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeUpdate] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_FavoriteDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_FavoriteDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_FavoriteIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_FavoriteIns] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GenUsername] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMaxAdjustmentAmount] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetMaxAdjustmentAmount] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMembers] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMembers] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMembers] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetMembers] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetMemberStatistics] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetMemberStatistics] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetPrefixByAff] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSystemCurrency] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetSystemCurrency] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HomeGeneralInfo] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HomeGeneralInfo] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail_New] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail_New] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsDetail_New] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel_New] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel_New] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsSel_New] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsSel_New] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_HotNewsUpd] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_HotNewsUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_LanguageSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_LanguageSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_LanguageSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_LanguageSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_LanguageSelAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_LanguageSelAll] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_LanguageSelAll] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_LanguageSelAll] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_LoginAffiliate] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Logout] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Logout] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_Logout] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDomainDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDomainIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDomainSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberDomainUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberDomainUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberInfoGetMissingCreatedDate] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberInfoGetMissingCreatedDate] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberInfoGetMissingCreatedDate] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberInfoGetMissingCreatedDate] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberListSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberListSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MemberListSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberListSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberStatisticsDetail] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberUpdIBCInfo] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MinAmountSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MinAmountSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_MinAmountSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MinAmountSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_OnUserSelNetSessionID] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_OnUserSelNetSessionID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_OnUserSelNetSessionID] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_OnUserSelNetSessionID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestSelDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestSelInfoByAff] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestSelList] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestSelList] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PaymentRequestUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PaymentRequestUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayerPayoutInfoSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayerPayoutInfoSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayerPayoutInfoSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayerPayoutInfoSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersCurrenciesSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersCurrenciesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersCurrenciesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersCurrenciesSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PlayersSelDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersSelDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PreferLangUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_PreferLangUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PreferLangUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductIDSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductIDSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductIDSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ProductIDSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ProductSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSelAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSelAll] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSelAll] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ProductSelAll] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSelByAffID] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSelByAffID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ProductSelByAffID] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ProductSelByAffID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_RecheckIn] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_RecheckIn] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_RecheckIn] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_RecheckIn] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ReportDetailSelAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportDetailSelAll] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ReportDetailSelByAff] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportDetailSelByAff] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ReportQM] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportQM] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ReportQMDetail] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportQMDetail] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeyDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeyDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeyIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeyIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySelByID] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySelByID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeySelByID] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeySelByID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourceKeyUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourceKeyUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesTranslationInsOrUpdate] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesTranslationInsOrUpdateXML] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTranslationSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTranslationSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesTranslationSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTypeSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTypeSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTypeSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesTypeSel] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SelRefNo] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SportTypeSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_StatementHistorySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_StatementHistorySel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_StatementHistorySel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_StatementHistorySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_StatisticsSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_StatisticsSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemCurrencySel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemCurrencySel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsDel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSel] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelAll] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelAll] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelAll] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSelAll] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByID] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByID] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSelByID] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByName] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByName] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByName] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSelByName] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByType] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByType] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsSelByType] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsSelByType] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSettingsUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSettingsUpd] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSupportedCurrencies] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSupportedCurrencies] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_SystemSupportedCurrencies] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_SystemSupportedCurrencies] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_TaskDetailSelByName] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_TaskDetailSelByName] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_TaskLogIns] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_TaskLogIns] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_TaskLogUpdStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_TaskLogUpdStatus] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_TextDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_UserOnlineList] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_UserOnlineList] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_WriteLog] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_WriteLog_IISErr] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_WriteLog_UserLog_RunSP] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_ClearLogin] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_ClearLogin_Loop] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_aff_DailyImportExchange] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_aff_DailyImportExchange] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_DailySummaryClickRate] TO [vnteam] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_GroupSettingBackup] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberDailyImportData] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailyImportData] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberDailyTransactionImportData] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberDailyTransactionImportData] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoImportData] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MemberInfoImportData] TO [vnteam] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoUpdateCreatedDate] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoUpdateCreatedDate] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Task_Aff_MemberInfoUpdateCreatedDate] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_MonthlyTransfer] TO [vnteam] AS [dbo]
GO



GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateSelDBTime]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateSelDBTime]
AS
/**  
 * Created by : Kaden  
 * Date   : 20130716  
 * Task   : Select current DB Time to display to website
 * DB   : DB052.Affiliate_MYM    
 * Revisions :  
  */  
SET NOCOUNT ON
DECLARE @DBTime DateTime
DECLARE @GMTOffset varchar(20)
Select @DBTime=getdate()
declare @OffsetMinute int
select @OffsetMinute=DATEDIFF(minute,getutcdate(),getdate())

select @GMTOffset=' GMT'
if @OffsetMinute=0
  return   

if(@OffsetMinute>0) 
  set @GMTOffset=@GMTOffset + '+' 
else 
  set @GMTOffset=@GMTOffset + '-' 
select @OffsetMinute=abs(@OffsetMinute)
if(@OffsetMinute/60>= 10)
  set @GMTOffset=@GMTOffset + cast(@OffsetMinute/60 as varchar(5))
else
  set @GMTOffset=@GMTOffset + '0' + cast(@OffsetMinute/60 as varchar(5))

if @OffsetMinute%60 >= 10
      set @GMTOffset=@GMTOffset + ':' + cast(@OffsetMinute%60 as varchar(5))
else
      set @GMTOffset=@GMTOffset + ':0' + cast(@OffsetMinute%60 as varchar(5))

SELECT @DBTime AS DatabaseDateTime,@GMTOffset AS GMTOffSet;
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateCurrenciesSel]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 19-02-2013
-- Description:	Get Affiliate Currencies Information
-- =============================================
CREATE Procedure [dbo].[Aff_User_AffiliateCurrenciesSel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AffiliateCurrencies' and Type ='Meta')
	-- Insert statements for procedure here
	select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID from Currency (nolock)
	where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateAllLanguages]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Aff_User_AffiliateAllLanguages] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    select LanguageID , LanguageName
	from language with(nolock)
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateSupportedLanguagesSel]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateSupportedLanguagesSel]
	@SupportedLanguages nvarchar(255) ='en-US'	
AS
BEGIN
	
	SET NOCOUNT ON;

  	-- Insert statements for procedure here
	select LanguageID , LanguageName from Language (nolock)
	where LanguageID in (select val from [dbo].[strSplit] ( @SupportedLanguages, ',' ) )
	Order by [Order]
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_BaseCurrenciesSel]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 22-01-2013
-- Description:	Get Base Currencies Information
-- =============================================
CREATE Procedure [dbo].[Aff_User_BaseCurrenciesSel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @SupportedBaseCurrencies varchar(max)
    select @SupportedBaseCurrencies=(select SValue from SystemSettings where SName = 'SupportedBaseCurrencies')
	-- Insert statements for procedure here
	select Code,Prefix, ExchangeID from Exchange (nolock)
	where Code in (select val from [dbo].[strSplit] ( @SupportedBaseCurrencies, ',' ) )



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_BannerSelType]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_BannerSelType]
	@TypeName varchar(50)=NULL,
	@Language varchar(8) ='en-US',
    @ParentType smallint=NULL	
AS

if @TypeName='Size'
begin   
select TypeID,Value,ParentID,0 as HasSubCategory
 from (
       select top(1000) TypeID,value,ParentID,
      (select top(1) val from dbo.strSplit(value,'x') where rank=1) width,
      (select top(1) val from dbo.strSplit(value,'x') where rank=2) height,
       len((select top(1) val from dbo.strSplit(value,'x') where rank=1)) as lw,
       len((select top(1) val from dbo.strSplit(value,'x') where rank=2)) as lh
		from BannerTypes (nolock) where Type='Size'		 
		order by lw,width,lh,height
     )  t 
 
  
end
else if @Language='en-US'
begin
   Select top(1000) bt.TypeID,bt.value,bt.ParentID,
        (select count(1) from BannerTypes bt1 (nolock) where bt1.ParentID=bt.TypeID) as HasSubCategory
   from BannerTypes bt (nolock)  

  where bt.Type=@TypeName and  (@ParentType is null or bt.ParentID=@ParentType)
           
   order by bt.DisplayOrder
end
else
begin
   select top(1000) bt.TypeID, isnull(r.ResourceValue,bt.Value) as Value, bt.ParentID,
        (select count(1) from BannerTypes bt1 (nolock) where bt1.ParentID=bt.TypeID) as HasSubCategory
   from BannerTypes bt (nolock)
   left join RefResources r with (nolock) on r.ResourceKey=bt.Value and r.RefID='Resource' and r.LanguageCode=@Language
   where  bt.Type=@TypeName
           and  (@ParentType is null or @ParentType = 0 or bt.ParentID=@ParentType)
   
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_BannerSel]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_BannerSel]	
	@Category smallint=NULL,
	@Language varchar(8)=NULL,
	@ImageType smallint=NULL,
	@Size smallint=NULL,
	@Currency smallint=NULL,
	@Type tinyint=0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT
AS

/*Created: 20090328@DungTong
Task : Search all Aff Banner Paging
DB:  DB052.Affiliate_12BET

Revisions:    
	- 20130207@Johnny: Filter by Type(1: normal banner; 2: media banners)
			  
Param's Explanation:
• @Category : Search by Category value=null :search all
• @Language : Search by Language value=null :search all
• @ImageType : Search by ImageType value=null :search all
• @Size : Search by Size value=null :search all
• @Currency : Search by Currency value=null :search all
• @Type: type of banners(1: normal banner; 2: media banners)
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows

*/

SET NOCOUNT ON
declare @NRows int;
 declare @SubCategory table(id int);

if isnull(@Category,0)<>0
begin
 insert into @SubCategory(id)
 select typeid from BannerTypes where  parentid= @Category
 union 
 select @Category
end 


--count nrows
select @NRows=count(1)
FROM Banners with (nolock)
WHERE (@Category is null or Category in (select id from @SubCategory))
	  and (@Language is null or  Language=@Language)
       and (@ImageType is null or ImageType =@ImageType)
	    and (@Size is null or size =@Size)
	   and (@Currency is null or Currency =@Currency)	  
       and (@Type is null or Type=@Type)
/*if(isnull(@NRows,0)=0)
   return*/

DECLARE @RowStart int, @RowEnd int	

IF(isnull(@NRows,0)=0)
	BEGIN
		SET @RowStart = 0;
		SET @RowEnd = 0;
	END
ELSE
	SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,@PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   	

SELECT 	BannerID, [Content], Category,
	[Language],LanguageCode, ImageType, [Size],Lastupdate,Currency,Type,Version,TotalRequest,LastRequest
FROM(       
SELECT TOP(@RowEnd) 
			ROW_NUMBER() OVER(ORDER BY bannerid DESC) AS TheCount,
				BannerID, [Content],btc.Value as Category,l.LanguageID as LanguageCode,
	            l.LanguageName as [Language],bti.Value as ImageType, bts.Value as [Size],
                Lastupdate,c.CurrencyName as Currency,b.Type,Version,TotalRequest,LastRequest
FROM Banners b with (nolock)
left Join BannerTypes bts on bts.TypeID = b.Size
left Join BannerTypes bti on bti.TypeID = b.ImageType
inner Join BannerTypes btc on btc.TypeID = b.Category
inner join Language l on l.LanguageID=b.Language
inner join Currency c on c.CurrencyID=b.Currency

WHERE (@Category is null or b.Category in (select id from @SubCategory))
	  and (@Language is null or  b.Language=@Language)
       and (@ImageType is null or b.ImageType =@ImageType)
	    and (@Size is null or b.size =@Size)
	   and (@Currency is null or b.Currency =@Currency)	  
       and (@Type is null or b.Type=@Type)
	  
	  
    
   ) x
 where x.TheCount between @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_EarningSelDaily]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_EarningSelDaily]  
	@AffID int,	
	@ProductID tinyint = 0,
	@monthdate smalldatetime = null,
	@FromDate  smalldatetime = null,
	@ToDate  smalldatetime = null,
	@AffCurrency varchar(8) = 'UUS' OUTPUT
	
AS  
/*
	Created: 200900911@VinhTrinh 
	Task : [description of SP]  
	DB: DB052.Affiliate_MYM
	Revisions:  		
	      - Get data for daily report from table AffDaily instead of MemberDaily
	      - 20100520@Johnny: apply StatusID in bettrans table
	      - 20100930@Peter : Change the new formula for displayed winlost
	                   Winlost on Aff site=Winlost-Odds Management - Marketing cost -  PSP
	                   --The formula change since 1 Oct 2010--need to consider a new column MemWinlostFake on MemberDaily table if it is changed again
	                   MemWinlostFake need to be updated on TaskMemberDaily
	      - 20101228@Henry: change bettype to new range
		  - 20130806@Jim:  just get Turnover value from  products that have group comm
	Param's Explanation:  
	• @custid: affliate Id  
	• @monthdate: Month date need to view.
	
	  
*/  
SET NOCOUNT ON
DECLARE @CurrDate smalldatetime

select @AffCurrency=e.CurrencyCode
from AffInfo ai (nolock)
	inner join Currency e (nolock) on e.CurrencyID=ai.Currency
where ai.AffID=@AffID

-- Aff_GetPrefixByAff @AffId = @AffId, @Prefix = @Prefix OUTPUT

SET @CurrDate = convert(varchar(10), CURRENT_TIMESTAMP, 120)
If (@monthdate is not null and (@FromDate is null or @ToDate is null))
Begin
	select @monthdate = dateadd(d, datediff(d, 0, @monthdate), 0)
	Select @fromdate = DATEADD(mm, DATEDIFF(m,0,@monthdate),0)
	Select @todate = case when @monthdate >= @CurrDate then @CurrDate else @monthdate end
End


SELECT 
	d.winlostdate, 					
	sum(d.MemDeposit_aff) as Deposit,
	sum(d.MemWithdrawal_aff) as Withdrawal,
	sum(d.MemWinlost_aff) as MemberWinlost,
	sum(d.MemWinlostFake_aff) as MemWinlostFake,
	sum(d.MemBonus_aff) as Bonus,
	sum(d.MemAdjustment_aff) as Adjustment,
	sum(d.MemTurnover_aff) as Turnover,
	sum(d.MemPSP_aff) as PSP
FROM AffDailySummary d with(nolock)			 
WHERE AffID = @AffID		
	AND d.winlostdate between @fromdate and @todate
	and (case when @ProductID = 0 then 1 when @ProductID = ProductID then 1 else 0 end) = 1
	--and (isnull(d.MemDeposit_aff,0) <>0 or isnull(MemWithdrawal_aff,0)<>0 or isnull(MemWinlost_aff,0)<>0 or isnull(MemAdjustment_Aff,0)<>0 or isnull(MemPSP_Aff,0)<>0 or isnull(MemMarketing_Aff,0)<>0 or isnull(MemDeposit,0)<>0 or isnull(MemWithdrawal,0)<>0)			
	and [dbo].[Aff_IsProductInGroupOfAff](@AffID,d.ProductID ,@MonthDate) >0
group by d.winlostdate
order by d.winlostdate
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_DomainAffClientSel]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Aff_User_DomainAffClientSel]
	@AffID int 
AS
	Select DISTINCT a.DomainName as DomainId, a.DomainName
	From AffDomain a with(nolock)
		inner join AffDomainControl b with(nolock) on a.DomainID = b.AffDomainID	
		inner join AffDetail d with(nolock) on (b.CountryID = d.CountryId  or b.CountryID='-')
	where b.Status = 1  and d.AffID=@AffID
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_CurrencyListSel]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_CurrencyListSel]
	
  
AS

/*
	Created: 
	Task : 
	DB: DB052.Affiliate_MYM
	Revisions:
		

*/
SET NOCOUNT ON
Select ExchangeID,Code from Exchange
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_CountrySelAll]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_CountrySelAll]		
	@Name varchar(255) = NULL,	
	@PageSize int = 50,
	@PageIndex int = 1,
	@TotalPages int = 0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
--count nrows
select @NRows=count(1)
FROM Country N WITH (NOLOCK)	
where CountryName like @Name

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
	
SELECT CountryID, CountryName,Description,Icon,DisplayOrder,IsEnabled
from (
	SELECT TOP(@RowEnd) ROW_NUMBER() OVER(ORDER BY CountryName asc) AS TheCount,
		C.*
	FROM Country C WITH (NOLOCK)		
	where CountryName like @Name
	) x
where x.TheCount >= @RowStart
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_CommGroupSelDetail]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_CommGroupSelDetail]	
	@AffID int = null
AS
/**
 * Created by	: Kaden
 * Date			: 20130611
 * Task			: Get Group Setting for Editing an existing Group
 * DB			: DB052.Affiliate_MYM  
 * Revisions	:
 *	•
 * Parameters:
 	@AffId: Affiliate Id
 *  
 */

SET NOCOUNT ON
DECLARE @GroupId int

if @AffID is not null 
begin
	select @GroupId = groupid from affinfo with(nolock) where affid = @AffID
end

select g.GroupID,g.ProductID,g.TierID,g.MinAmount,g.MaxAmount,g.MinQM,g.MaxQM,g.Commission
from GroupSetting g (nolock)     
where g.GroupID=@GroupID 

Select top(1000) ProductID,ProductName
	from Product (nolock)
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_TextSel]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TextSel_1_xpre    Script Date: 4/3/2012 3:07:13 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextSel_1    Script Date: 2/24/2012 10:17:35 AM ******/

CREATE Procedure [dbo].[Aff_User_TextSel]	
	@Category varchar(50)=NULL,
	@Language varchar(50)=NULL,
	@Currency varchar(50)=NULL,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS

SET NOCOUNT ON

--count nrows
select @NRows=count(1)
FROM Banners with (nolock)
WHERE Category=coalesce(@Category,Category) 
      and [Language]=coalesce(@Language,[Language])
      and [ImageType] = 'Text'
      and isnull(Currency,'')=coalesce(@Currency,Currency,'') 

if(isnull(@NRows,0)=0)
   return
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT 	BannerID, Category,
	[Language],Lastupdate,Currency,[Content]
FROM(       
SELECT TOP(@RowEnd) 
			ROW_NUMBER() OVER(ORDER BY bannerid DESC) AS TheCount,
			BannerID, Category,
			[LanguageName] as Language, Lastupdate,Ex.Currency,[Content]
FROM Banners B with (nolock)
inner join language L with (nolock) on B.Language = L.LanguageID
inner join Exchange Ex with (nolock) on Ex.ExchangeID = B.Currency
WHERE Category=coalesce(@Category,Category) 
      and [Language]=coalesce(@Language,[Language])
	  and [ImageType] = 'Text'
      and isnull(B.Currency,'')=coalesce(@Currency,B.Currency,'') 
   ) x
 where x.TheCount between @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_SystemSettingsSelByType]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_SystemSettingsSelByType]	
	@Type varchar(50)=NULL
AS
/*
Created: 20110221@Peter
Task : Get All Settings By Type
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

SELECT [SID], [SName], [SValue],[Type],[Description]
FROM SystemSettings S WITH (NOLOCK)		
where Type =coalesce(@Type,Type)
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_SystemSettingsSelByName]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_SystemSettingsSelByName]	
	@Name varchar(50)
AS
/*
Created: 20110222@Johnny
Task : Get 1 Settings From System
DB: DB052.Affiliate_MYM
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From SystemSettings (nolock)
where SName=@Name
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_RecheckIn]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_RecheckIn]       
 @OnUserID int,      
 @IsKickedOut bit = 0 OUTPUT      
AS      
SET NOCOUNT ON      
      
--Original:On_UserUpd      
----------------------------------      
--Allow multi-login, will remove after testing      
/*Select @IsKickedOut = 0      
update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate()       
where on_userid = @OnUserID      
return     */  
    
--------------------------------      
      
if exists (select 1 from on_user with (NOLOCK) where On_UserID = @OnUserID and isKickedOut=1)      
BEGIN      
 Select @IsKickedOut=1      
END      
else      
BEGIN      
 Select @IsKickedOut = 0      
 update on_user with (ROWLOCK, UPDLOCK) set reload_time = getdate()       
 where on_userid = @OnUserID      
       
 IF @@ROWCOUNT = 0      
  Select @IsKickedOut=1      
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_ProductSelByAffID]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_ProductSelByAffID]
	@AffID int,
	@MonthDate datetime=null,
	@Language varchar(10) ='en-US'
AS

BEGIN
   if(@MonthDate is null or DATEDIFF(m,current_timestamp,@MonthDate)>=0)
   begin
	   
	   Select ProductID,isnull(r.ResourceValue,ProductName) as ProductName
	   from Product p (nolock)
		left join RefResources r (nolock) on r.RefID='Product' and r.LanguageCode=@Language and r.ResourceKey=p.ProductName

		where p.ProductID in
	   (
	   select distinct ProductID from GroupSetting g (nolock)
		inner join AffInfo a (nolock) on a.GroupID=g.GroupID
		where a.AffID=@AffID
		 
	   )	      
   end
   else
   begin
		  Select ProductID,isnull(r.ResourceValue,ProductName) as ProductName
	   from Product p (nolock)
		left join RefResources r (nolock) on r.RefID='Product' and r.LanguageCode=@Language and r.ResourceKey=p.ProductName

		where p.ProductID in
	   (
	   select distinct g.ProductID from GroupSettingHistory g (nolock)
	   inner join AffGroupHistory a (nolock) on a.GroupID=g.GroupID

	   where a.AffID=@AffID and a.MonthDate=@MonthDate and g.MonthDate=@MonthDate
		
	   )	      
   end
END
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_PlayersCurrenciesSel]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 30-05-2013
-- Description:	Get Affiliate Player Currencies Information
-- =============================================
CREATE Procedure [dbo].[Aff_User_PlayersCurrenciesSel]
		
AS
BEGIN
	
	SET NOCOUNT ON;

    declare @Currencies varchar(max)
    select @Currencies=(select SValue from SystemSettings where SName = 'AFF_PlayerCurrencies' and Type ='Meta')
	-- Insert statements for procedure here
	select CurrencyCode ,CurrencyID from Currency (nolock)
	where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )



END
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_LanguageSel]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_LanguageSel]
	
AS
-- DB052.Affiliate_12Bet
	

SELECT * 
FROM Language
Order by [Order]
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_HotNewsSel_New]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_HotNewsSel_New]
    @fromdate smalldatetime=null,
    @todate smalldatetime=null,
	@Important bit=null,
	@language	varchar(11) = null,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT
AS
/*
Created: 20090317@DungTong
Task : Search message hot news and paging
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
- 20130704@BrianDinh: Remove output para @NRows

Param's Explanation:
• @fromdate : <> null: from postdate
                null: select all
• @todate : <> null: to postdate
                null: select all
• @Important : select message is important or not
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search                

*/
SET NOCOUNT ON

DECLARE @RowStart int, @RowEnd int,@AffiliateID int;
DECLARE @NRows int;
select @todate = @todate + 1

select @Nrows=count(1)
from News with (nolock)
where important=coalesce(@Important,important)
      and (
          case when @fromdate is null or @todate is null then 1
                when posteddate between @fromdate and @todate then 1
                else 0
          end     
      )=1
      
 if(isnull(@NRows,0)=0)
   return	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   
       
if(@language is null)--select all column
begin
   
    select [message_en] as [content]
		  ,[creator]
		  ,[posteddate]
		  ,[msgid] as messageId
		  ,[important]
		  ,[creatorname]
		  ,[updatename]
		  ,[updateddate]
    from (
     SELECT [message_en]		  
		  ,n.[creator]
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,C.username as creatorname
		  ,u.username as updatename
		  ,[updateddate]
          ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount
	  FROM News n with (nolock)
			LEFT JOIN AdminUser C  WITH (NOLOCK) ON C.CUSTID=n.[creator]
			LEFT JOIN AdminUser u  WITH (NOLOCK) ON u.CUSTID=n.[updatedby]
	  WHERE important=coalesce(@Important,important)
           and (case when @fromdate is null or @todate is null then 1
                    when posteddate between @fromdate and @todate then 1
                     else 0
               end     
            )=1
     ) x
     where x.TheCount between @RowStart and @RowEnd
end
else --select for specific language
 begin
  
     select content		
		  ,[creator]
		  ,[posteddate]
		  ,[msgid] as messageId
		  ,[important]
          ,[creatorname]
		  ,[updatename]
		  ,[updateddate]
    from (
     SELECT  coalesce(r.ResourceValue,News.message_en) as [content]
			,[creator]
		    ,[posteddate]
		    ,[msgid]
            ,[important]
			,'' as [creatorname]
		    ,'' as [updatename]
		    ,[updateddate]
            ,ROW_NUMBER() OVER(ORDER BY msgid desc) AS TheCount		  
	  FROM News with (nolock)		
	  INNER JOIN RefResources r with (nolock) ON 
		r.RefID = 'News' and r.LanguageCode = @language and News.MsgID = cast(r.ResourceKey as int)
	  WHERE important=coalesce(@Important,important)
           and (case when @fromdate is null or @todate is null then 1
                    when posteddate between @fromdate and @todate then 1
                     else 0
               end     
            )=1
     ) x
     where x.TheCount between @RowStart and @RowEnd
 end
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_HotNewsDetail_New]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_HotNewsDetail_New]
	@MsgID int=null
AS
/*
Created: 20090310@TrangLe
Task : Select affiliate hot news by message id or latest messageid
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090317@DungTong: allow to get latest message id
- 20090819@DungTong : Add new Spanish language
- 20090920@DungTong : Add new Vietnamese and Indonesia Language
Param's Explanation:
• @MsgID : >0 message id selected
           null: select the latest message

*/
SET NOCOUNT ON
if(coalesce(@MsgID,-1)=-1) -- get the latest message
  begin
        select  @MsgID=max(MsgID) 
        from News with (nolock)     
  end
    
declare @ID varchar(10)
set @ID = cast(@MsgID as varchar(50))


/*
	SELECT r.LanguageCode
			,r.ResourceValue as Value
		  ,n.[creator]
		  ,[posteddate]
		  ,[msgid]
		  ,[important]
		  ,c.username as creatorname
	  FROM News n with (nolock)
			INNER JOIN RefResources r WITH (NOLOCK) ON r.RefID = 'News'  AND r.ResourceKey = @ID
			LEFT JOIN AdminUser c WITH (NOLOCK) ON c.custid=n.[creator]
	  WHERE 
			msgid=@MsgID
*/

DECLARE @Query VARCHAR(8000)  

DECLARE @Names VARCHAR(8000)  
/*SELECT  COALESCE(@Names + '], [', '') + LanguageID FROM Language (nolock)
 where ResourceKey = @ID    */       
  set @Names =  stuff(
    (
    select cast(',' as varchar(max)) + '[' + l1.LanguageID +']'
    from Language l1 (nolock)   
    for xml path('')
    ), 1, 1, '')  
  
    
SET @Query = '
select n.[creator]
	  ,[posteddate]
	  ,[msgid]
	  ,[important]
	  ,c.username as creatorname
	  ,temp.*
	  FROM News n with (nolock)
	  LEFT JOIN AdminUser c WITH (NOLOCK) ON c.custid=n.[creator]
	  INNER JOIN (
			select * from (select ResourceKey,ResourceValue,LanguageCode from RefResources r (nolock) 
			WHERE r.ResourceKey = ''' + @ID +''') a
			PIVOT
			(MIN(ResourceValue) FOR LanguageCode IN (' + @Names+ ')) pvt
	 ) temp ON temp.ResourceKey = ''' + @ID + '''
	 WHERE n.msgid = ' + convert(varchar(10),@MsgID)
--select @Query
exec (@Query)
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_GetDefaultProductCommission]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[Aff_User_GetDefaultProductCommission]
    @groupID int = 101
AS
	/**
	 * Created by	: Brian
	 * Date			: 20130709
	 * Task			: Get Default Group Commision
	 * DB			: DB052.Affiliate_Alpha
	 * Revisions	:
	 *	•
	 * Parameters:
 		@groupId: group id
	 *  
	 */
    
	SET NOCOUNT ON

	DECLARE @productTmp TABLE (ProductId int);

	-- get group settings info
	SELECT g.GroupID,g.ProductID,g.TierID,g.MinAmount,g.MaxAmount,g.MinQM,g.MaxQM,g.Commission
	FROM GroupSetting g WITH(NOLOCK)
	WHERE g.GroupID = @groupID

	-- get the list of product list
	INSERT INTO @productTmp
	SELECT DISTINCT(ProductID)
	FROM GroupSetting
	WHERE GroupID = @groupID

	SELECT p.ProductID, p.ProductName
	FROM Product p WITH(NOLOCK)
	WHERE p.ProductID in (SELECT * FROM @productTmp)
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_GetAllAffSystemSettings]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_GetAllAffSystemSettings]      
 @Environment nvarchar(20) = 'Local Development'    
AS    
/*    
Created: 20130722@Long    
Task : Get All Affiliate's System Settings    
DB:     
Original:    
    
Param's Explanation (filtered by):    
    
*/    
SET NOCOUNT ON    
    
-- #0 get individual info    
select sname,svalue,environment  
from systemsettings with(nolock)  
where type = 'meta' and (environment is null or environment=@Environment)    
  
-- #1 get All Languages    
select LanguageID , LanguageName    
from language with(nolock)    
    
--#2 get Supported Languages    
DECLARE @AffiliateLanguages NVARCHAR(100)  
SELECT @AffiliateLanguages = SValue FROM SystemSettings where SName='AFF_AffiliateSupportedLanguages'  
  
select LanguageID , LanguageName from Language (nolock)    
where LanguageID in (select val from [dbo].[strSplit] ( @AffiliateLanguages, ',' ) )    
Order by [Order]    
    
--#3 get All Currencies    
Select ExchangeID,Code from Exchange    
    
--#4 get Affiliate Currencies    
declare @Currencies varchar(max)    
select @Currencies=(select SValue from SystemSettings where SName = 'AffiliateCurrencies' and Type ='Meta')    
select CurrencyCode as Code,'' as Prefix, CurrencyID as ExchangeID from Currency (nolock)    
where CurrencyCode in (select val from [dbo].[strSplit] ( @Currencies, ',' ) )    
    
--#5 get Base Currencies    
declare @SupportedBaseCurrencies varchar(max)    
select @SupportedBaseCurrencies=(select SValue from SystemSettings where SName = 'SupportedBaseCurrencies')    
select Code,Prefix, ExchangeID from Exchange (nolock)    
where Code in (select val from [dbo].[strSplit] ( @SupportedBaseCurrencies, ',' ) )    
    
--#6 get Player Currencies    
declare @PCurrencies varchar(max)    
select @PCurrencies=(select SValue from SystemSettings where SName = 'AFF_PlayerCurrencies' and Type ='Meta')    
select CurrencyCode ,CurrencyID from Currency (nolock)    
where CurrencyCode in (select val from [dbo].[strSplit] ( @PCurrencies, ',' ) )    
      
-- #7 get country list    
SELECT CountryID, CountryName,Description,Icon,DisplayOrder,IsEnabled    
from Country    
  
-- #8 get multiplied by values  
declare @var varchar(1000)  
  
select @var = coalesce(@var + ',' + CurrencyCode,CurrencyCode)  
from Currency (nolock)    
where CurrencyCode in (select val from [dbo].[strSplit]((select SValue from systemsettings with(nolock) where SName = 'AffiliateCurrencies'), ',' ) ) and MultipliedBy>1  
  
select top 1 @var as CurrencyMultipliedBy, convert(varchar(10),multipliedby) as MultipliedBy  
from Currency (nolock)    
where CurrencyCode in (select val from [dbo].[strSplit]((select SValue from systemsettings with(nolock) where SName = 'AffiliateCurrencies'), ',' ) ) and MultipliedBy>1
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_OnUserSelNetSessionID]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_OnUserSelNetSessionID]  
 @On_UserID int,     
 @NetSessionID varchar(30) OUTPUT 
AS  
/*
Created: 20090316@Ken
Task : Get NetSessionID from table On_User
DB: DB052.Affiliate_MYM

Revisions:	
*/
SET NOCOUNT ON
SELECT @NetSessionID = ''

SELECT @NetSessionID = NetSessionID
FROM On_User WITH(NOLOCK) 
WHERE On_UserID = @On_UserID
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateSelEditInfo]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateSelEditInfo]    
 @AffId int,    
 @GetBalance bit = 0,    
 @AFF_MinWire  MONEY = 0 OUTPUT,    
 @Aff_MinNeteller MONEY = 0 OUTPUT,    
 @AFF_MinCheque MONEY = 0 OUTPUT,    
 @AFF_MinMoneybookers MONEY = 0 OUTPUT,    
 @AFF_MinPlayer MONEY = 0 OUTPUT    
AS    
-- DB052.Affiliate_MYM    
SET NOCOUNT ON    
Declare @currencyName varchar(5)    
    
Select @currencyName = Currency    
from AffInfo with (nolock)    
where AffId = @AffId    
    
Select @AFF_MinWire = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinWire'+@currencyName    
Select @Aff_MinNeteller = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinNeteller'+@currencyName    
Select @AFF_MinCheque = cast(SValue as money) From systemsettings with(nolock) where SName = 'AFF_MinCheque'+@currencyName     
Select @AFF_MinMoneybookers = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinMoneybookers'+@currencyName    
Select @AFF_MinPlayer = cast(SValue as money) From systemsettings with(nolock) where SName ='AFF_MinPlayer'+@currencyName    
    
SELECT      
 ai.AffId,     
 ai.username,     
 ai.username2,    
 ad.gender,    
 ai.firstname,    
 ai.lastname,    
 ai.Status,    
 ai.email,    
 ad.phone,    
 ad.mobilephone,    
 ad.address,    
 ad.city,    
 ad.state,    
 ad.postal,    
 ad.countryID as Country,     
 ad.SiteURL ,    
 ad.MoreSiteURLs,    
 ad.PreferredPayment, --Player, Neteller, Moneybookers, Wire, Cheque    
 ad.PreferredLanguage as Language,    
 ai.Currency,    
 ad.Player_Username,    
 ad.Neteller_AccountID,    
 ad.Moneybookers_Email,    
 ad.Wire_BankName,    
 ad.Wire_BankAddress,    
 ad.Wire_SwiftCode,    
 ad.Wire_AccountName,     
 ad.Wire_AccountNo,    
 ad.Cheque_FullName,    
 ad.Cheque_Address,    
 ad.Cheque_City,    
 ad.Cheque_State,    
 ad.Cheque_Postal,    
 ad.Cheque_Country,    
 ad.question,    
 ad.answer,    
 ad.mailoption as EmailFormat,    
 --Do not allow edit when status is approved     
 (case when ai.Status in ('pending','disapproved') then 1 else 0 end) as IsCurrencyEditable    
 --(case when ai.Status in ('pending','disapproved') or not exists (select top(1)  1 from Memberdaily (nolock) where AffID = ai.AffID ) then 1 else 0 end) as IsCurrencyEditable      
FROM     
 AffInfo ai with (nolock)     
 inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId    
WHERE     
 ai.AffId=@AffID    
ORDER BY ai.username
GO

/****** Object:  StoredProcedure [dbo].[Aff_User_PaymentRequestSelInfoByAff]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_PaymentRequestSelInfoByAff]
	@AffID int,
	@PreferredPayment varchar(20) OUTPUT,
	@BalBroughtForward money OUTPUT,	
	@MinAmount money output
AS
/*Created: 20090914@Peter
Task : Getting Payment request history information for Affiliate
DB: DB052.Affiliate_MYM 
Original: [Aff_User_BettransSelTransfer]
Revisions:
    
Param's Explanation:
• @custid : Affiliate custid
• @BalBroughtForward: Sum(Winlost is transfered and approved to affiliate)
• @PreferredPayment: Preferred Payment method for this affiliate
• @MinAmount
*/		
SET NOCOUNT ON			
Declare @currencyName varchar(5)
Select @PreferredPayment=PreferredPayment
from AffDetail with (nolock)
where AffID=@AffID

SELECT @currencyName = C.currencycode
from AffInfo A with (nolock) inner join currency C with(nolock) on A.currency = c. currencyid
where A.AffID=@AffID	
--Get MinAmount value

SELECT @MinAmount = SValue from SystemSettings with(nolock) 
WHERE SName = 'AFF_Min'+ @PreferredPayment + @currencyName

--Get Balance Brought Forward
Select @BalBroughtForward=dbo.Aff_GetAffBalance(@AffID)

--Get list payment request
Select t.TransID,p.RefID, p.TransDate, p.CompletedDate,p.Status,abs(p.Amount) as Amount,p.AffDesc
from AffPayout p with (nolock)
 inner join AffTrans t with (nolock) on t.RefID=p.RefID
where p.AffID=@AffID
order by RefID desc
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_PlayerPayoutInfoSel]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_PlayerPayoutInfoSel]
	@AffId int,
	@PlayerUsername varchar(30) = '' OUTPUT,
	@SystemName varchar(30) = '' OUTPUT,
	@DummyBalAcc varchar(30) = '' OUTPUT,
	@AffCurrency varchar(6) = '' OUTPUT
AS
/*
	Task : Get all information of existing member
	DB : DB054.Affiliate_MYM
		- Johnny@2013Mar25: Return test account (UUS balance account)
*/


select @PlayerUsername = Player_Username from AffDetail nolock where AffId = @AffId

select @SystemName = SValue From SystemSettings nolock where SName = 'SystemName' and Type = 'Meta'

Declare @Player_Currency varchar(50)

Select @Player_Currency = dbo.[Aff_PlayerCurrencyByAffId] (@AffId)

Select @AffCurrency = e.code from affinfo a 
inner join exchange e on e.ExchangeID = a.Currency 
where a.affid = @AffId
--For Real Currency
Select @DummyBalAcc = SValue
From SystemSettings nolock
where SName like 'AFF_BalPlayer' + @Player_Currency
	and Type = 'Meta'
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_ClickStatisticsSelBySite]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_ClickStatisticsSelBySite]    
	@AffID int,    
	@FromDate smalldatetime,  
	@ToDate smalldatetime,  
	@TotalClicks int = 0 output,  
	@UniqueClicks int = 0 output  
AS    
/*    
Created: 20111005@Johnny    
Task :   Report click statistics by Referrer site  
DB: DB052.Affiliate_12BET    
Original:    
    
Revisions:    
-   
*/    
  
SET NOCOUNT ON    
  
Declare @LastDateSum smalldatetime  
if(@FromDate > @ToDate)  
	return  
  
Declare @Result as table(DomainReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)  
  
select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)  
  
select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))  
	, @FromDate = convert(varchar(10), @FromDate,120)  
  
if (@LastDateSum < @FromDate)--get from main table  
Begin  
insert into @Result  
select DomainReferrer,  
	sum(TotalClick) as TotalClick,  
	sum(UniqueClick) as UniqueClick,  
	sum(Signups) as Signups,  
	sum(FDM) as FDM  
from   
	(  
	Select   
		DomainReferrer,  
		sum(ClickCount) as TotalClick,  
		count(distinct IP) as UniqueClick,  
		SUM(isnull(Signups, 0)) as Signups,
		SUM(isnull(FDM, 0)) as  FDM 
	from ClickStatistics c with(nolock)   
		left join 
			(Select ClickId, 
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from MemberInfo m with (nolock) 
			where AffId = @AffID
			group by ClickId
			) as m on c.ClickId = m.ClickId
	where [Date] between @FromDate and @ToDate  
		and c.AffId = @AffID  
	group by DomainReferrer, [Date]  
	) as t  
group by DomainReferrer  
End  
else if (@LastDateSum > @ToDate)--get from summary table  
Begin  
insert into @Result  
Select   
	DomainReferrer,  
	sum(TotalClick) as TotalClick,  
	sum(UniqueClick) as UniqueClick,  
	sum(TotalSignup) as Signups,  
	sum(TotalDeposit) as FDM  
from ClickStatisticsSum with(nolock)   
where [Date] between @FromDate and @ToDate  
	and AffId = @AffID  
group by DomainReferrer  
End  
else--@fromdate < @LastDateSum < @ToDate  
Begin  
insert into @Result  
select DomainReferrer,  
	sum(TotalClick) as TotalClick,  
	sum(UniqueClick) as UniqueClick,  
	sum(Signups) as Signups,  
	sum(FDM) as FDM  
from   
	(  
	Select   
		DomainReferrer,  
		sum(TotalClick) as TotalClick,  
		sum(UniqueClick) as UniqueClick,  
		sum(TotalSignup) as Signups,  
		sum(TotalDeposit) as FDM  
	from ClickStatisticsSum with(nolock)   
	where [Date] between @FromDate and @LastDateSum  
		and AffId = @AffID  
	group by DomainReferrer  
  
	Union All  
  
	Select   
		DomainReferrer,  
		sum(ClickCount) as TotalClick,  
		count(distinct IP) as UniqueClick,  
		SUM(isnull(Signups, 0)) as Signups,
		SUM(isnull(FDM, 0)) as  FDM 
	from ClickStatistics c with(nolock)   
			left join 
			(Select ClickId, 
				SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
				SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
			from MemberInfo m with (nolock) 
			where AffId = @AffID
			group by ClickId
			) as m on c.ClickId = m.ClickId
	where [Date] between @LastDateSum and @ToDate  
		and c.AffId = @AffID  
	group by DomainReferrer, [Date]  
	) tmp  
group by DomainReferrer  
  
End  
  
Select * from @Result  
  
select @TotalClicks = SUM(TotalClick)  
    , @UniqueClicks = SUM(UniqueClick)  
from @Result
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_ClickStatisticsSelByPage]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_ClickStatisticsSelByPage]  
	@AffID int,  
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@SportCode varchar(50) = null,
	@LanguageCode varchar(10) = null
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Landing page and language of landing page
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
- 
*/  

SET NOCOUNT ON  

Declare @LastDateSum smalldatetime
if(@FromDate > @ToDate)
	return

Declare @Result as table(SportCode varchar(50), LanguageCode varchar(10), TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)

select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))
		, @FromDate = convert(varchar(10), @FromDate,120)

if (@LastDateSum < @FromDate)--get from main table
Begin
	insert into @Result
	Select 
		SportCode,
		LanguageCode,
		sum(TotalClick) as TotalClick,
		Sum(UniqueClick) as UniqueClick,
		SUM(Signups) as Signups,
		SUM(FDM) as  FDM
	From(
		Select 
			SportCode,
			LanguageCode,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics c with(nolock) 
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where AffId = @AffID
				group by ClickId
				) as m on c.ClickId = m.ClickId
		where [Date] between @FromDate and @ToDate
			and c.AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		group by SportCode, LanguageCode, [Date]--[Date] in condition to calculate unique click
		) as tmp
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
	insert into @Result
	Select 
		SportCode,
		LanguageCode,
		sum(TotalClick) as TotalClick,
		sum(UniqueClick) as UniqueClick,
		sum(TotalSignup) as Signups,
		sum(TotalDeposit) as FDM
	from ClickStatisticsSum with(nolock) 
	where [Date] between @FromDate and @ToDate
			and AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode
End
else--@fromdate < @LastDateSum < @ToDate
Begin
	insert into @Result
	select SportCode,
			LanguageCode,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			SportCode,
			LanguageCode,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(TotalSignup) as Signups,
			sum(TotalDeposit) as FDM
		from ClickStatisticsSum with(nolock) 
		where [Date] between @FromDate and @LastDateSum
			and AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		group by SportCode, LanguageCode

		Union All

		Select 
			SportCode,
			LanguageCode,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
		SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics c with(nolock) 
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where AffId = @AffID
				group by ClickId
				) as m on c.ClickId = m.ClickId
		where [Date] between @LastDateSum and @ToDate
			and c.AffId = @AffID
			and SportCode = ISNULL(@SportCode, SportCode)
			and LanguageCode = ISNULL(@LanguageCode, LanguageCode)
		group by SportCode, LanguageCode, [Date]
		) tmp
	group by SportCode, LanguageCode
	order by SportCode, LanguageCode

End

Select * from @Result
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_ClickStatisticsDetailBySite]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_ClickStatisticsDetailBySite]  
	@AffID int,  
	@Domain nvarchar(300) = null,
	@SportCode varchar(50) = null,
	@LanguageCode varchar(10) = null,
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT
AS  
/*  
Created: 20111005@Johnny  
Task :   Report click statistics by Referrer site
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
- 
*/  

SET NOCOUNT ON  

Declare @LastDateSum smalldatetime
if(@FromDate > @ToDate)
	return

Declare @Result as table(UrlReferrer nvarchar(300), TotalClick int, UniqueClick int, Signups int, FDM int)

select @LastDateSum = (select MAX(Date) from ClickStatisticsSum)
		, @FromDate = convert(varchar(10), @FromDate,120)

select @LastDateSum = isnull(@LastDateSum, dateadd(d, -1, @FromDate))

if (@LastDateSum < @FromDate)--get from main table
Begin
	insert into @Result
	select URLReferrer,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			URLReferrer,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics c with(nolock) 
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where AffId = @AffID
				group by ClickId
				) as m on c.ClickId = m.ClickId
		where [Date] between @FromDate and @ToDate
			and c.AffId = @AffID
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]
		) as t
	group by URLReferrer
End
else if (@LastDateSum > @ToDate)--get from summary table
Begin
	insert into @Result
	select URLReferrer,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			URLReferrer,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics_bk c with(nolock) 
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where AffId = @AffID
				group by ClickId
				) as m on c.ClickId = m.ClickId
		where [Date] between @FromDate and @ToDate
			and c.AffId = @AffID
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]
		) as t
	group by URLReferrer
End
else--@fromdate < @LastDateSum < @ToDate
Begin
	insert into @Result
	select URLReferrer,
			sum(TotalClick) as TotalClick,
			sum(UniqueClick) as UniqueClick,
			sum(Signups) as Signups,
			sum(FDM) as FDM
	from 
		(
		Select 
			URLReferrer,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics_bk c with(nolock) 
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where AffId = @AffID
				group by ClickId
				) as m on c.ClickId = m.ClickId
		where [Date] between @FromDate and @LastDateSum
			and c.AffId = @AffID
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]

		Union All

		Select 
			URLReferrer,
			sum(ClickCount) as TotalClick,
			count(distinct IP) as UniqueClick,
			SUM(isnull(Signups, 0)) as Signups,
			SUM(isnull(FDM, 0)) as  FDM
		from ClickStatistics c with(nolock) 
			left join 
				(Select ClickId, 
					SUM(case when m.RegisteredDate is not null then 1 else 0 end) as Signups,
					SUM(case when m.CreatedDate is not null then 1 else 0 end) as  FDM 
				from MemberInfo m with (nolock) 
				where AffId = @AffID
				group by ClickId
				) as m on c.ClickId = m.ClickId
		where [Date] between @LastDateSum and @ToDate
			and c.AffId = @AffID
			and DomainReferrer = isnull(@Domain, DomainReferrer)
			and SportCode = isnull(@SportCode, SportCode)
			and LanguageCode = isnull(@LanguageCode, LanguageCode)
		group by URLReferrer, [Date]
		) tmp
	group by URLReferrer

End

--Select * from @Result

--count nrows
declare @NRows int
select @NRows=count(1)
FROM @Result
   
DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SELECT 	*
FROM(       
	SELECT TOP(@RowEnd) 
			ROW_NUMBER() OVER(ORDER BY URLReferrer) AS TheCount,
			*
	FROM @Result
	   ) x
 where x.TheCount between @RowStart and @RowEnd
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_StatisticsSel]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_StatisticsSel]  
	@AffID int,  
	@MonthDate smalldatetime,  	
	@TotalActivePlayer int OUTPUT,  
	@TotalPlayerDepUp int OUTPUT,  
	@NewSignUpDep int OUTPUT,  
	@NewSignUp int OUTPUT,  
	@TotalPlayer int OUTPUT,   
	@BalBroughtforward money = 0 OUTPUT,  
	@TotalDeposit money OUTPUT,  
	@TotalDepositUp money OUTPUT,  
	@TotalTurnover money OUTPUT,  
	@TotalTurnoverUp money OUTPUT,  
	@TotalWinlostUp money OUTPUT,  
	@TotalWinlost money OUTPUT,  
	@TotalUniqueClicks int = 0 OUTPUT,  
	@TotalClicks int = 0 OUTPUT  
AS  
  
/*Created: 20090325@VinhTrinh  
Task : Get statistics for affiliate  
DB: DB052.Affiliate_ZZun  
Original : [Aff_User_StatisticsSel]  
Revisions:  
	- 20090513@VinhTrinh: return 2 more result(winlost up to now and winlos for search month).  
	- 20090827@DungTong: Convert to new DB version  
	- 20100511@Johnny: correct output params "@TotalPlayerDepUp" and "@NewSignUpDep"  
	- 20130806@Jim:  just get Turnover value from  products that have group comm
Param's Explanation:  
	• @AffID : Affiliate custid  
	• @MonthDate : Date search(format:first day of the month).  
	• @TotalActivePlayer : Get Active player in Month  
	• @TotalPlayerDepUp int OUTPUT,--Get player deposited in our system  
	• @NewSignUpDep : Get new signups of the month  
	• @TotalDeposit : total deposit money for month search  
	• @TotalDepositUp money OUTPUT,--total deposit money up to now  
	• @TotalTurnover money OUTPUT,--total turnover money up to now  
*/  
  
SET NOCOUNT ON  
  
      
  
SELECT @NewSignUp = sum(case when DATEDIFF(MONTH,@MonthDate,RegisteredDate) = 0 then 1  else 0 end)  
	,@NewSignUpDep = sum(case when CreatedDate is not null and datediff(m, CreatedDate, @MonthDate) = 0  then 1 else 0 end)  
	,@TotalPlayerDepUp=sum(case when  CreatedDate is not null and IsRemoved=0 then 1 else 0 end)   
	,@TotalPlayer=sum(case when IsRemoved=0 then 1 else 0 end)   
FROM MemberInfo WITH(NOLOCK)  
WHERE AffID = @AffID        
	and username not in (select username From MemberRemoval with(nolock) where datediff(m, RemovedDate, @MonthDate) = 0)   
  
create table #TblStatistics (username varchar(30), ProductID int, QualifiedMember int,ActivePlayer int, Turnover money, Deposit money, Winlost money, MonthDate smalldatetime)  

insert into #TblStatistics  
select '',  
	ProductID,   
	QualifiedMember,   
	ActivePlayer,  
	MemberTurnover_aff, --Turnover has been change to AffExRate  
	MemberDeposit_aff, --Deposit has been change to AffExRate  
	MemberWinlost_aff as MemberWinlost,--Winlost has been change to AffExRate  
	WinlostDate  
from AffCommission with (nolock)  
where AffId = @AffId   

declare @MaxTransDate datetime, @FromDate datetime, @CurrentDate datetime, @QMTurnover money  
  
select @QMTurnover=dbo.[Aff_GetQMTurnOver](@AffID,@MonthDate), @CurrentDate= current_timestamp
select @MaxTransDate = max(MonthDate) from #TblStatistics with(nolock)  
if @MaxTransDate is not null  
   select @FromDate = dateadd(d,1,@MaxTransDate)  
else 
      select @FromDate = MIN(WinlostDate) from AffDailySummary(nolock) 
   

insert into #TblStatistics  
  
select ci.username,  
	ProductID,  
	0 as QualifiedMember,  
	0 as ActivePlayer,  
	sum(isnull(TurnOver,0) * isnull(AffExRate,1)) as Turnover,  
	sum(isnull(Deposit,0) * isnull(AffExRate,1)) as Deposit,      
	sum(isnull(Winlost,0) * isnull(AffExRate,1)) as Winlost,  
	dateadd(mm, DATEDIFF(m,0,b.WinlostDate), 0)  
from MemberDaily b with (nolock)   
	inner join MemberInfo ci with (nolock) on ci.username=b.username  
where ci.AffID=@AffID   
	and b.winlostdate between @FromDate and @CurrentDate--this condition use up index on winlostdate      
	and [dbo].[Aff_IsProductInGroupOfAff](@AffID,ProductID ,@MonthDate) >0	
group by ci.username, ProductID,  
	dateadd(mm, DATEDIFF(m,0,b.winlostdate), 0)  


update #TblStatistics

set QualifiedMember=(case when Turnover>=@QMTurnover then 1 else 0 end)    

where username<>''


Select @TotalWinlostUp = Sum(a.Winlost)  
	, @TotalTurnoverUp = Sum(a.Turnover)  
	, @TotalDepositUp = Sum(a.Deposit)  
	,@TotalWinlost = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Winlost else 0 end)  
	, @TotalTurnover = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Turnover else 0 end)  
	, @TotalDeposit = Sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0 then a.Deposit else 0 end)  
	--,@TotalActivePlayer=sum(case when DATEDIFF(m, a.MonthDate, @MonthDate) = 0  then isnull(a.ActivePlayer,0) else 0 end)   
	
  
From #TblStatistics a with (nolock)  

declare @DateTemp datetime

set @DateTemp=dbo.Date_Only(dbo.Aff_GetLastDayOfMonth(@MonthDate))



if(exists(select top(1) 1 from AffCommission (nolock) where winlostdate=@DateTemp))
BEGIN
 select @TotalActivePlayer=max(ActivePlayer)
 From #TblStatistics a with (nolock)  
 where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and username=''
END
else
BEGIN
   select @TotalActivePlayer=count(distinct username)
  From #TblStatistics a with (nolock)  
  where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and username<>''
              and (a.Turnover>0 or a.Deposit>0) 
END



  
--Get Click Statistics  
  
select @TotalClicks= sum(TotalClick),  @TotalUniqueClicks=sum(UniqueClick)  
FROM  
(  
	select sum(TotalClick) as TotalClick,Sum(UniqueClick) as UniqueClick  
	from ClickStatisticsSum (nolock)  
	where AffID=@AffID              
		and datediff(mm,@MonthDate,[date])=0  
	
	union all  

	select sum(ClickCount) as TotalClick,count(distinct s.IP) as UniqueClick  
	from ClickStatistics s (nolock)   
	where datediff(mm,@MonthDate,s.date)=0 and s.AffID=@AffID  
	group by dbo.Date_Only(Date),DomainReferrer, SportCode, LanguageCode  
) t  
  
select @BalBroughtforward = isnull(dbo.Aff_GetAffBalance(@AffID), 0)     

declare @MinMonthDate datetime

select @MinMonthDate=MIN(MonthDate) from AffGroupHistory(nolock)


if datediff(m,CURRENT_TIMESTAMP,@MonthDate)>0 or datediff(m,@MinMonthDate,@MonthDate) < 0
begin
		  Select p.ProductID,p.ProductName,0  as TotalQualifiedMembers 
		  From Product p  with (nolock)  
		  where  [dbo].[Aff_IsProductInGroupOfAff](@AffID,p.ProductID ,current_timestamp) >0   
		  order by p.ProductID
end
else
begin
		Select p.ProductID,p.ProductName,isnull(t.TotalQualifiedMembers,0)  as TotalQualifiedMembers 
		 From Product p  with (nolock)  
		left join 
		(
		   select a.ProductID, sum(a.QualifiedMember) as TotalQualifiedMembers
		   from #TblStatistics a (nolock)  
		   where DATEDIFF(m, a.MonthDate, @MonthDate) = 0 and [dbo].[Aff_IsProductInGroupOfAff](@AffID,a.ProductID ,@MonthDate) >0
		   group by a.ProductID

		) t on t.ProductID=p.ProductID
		where  [dbo].[Aff_IsProductInGroupOfAff](@AffID,p.ProductID ,@MonthDate) >0   
		  order by p.ProductID

end
Drop table #TblStatistics     
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_PaymentRequestUpd]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_PaymentRequestUpd]   
	@TransID bigint,   
	@Status nvarchar(50),  
	@AdminDesc nvarchar(300) = null,  
	@AffDesc nvarchar(300) = null,  
	@PreferredLanguage varchar(20)='en-US' OUTPUT,  
	@MailOption bit = 0 OUTPUT,  
	@TransDate datetime=null OUTPUT,
	@Amount money=0 OUTPUT,
	@UserID int,   
	@IP varchar(15) = '',  
	@RefNo bigint=0,  
	@language varchar(20) = 'en-US',  
	@IbcRefNo bigint = 0,  
	@IbcTransId bigint = 0,  
	@IBCUsername varchar(50) = '',  
	@ErrCode int = 0 OUTPUT
AS  
-- DB: DB052.Affiliate_MYM  
/*  
Creator : Peter@20090910  
Task : Update Payment status ('Approved','Rejected','Cancelled')  
  
Input   
    1) @AffId (For Double check)   
    2) @RefID (This ID is get from "B. deposit/withdrawal for approved" Output TransID )  
    3) @Status Status of transaction  
    3) @AdminDesc Description for this payment from Admin  
    4) @AffDesc Description visible for Affiliate  
    5) @userid ID of Admin update this payment  
    6) @IP IP update payment  
     
Revisions:  
  
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
• @ErrMsg: Error description.  
*/  
  
  
--Check whether this is pending payment request   
SET NOCOUNT ON  
Declare @AffID int, @RefID bigint , @TransType int  
Select @TransType = 202  
Select @AffID=AffID,@RefID=RefID,@TransDate=TransDate, @Amount=Amount
from AffTrans (nolock)  
where TransID=@TransID and TransType= @TransType and Status='pending'  
  
if(@AffID is null or @RefID is null)  
BEGIN  
           Select --'This transaction is not a withdrawal.' 
   @ErrCode = 140  
 return  
END  
  
/*Check Condition to excute this sp  
  + From Affiliate Site : @UserID=@AffID and  @Status='Cancelled'  
  + From AffAdmin Site: @UserID<> @AffID and Status in ('Approved','Rejected')   
*/  
if( @UserID<>@AffID)  
BEGIN  
 --Check permission-----------------------------  
 EXEC [dbo].[Aff_Con_CheckPermission]  
  @custid=@UserID,@funcname='[Payment]',  
  @System = 'AFFILIATE',  
  @ErrCode=@ErrCode output
 If @ErrCode <> 0  
  RETURN  
     if(@Status not in ('Approved','Rejected'))  
  BEGIN  
       Select --'Oops, You do not have permission to update this transaction.' 
     @ErrCode = 139  
   return  
  END  
END  
  
if(@UserID=@AffID and  @Status<>'Cancelled')  
BEGIN  
           Select --'Oops, You do not have permission to update this transaction.'     
   @ErrCode = 139  
 return  
END  
  
  
  
BEGIN TRANSACTION  
BEGIN TRY  
    declare @CompletedDate datetime  
     Select @PreferredLanguage=PreferredLanguage  
   , @MailOption = MailOption  
     from AffDetail (nolock)  
     where AffID=@AffID   
       
    Select @CompletedDate=current_timestamp  
    Update  AffPayout with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        AdminDesc=isnull(@AdminDesc,AdminDesc),  
        AffDesc=isnull(@AffDesc,AffDesc),  
	  IbcRefNo = @IbcRefNo,  
	  IbcTransId = @IbcTransId
	  ,IBCUsername = (case when isnull(IBCUsername, '') = '' then @IBCUsername else IBCUsername end)  
    where RefID=@RefID and AffID=@AffID  
      
    Update  AffTrans with (rowlock,updlock)  
    set [Status]=@Status,  
        CompletedDate=@CompletedDate,  
        Creator=@UserID  
    where TransID=@TransID and AffID=@AffID       
END TRY  
  
BEGIN CATCH  
 rollback transaction   
    Select --'Insert transaction failed.'  
  @ErrCode = 134  
 return  
    RETURN  
END CATCH  
  
COMMIT TRANSACTION   
  
  
declare @SPName varchar(50), @LogData nvarchar(4000)  
select @SPName = OBJECT_NAME(@@ProcID)   
  
Select @LogData =  'Update status for payout Request. TransID = ' + dbo.Aff_ToString(@TransID) + '. Status = ' + dbo.Aff_ToString(@Status)  
  
EXEC [dbo].[Aff_WriteLog]  
 @Creator=@UserID,   
 @AffID=@AffID,  
 @Typename= 'Payout',   
 @SPName=@SPName ,  
 @RefNo=@RefNo,  
 @IP =@IP,  
 @Details=@LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_PaymentRequestIns]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_PaymentRequestIns]  
	@AffID int,  
	@Player_UserName varchar(30), 	
	@Player_IBCUserName varchar(30), 	
	@Player_Currency varchar(5),	
	@Amount money,   
	@IP varchar(20),   
	@language varchar(20) = 'en-US',  
	@PreferredLanguage varchar(5)='en-US' OUTPUT,  
	@MailOption bit = 1 Output,
	@TransDate datetime=null OUTPUT,  
	@TransID bigint =0 OUTPUT,  
	@ErrCode int = 0 OUTPUT
AS  
begin  
/*  
Created: 20130314@Johnny  
Task : Insert an payment request from Affiliate  
DB: DB052.Affiliate_MYM  
Original:   
  
Revisions:  
	Change SName='SupportedBaseCurrencies' to SName='AFF_PlayerCurrencies' 
	- 
  
Param's Explanation:  
.@AffID: Affiliate id,  
.@Amount : Amount to withdraw  
.@IP: ip of computer sent,  
• @ErrCode:  
= 0: Transaction recorded successfully.  
> 0: Insert unsuccessful.  
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
Declare @TransType int  
select @TransType=202  
--Checking Affiliate ID  
if(not exists (select 1 from AffInfo (nolock) where affid=@AffID and Status='approved' and IsClosed=0 ))  
 begin  
 Select --'Oops, Your account is not existed or closed. Please contact administrator.' 
   @ErrCode = 107  
      return   
 end  
--Checking Amount  
if(@Amount<=0)  
begin  
  Select --'Sorry, amount is invalid.'    
   @ErrCode = 135  
          return  
end  
-- Checking whether this account has a pending request.  
if Exists(Select 1 from AffPayout with(nolock) where AffID = @AffID and status = 'Pending')  
Begin  
 Select --'You have a pending request. In order to create a new request, please cancel the pending one or wait until it has been processed.'     
 @ErrCode = 130  
 return  
End  
  
--Checking Balance Brought Forward  
DECLARE @AffBalance money
SET @AffBalance = dbo.Aff_GetAffBalance(@AffID)
if((@AffBalance<=0) OR (@Amount > @AffBalance))
begin  
   Select --'Sorry, this Affiliate does not have enough money to withdraw.'  
      @ErrCode = 131      
  return    
end  
  
--Get all related info and Check Preferred Payment  
declare @PreferredPayment varchar(20),@AffCurrencyID smallint, @AffCurrency varchar(5), @Member_ExRate float  

Select  @PreferredPayment= PreferredPayment, @PreferredLanguage=PreferredLanguage, @MailOption = MailOption  
from AffDetail (nolock)  
where AffID=@AffID   
   
 IF @PreferredPayment <> 'Player' --Just support transfer to player account  
 BEGIN  
  Select --'Sorry! The [Neteller, Bank Transfer,.. - affiliate'+'''s chosen one] payment method is not available. At the moment, only '+ '''Player Account'+''' method is supported. Please click here to make a change.'  
      @ErrCode = 137     
  return  
 END  
  
 --Check supported player's currency
declare @SupportedCurrencies varchar(100)

Select @SupportedCurrencies=SValue
from SystemSettings (nolock)
where Type='Meta' and SName='AFF_PlayerCurrencies' 
 
 
 if(@SupportedCurrencies not like '%' + @Player_Currency + '%') 
 begin
	  Select --'We do not support this currency. Please contact administrator.'
    @ErrCode = 138  
	return 	
 end
 
declare @Player_ExRate float, @Player_CurrencyId int
  
   Select  @AffCurrencyId=Currency  
   from AffInfo (nolock)  
   where AffID=@AffID   
	
	Select @Player_CurrencyId = ExchangeId
	From CurrencyConverter nolock
	where PartnerCurrency = @Player_Currency

	--Get player's Exchange rate (row is aff currency, column is player currency)
   Select @Player_ExRate=dbo.Aff_GetExchangeRate(@AffCurrencyId, @Player_CurrencyId, default)
  

-- check min amount for withdrawing  
 DECLARE @SName varchar(50),@MinAmount money   
 SELECT @MinAmount=cast(SValue as money)   
    from SystemSettings with(nolock)   
    where SName = 'AFF_Min'+ @PreferredPayment + @AffCurrency  
  
 IF @MinAmount is not null  and @Amount < @MinAmount   
 BEGIN  
  Select --'Invalid balance account or either the currency or payment method is not supported.'   
   @ErrCode = 133    
  return  
 END  
 
 Declare @SysCurrency varchar(5), @SysCurrencyId smallint, @SysExRate float
 
 Select @SysCurrency=SValue
 from SystemSettings (nolock)
 where Type='Meta' and SName='SystemCurrency'

 Select @SysCurrencyId = ExchangeId
 From Exchange nolock
 where Code = @SysCurrency
 
	Select @SysExRate=dbo.Aff_GetExchangeRate(@AffCurrencyId, @SysCurrencyId, default)


If (Exists(Select 1 From AffDetail nolock where AffId = @AffId and Player_Currency is null))
Begin--Update Player currency if it is null
	update AffDetail with(rowlock, updlock)
	Set Player_Currency = @Player_Currency
	where AffId = @AffId
End
  

BEGIN TRANSACTION  
BEGIN TRY  
    declare @RefNo bigint  
	Select @TransDate=current_timestamp

    --Insert into AffPayout(AffID,IBCCustID,UserName,IBCUserName,AffCurrency,Amount,MemberCurrency,MemberExRate,AffPayout,SysCurrency,SysExRate,TransDate,Status)  
    --values(@AffID,@Player_IBCCustID,@Player_UserName,@Player_IBCUserName,@AffCurrency,-@Amount,@Player_Currency,@Player_ExRate,-@Amount * @Player_ExRate,@SysCurrency,@SysExRate,@TransDate,'pending')   

	Insert into AffPayout(AffID, UserName, IBCUserName, AffCurrency, Amount, MemberCurrency, MemberExRate, AffPayout, SysCurrency, SysExRate, TransDate, Status)  
    values(@AffID, @Player_UserName, @Player_IBCUserName, @AffCurrencyId, -@Amount, @Player_CurrencyId, @Player_ExRate, -@Amount * @Player_ExRate, @SysCurrencyId, @SysExRate, @TransDate, 'pending')   
    
    Select @RefNo= SCOPE_IDENTITY()  
    
    insert into AffTrans(AffID, TransDate, Amount, Status, Description, Creator, AffCurrency, SysCurrency, SysExRate, TransType, RefID)  
	values(@AffID, @TransDate, -@Amount, 'pending', 'Request payout', @AffID, @AffCurrencyId, @SysCurrencyId, @SysExRate, @TransType, @RefNo)  
    select @TransID=SCOPE_IDENTITY()  
END TRY    
BEGIN CATCH  
	rollback transaction   
	select @@Error
    Select --'Insert transaction failed.'   
	@ErrCode = 134  
    RETURN  
END CATCH  
  
COMMIT TRANSACTION   
         
  
--Write the log   
DECLARE @LogData nvarchar(4000),@SPName varchar(100)  
SELECT @LogData = 'Affiliate request payout. Amount=' +  dbo.Aff_ToString(@Amount)         
  
select @SPName=OBJECT_NAME(@@ProcID)  
   
EXEC [dbo].[Aff_WriteLog]  
	@Creator=@AffID,   
	@AffID=@AffID,  
	@Typename= 'Payout',   
	@SPName=@SPName ,  
	@IP =@IP,  
	@Details=@LogData   
  
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_Logout]    Script Date: 07/30/2013 04:24:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_Logout]  
 @AffId int,  
 @ServerID int = NULL,  
 @Username varchar(30) = NULL  
AS  
/**
 * Created by	: Kaden
 * Date			: 20130607
 * Task			: Create to process logout of admin on Affiliate admin site.  
 * DB			: DB052.Affiliate_MYM  
 * Revisions	:
 *	•
 * Parameters:
 	@AffId: Affiliate Id
	@Username: Username
	@Password: Password
 *  
 */

  
SET NOCOUNT ON  
--Write log to record user logout  
Declare @CustID int, @Creator int, @LoginIP varchar(20), @TypeName varchar(20), @Role varchar(20),  @SubAccID int 
Select @CustID = custid, @ServerID = coalesce(@ServerID,ServerID,''), @LoginIP = IP, @SubAccID=subaccid   
From On_User (nolock) where on_userid = @AffId  
  
select @ServerID=null

SELECT @TypeName = case when @SubAccID=6 then 'LogoutAdmin' else 'LogoutAffiliate' end
  

Delete from On_User where on_userid = @AffId  

--Write log
declare @SPName varchar(50), @LogData nvarchar(200)
select @SPName = OBJECT_NAME(@@ProcID)
SELECT @LogData =  case when @SubAccID=6 then 'Admin' else 'Affiliate' end + case when isnull(@Username,'') = '' then cast(isnull(@custid,'') as varchar(30)) else isnull(@Username,'') end + ' IP:' + isnull(@LoginIP,'') + ' Logout ServerID:' + CAST(isnull(@ServerID,'') as nvarchar(20))    


select @Creator = case when @SubAccID < 0 then abs(@SubAccID) else @CustID end

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Creator,
	@AffID = @CustID,
	@Typename = @TypeName, -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @LoginIP
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_EmailHistoryIns]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_EmailHistoryIns]
	@MID int OUTPUT,
	@creator int=-1,
	@content nvarchar(4000),
	@sender nvarchar(100),
	@affiliate varchar(30)=null,
	@email nvarchar(50),
	@subject nvarchar(2000),
	@ip nvarchar(15),
	@browser nvarchar(100),
	@sessionid nvarchar(100),
	@ErrCode int = 0 OUTPUT
AS
begin
/*
Created: 20090626@VinhTrinh
Task : Insert new email for EmailHistory
DB: DB052.Affiliate_MYM
Original:

Revisions:


Param's Explanation:
.@MID: OUTPUT of mail id,
.@creator : id of customer sent this email
.@content: content of this email,
.@sender: sender name,
.@affiliate: name of affiliate in the system,
.@email: email of sender,
.@subject: email subject,
.@ip: ip of computer sent,
.@browser: name of browser,
.@sessionid: ASP.NET session id,
• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

--check all of parameter is valid.
declare @affiliateid int,@maximumPer10minutes int --maximum of 20 emails per 10 minutes for each session

select @affiliateid=-1,@maximumPer10minutes=20
--Check creator name
if(@creator<>-1 and not exists(select 1 from AffInfo with (nolock) where AffId=@creator))
begin
	begin 
            select @ErrCode=160
            return
      end 
end
--check affiliate username
if(@affiliate is not null)
begin
     select @affiliateid=AffID
     from AffInfo  with (nolock)  
     where username=@affiliate
    if (@@rowcount<>1)
      begin 
			select @affiliateid=-1            
      end           
end

--check content
if (isnull(@content,'')='')
  begin
      select @ErrCode=161
            return
  end
--check sender name
 if (isnull(@sender,'')='')
  begin
      select @ErrCode=162
            return
  end
 
--check email
if (isnull(@email,'')='')
  begin
      select @ErrCode=163
            return
  end

--check mail subject
if (isnull(@subject,'')='')
  begin
      select @ErrCode=164
            return
  end

--check ip
if (isnull(@ip,'')='')
  begin
      select @ErrCode=165
            return
  end

--check browser
if (isnull(@browser,'')='')
  begin
      select @ErrCode=166
            return
  end

--check session id
if (isnull(@sessionid,'')='')
  begin
      select @ErrCode=167
            return
  end
--Check is allow to send email (just allow to send maximum of @maximumPer10minutes per 10 minutes)
--if (@affiliateid<>-1)
--begin
	declare @count int
	select @count=count(1) from [EmailHistory] with (nolock)
	where sessionid=@sessionid and datediff(mi,createddate,current_timestamp)<=10

	if(@count>@maximumPer10minutes)
	begin
			Select @ErrCode=168
				return
	end
--end
BEGIN TRANSACTION
INSERT INTO [dbo].[EmailHistory]
           ([content]
           ,[sender]
           ,[creator]
           ,[AffID]
           ,[affname]
           ,[email]
           ,[subject]
           ,[createddate]
           ,[ip]
           ,[browser]
           ,[sessionid]
           )
     VALUES
           (@content
           ,@sender
           ,@creator
           ,@affiliateid
           ,@affiliate
           ,@email
           ,@subject
           ,getdate()
           ,@ip
           ,@browser
           ,@sessionid)
           
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrCode = 169
	return
END

SELECT @MID = SCOPE_IDENTITY()
COMMIT TRANSACTION

DECLARE @LogData nvarchar(200)
SELECT @LogData = 'Insert into EmailHistory MID:' + dbo.Aff_ToString(@MID)

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

EXEC [dbo].[Aff_WriteLog]
	@Creator=@creator,	
	@AffID = @affiliateid, 
	@TypeName= 'Email',	
	@SPName=@SPName,
	@IP =@IP,
	@Details=@LogData
	
end
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateUpdPwd]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateUpdPwd]
	@AffID int,
	@OldPwd nvarchar(50)=null,
	@AffPwd nvarchar(50),
	@UserID int = null,
	@IP varchar(20),
	@Language varchar(20) = 'en-US',
	@ErrCode int = 0 OUTPUT
AS
/*
	Created: 200908230@DungTong
	Task : Admin Reset Password for Affiliate or Affiliate change password
	DB: DB052.Affiliate_MYM

	Revisions:
	  - 20090930@VinhTrinh: Admin Change Affiliate Password
	Param's Explanation:
	• 
*/

SET NOCOUNT ON

--Check permission-----------------------------
if @OldPwd is null
BEGIN
	EXEC [dbo].[Aff_Con_CheckPermission] 
		@custid=@UserID,
		@funcname='[Affiliate]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output
		
	If @ErrCode <> 0
		RETURN
END
-----------------------------------------------
if not exists(select 1 from AffInfo with (NOLOCK) 
				where AffID = @AffID
				and (case when (@OldPwd is not null and Password = @OldPwd) or @OldPwd is null then 1 
						else 0 end ) = 1 )
BEGIN
	Select @ErrCode = 150
	RETURN 
END

UPDATE AffInfo  with (ROWLOCK, UPDLOCK)
SET Password=@Affpwd
where AffID=@AffID

declare @SPName varchar(50), @LogData nvarchar(200)
Select @LogData = 'Reset password'
select @SPName = OBJECT_NAME(@@ProcID)
select @UserID = isnull(@UserID, @AffID)

EXEC [dbo].[Aff_WriteLog]
	@Creator = @UserID,
	@AffID = @AffID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @IP
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateUpdInfo]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Aff_User_AffiliateUpdInfo]
    @AffId int ,
    @userid int,
    @firstname nvarchar(50) = NULL,
    @lastname nvarchar(50) = NULL,
    @Gender bit = null,
    @country nvarchar(50) = NULL,
    @email nvarchar(50) = NULL,
    @password varchar(40)=NULL,
    @phone nvarchar(50) = NULL,
    @mobilephone nvarchar(50) = NULL,
    @address nvarchar(80),
    @city nvarchar(50) = NULL,    
    @state nvarchar(50) = NULL,
    @postal nvarchar(50) = NULL,
    @emailformat bit = null,
    @currency smallint = null,
    @playerCurrency nvarchar(50) = null,
     --Add for Personalized Site
    @IsPageEnabled bit=0,
    @Level int=0,  
    ---------------------------------------------------------------------------------
    -- Parameter for Affiliate info(use for update/insert data to DB03)
    @SiteURL varchar(100)=NULL,
    @MoreSiteURLs varchar(1000) = NULL,
    @PreferredLanguage varchar(11)=NULL,
    @PreferredPayment    varchar(20), --Player, Neteller, Moneybookers, Wire, Cheque
    @Player_Username    varchar(30) = NULL,
    @Neteller_AccountID    varchar(50) = NULL,
    @Moneybookers_Email    varchar(50) = NULL,
    @Wire_BankName        nvarchar(100) = NULL,
    @Wire_BankAddress    nvarchar(200) = NULL,
    @Wire_SwiftCode        nvarchar(20) = NULL,
    @Wire_AccountName    nvarchar(100) = NULL,    
    @Wire_AccountNo        varchar(50) = NULL,
    @Cheque_FullName    nvarchar(200) = NULL,
    @Cheque_Address        nvarchar(200) = NULL,
    @Cheque_City        nvarchar(50) = NULL,
    @Cheque_State        nvarchar(50) = NULL,
    @Cheque_Postal        nvarchar(50) = NULL,
    @Cheque_Country        varchar(50) = NULL,
    ---------------------------------------------------------------------------------
    @language varchar(20) = 'es-ES',
    @IP varchar(20),
    @ErrCode int = 0 OUTPUT
AS
/*Updated: 20090324@VinhTrinh
Task : Update affiliate infor.
DB: DB052.Affiliate_ZZun
Original : [Aff_AffiliateUpdInfo]
Revisions:
    Peter@20100209 : Check If Admin update Player_UserName, we must make sure there is no pending payment request.
    Johnny@20110228 : Do not allow affiliate update player_user if they have already
    Johnny@20130319 : Do not allow update currency
Param's Explanation:
• @AffId : Affiliate custid
• @userid : user update.
• @firstname : update firstname.
....
*/

SET NOCOUNT ON

--Check permission(If AffId = userid => Affiliate update info else Admin Update Aff info)-----------------------------
if @AffId <> @userid
Begin
    EXEC [dbo].[Aff_Con_CheckPermission] 
        @custid=@UserID,@funcname='[Affiliate]',
        @System = 'AFFILIATE',
        @ErrCode=@ErrCode output
    
    If @ErrCode <> 0
        RETURN
End

--Check If we change player_username

if (@Player_Username Is not null AND @Player_Username <> (Select Player_UserName from AffDetail with (nolock) where AffId=@AffID)
     and exists (Select 1 from AffPayout with (nolock) where AffID=@AffID and Status='pending') 
    )
    
 BEGIN
    SELECT @ErrCode = 170
    return
    
 END   
-----------------------------------------------


--Check duplicate Email 

IF Exists(Select 1 From AffInfo a with(nolock) where a.email=@email and a.AffId <> @AffId and a.Status <> 'Disapproved')
BEGIN
    SELECT @ErrCode = 121
    return
END    
/*
-- Check Currency is Editable
declare @CurrencyCurrent smallint
Select @CurrencyCurrent =currency
from AffINfo (nolock)
where AffID=@AffID


if(@Currency<>@CurrencyCurrent and exists (select top(1)  1 from Memberdaily (nolock) where AffID = @AffID))
begin
    SELECT @ErrMsg = case @Language 
                        when 'en-US' then 'Cannot change the currency of this Affiliate!'
                        when 'zh-TW' then N'Cannot change the currency of this Affiliate!'
                        when 'zh-CN' then N'Cannot change the currency of this Affiliate!'
                        when 'th-TH' then N'Cannot change the currency of this Affiliate!'
                        when 'es-ES' then N'Cannot change the currency of this Affiliate!'
                        when 'vi-VN' then N'Cannot change the currency of this Affiliate!'
                        when 'id-ID' then N'Cannot change the currency of this Affiliate!'
                        else N'Cannot change the currency of this Affiliate!'
                        end, @ErrCode = 1003
    return
end
*/
Begin Transaction

UPDATE AffInfo with(rowlock,updlock) 
SET firstname = isnull(@firstname,firstname),
    lastname = isnull(@lastname,lastname),
    email = isnull(@email,email),
    Password = isnull(@password,Password),
    IsPageEnabled = isnull(@IsPageEnabled,IsPageEnabled),
    [Level] = isnull(@Level,[Level])
    ,Currency=(case when status in ('Pending','Disapproved') then  isnull(@currency,currency) else currency end)
    
WHERE AffId = @AffId

IF @@error<>0 
BEGIN
    SELECT @ErrCode = 171                     
    RollBack Transaction
    RETURN
END


UPDATE AffDetail  with(rowlock,updlock) 
SET  
    Gender = isnull(@Gender,Gender),
    CountryID = isnull(@country, countryID),
    phone = isnull(@phone,phone),
    mobilephone = isnull(@mobilephone,mobilephone),
    address = isnull(@address,address),
    city = isnull(@city,city),
    state = isnull(@state,state),
    postal = isnull(@postal,postal),
    SiteURL=isnull(@SiteURL,SiteURL),  
    MoreSiteURLs=@MoreSiteURLs,  
    PreferredLanguage = isnull(@PreferredLanguage, PreferredLanguage),
    PreferredPayment=@PreferredPayment, 
    --Player_IBCCustID=@Player_IBCCustId, 
    Player_Username=case when @AffId <> @UserId then @Player_Username else isnull(Player_Username, @Player_Username) end,  
    Player_Currency = @playerCurrency,
    Neteller_AccountID=@Neteller_AccountID,  
    Moneybookers_Email=@Moneybookers_Email,  
    Wire_BankName=@Wire_BankName,  
    Wire_BankAddress=@Wire_BankAddress,  
    Wire_SwiftCode=@Wire_SwiftCode,  
    Wire_AccountName=@Wire_AccountName,  
    Wire_AccountNo=@Wire_AccountNo,  
    Cheque_FullName=@Cheque_FullName,  
    Cheque_Address=@Cheque_Address,  
    Cheque_City=@Cheque_City,  
    Cheque_State=@Cheque_State,  
    Cheque_Postal=@Cheque_Postal,  
    Cheque_Country=@Cheque_Country    ,
    MailOption = @EmailFormat 
where AffId = @AffId

IF @@Error <> 0
BEGIN 
    SELECT @ErrCode = 172
    Rollback Transaction
    RETURN
END
Commit Transaction

--Update succeeded

declare @SPName varchar(50), @Detail nvarchar(4000)
select @SPName = OBJECT_NAME(@@ProcID) 

Select @Detail = 'Update Affifilate''s Info 
firstname='+ dbo.Aff_ToString(@firstname) + ',
lastname='+ dbo.Aff_ToString(@lastname) + ',
Gender='+ dbo.Aff_ToString(@Gender) + ',
country='+ dbo.Aff_ToString(@country) + ',
email='+ dbo.Aff_ToString(@email) + ',
password='+ dbo.Aff_ToString(@password) + ',
phone='+ dbo.Aff_ToString(@phone) + ',
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',
address='+ dbo.Aff_ToString(@address) + ',
city='+ dbo.Aff_ToString(@city) + ',
state='+ dbo.Aff_ToString(@state) + ',
postal='+ dbo.Aff_ToString(@postal) + ',
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',
PreferredPayment='+ dbo.Aff_ToString(@PreferredPayment) + ',
PreferredLanguage='+ dbo.Aff_ToString(@PreferredLanguage) + ',
Player_Username='+ dbo.Aff_ToString(@Player_Username) + ',
Player_Currency='+ @playerCurrency + ',
Neteller_AccountID='+ dbo.Aff_ToString(@Neteller_AccountID) + ',
Moneybookers_Email='+ dbo.Aff_ToString(@Moneybookers_Email) + ',
Wire_BankName='+ dbo.Aff_ToString(@Wire_BankName) + ',
Wire_BankAddress='+ dbo.Aff_ToString(@Wire_BankAddress) + ',
Wire_SwiftCode='+ dbo.Aff_ToString(@Wire_SwiftCode) + ',
Wire_AccountName='+ dbo.Aff_ToString(@Wire_AccountName) + ',
Wire_AccountNo='+ dbo.Aff_ToString(@Wire_AccountNo) + ',
Cheque_FullName='+ dbo.Aff_ToString(@Cheque_FullName) + ',
Cheque_Address='+ dbo.Aff_ToString(@Cheque_Address) + ',
Cheque_City='+ dbo.Aff_ToString(@Cheque_City) + ',
Cheque_State='+ dbo.Aff_ToString(@Cheque_State) + ',
Cheque_Postal='+ dbo.Aff_ToString(@Cheque_Postal) + ',
Cheque_Country='+ dbo.Aff_ToString(@Cheque_Country) + ',
IsPageEnabled='+ dbo.Aff_ToString(@IsPageEnabled) + ',
Level='+ dbo.Aff_ToString(@Level) + ',
Currency'+ dbo.Aff_ToString(@Currency) + ',
language='+ dbo.Aff_ToString(@language) 

EXEC [dbo].[Aff_WriteLog]
    @Creator=@UserId,    
    @AffID=@AffID,
    @Typename= 'UserInfo',    
    @SPName=@SPName ,
    @IP =@IP,
    @Details=@Detail    
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateStatementHistorySel]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateStatementHistorySel]  
	@AffId int,  
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT  
AS  
/*Created: 20091225@Peter
Task : Getting all of transactions for an affiliate (Monthly transfer, Payment Request , Adjustment)
DB: DB052.Affiliate_ZZun
Original: [Aff_User_AffiliateStatementHistorySel]  
Revisions:  	
	+ 20130813@Don: Fixed bug [Statement history - Data in Satement history table is not ordered] (redmine.nexcel.vn/issues/4327)

Param's Explanation:  
• @AffID : Affiliate custid  
• @PageSize : Size of page
• @PageIndex : current page
• @TotalPages : number of pages
• @NRows : number of rows
*/  
SET NOCOUNT ON

declare @AffTrans table(TransId bigint, MonthDate SmallDatetime, TransType int, Amount money, Status varchar(20), Creator nvarchar(50), Description varchar(200))
declare @Month int,
       @Year int,
       @Amount money ,      
       @Currentdate datetime,
       @NetPercentReceived float
       
select @NetPercentReceived=1.0,@CurrentDate=current_timestamp     

exec [dbo].[Aff_CalMonthlyEarningCurrent] 
@AffID =@AffID,
@Amount=@Amount OUTPUT

insert into @AffTrans
select 0 as TransID,current_timestamp as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'Current Month Statistics' as Description              

--Neu thang roi chua calculate va user duoc approve tu thang roi tro ve truoc
if(not exists (select top(1) 1 from AffCommission with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0) and 
  datediff(m,(select ApprovedDate from AffInfo with (nolock) where AffID=@AffID),@CurrentDate) >=1
  and exists (select top(1) 1 from AffDailySummary with (nolock) where AffID=@AffID and datediff(m,winlostdate,dateadd(m,-1,@CurrentDate))=0))
BEGIN
  select @Month=month(dateadd(m,-1,@CurrentDate)),@Year=Year(dateadd(m,-1,@CurrentDate))
  exec [dbo].[Aff_CalMonthlyEarning] 
		@AffID =@AffID,
		@Month=@Month,
		@Year=@Year,
		@Amount=@Amount OUTPUT

  insert into @AffTrans
  select 0 as TransID,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(m,-1,@CurrentDate))+1,0)) as MonthDate, 0 as TransType,isnull(@Amount,0)*@NetPercentReceived as Amount,'Current' as Status,'' as Creator,'UnCalculated Month' as Description	
END

insert into @AffTrans

select TransID, a.TransDate as MonthDate, TransType, (case when transtype=202 then abs(a.Amount) else a.Amount end) as Amount, (case when transtype=203 then 'B/F' else a.Status end) as  Status,

case when a.Status in ('Pending','Cancelled') and a.TransType=202 then ai.UserName
                 when a.TransType=201  then 'System'				  
			      else i.username
			end  as Creator,

 case when TransType = 203 then '' else coalesce(p.AffDesc,a.Description) end as Description
from AffTrans a (nolock)
      inner join AffInfo ai (nolock) on ai.AffID= a.AffID
     left join AffPayout p (nolock) on p.RefID=a.RefID
	left join AdminUser i with (nolock) on i.custid=a.Creator 
where a.AffId = @AffId
	and TransType in (202, 203)--202: Payment request and 203 : adjustment
Union All

Select 0 as TransId, a.MonthDate, 201 as TransType, isnull(a.Amount, 0) + isnull(b.Amount, 0) as Amount, 'B/F', 'System',  a.Description
From
	(select TransDate as MonthDate, Amount,  Description
	from AffTrans a (nolock)
	where AffId = @AffId
		and TransType = 201--201: Monthly Transfer
	)a left join
	
	(select TransDate as MonthDate, Amount
	from AffTrans a (nolock)
	where AffId = @AffId
		and TransType = 204--204 : Marketing fee(deduction 20% per Affiliate Net Winlost)
	) b on a.MonthDate = b.MonthDate 


select @NRows = Count(*)
From @AffTrans

DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 
 
select TransId, MonthDate, TransType, Amount, Status, Creator, Description
from  
	(
		select ROW_NUMBER() OVER(ORDER BY MonthDate desc) AS TheCount, 
			TransId, MonthDate, TransType, Amount, Status, Creator, Description
		from @AffTrans
	)m  
where m.TheCount between @RowStart and @RowEnd  order by monthdate desc
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateRecoverPwd]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateRecoverPwd]
	@AffID int,
	@ValidCode varchar(10),
	@NewPwd varchar(40),
	@Email nvarchar(50) = NULL OUTPUT,
	@Username varchar(30)= NULL OUTPUT,
	@Firstname nvarchar(50) = NULL OUTPUT,
	@Lastname nvarchar(50) = NULL OUTPUT,
	@PreferredLanguage varchar(11) = 'en-US' OUTPUT,
	@MailOption bit = 0 OUTPUT,
	@Language varchar(20) = 'en-US',
	@ErrCode int = 0 OUTPUT
AS
/*
	Created: 20090930@VinhTrinh:
	Task : Affiliate require new password when they forget it.
	DB: DB052.Affiliate_MYM

	Revisions:
	  - 20130625: Long.Luu, modify for Aff User Core
	Param's Explanation:
	• @Email email request password
	• @ValidCode code generate to affiliate when using forget password
	• @NewPwd Generate random password and send to Affiliate
	• @AffID return affid
	• @Username return username
	• @Firstname return firstname
	• @Lastname return lastname
*/
SET NOCOUNT ON

Select @PreferredLanguage = PreferredLanguage, @MailOption = MailOption
	From AffDetail with(nolock) 
	Where AffId=@AffId
	
IF Exists(Select 1 FROM AffDetail with(nolock) WHERE AffId=@AffId and ValidCode=@ValidCode and datediff(hh, convert(datetime,CodeExpiry), current_timestamp)< 24)
BEGIN
	UPDATE AffInfo with(rowlock,updlock)
	SET Password=@NewPwd--, pwdexpiry=dateadd(dd, 30, CURRENT_TIMESTAMP),answer='',question=''
	WHERE AffId=@AffId
	
	UPDATE AffDetail with(rowlock,updlock)
	SET ValidCode='', CodeExpiry = null--, pwdexpiry=dateadd(dd, 30, CURRENT_TIMESTAMP),answer='',question=''
	WHERE AffId=@AffId
	
	Select @Email=email,@UserName=UserName,@ErrCode=0,@Firstname = firstname, @Lastname = lastname
	From AffInfo with(nolock) 
	Where AffId=@AffId
	
	
END
ELSE
BEGIN
	SELECT @ErrCode = 106 
			--'The address that you have used to request a new password is not valid.'
	RETURN 
END

declare @SPName varchar(50), @LogData nvarchar(300)
Select @LogData = 'Recover password for customer AffiliateID:' + dbo.Aff_ToString(@AffId) 
select @SPName = OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @AffID,
	@AffID = @AffID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateLogin]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateLogin]  
  @Username VARCHAR(50),  
  @Password VARCHAR(50),  
  @LoginIP VARCHAR(20),  
  @Language VARCHAR(20) = 'en-US',   
  @InputAffType INT = 1, --Check Kiosk system login  
  @ServerID INT, -- Trace log server when use load balancer server 
  @NetSessionID varchar(30), 
  @OnUserID int = 0 OUTPUT,  
  
  @AffId INT = 0 OUTPUT,   
  @FirstName NVARCHAR(50) ='' OUTPUT,    
  @LastName NVARCHAR(50) ='' OUTPUT,    
  @Email NVARCHAR(50)='' OUTPUT,  
  @MailOption BIT = 1 OUTPUT,    
  @PreferLang VARCHAR(11) = 'en-US' OUTPUT,  
  @HasSecurityQuestion BIT=1 OUTPUT,  
  @IsAllowedPersonalizedPage BIT=0 OUTPUT,  
  @AffLevel INT=0 OUTPUT,  
  @AffType INT = 1 OUTPUT,  
  @Currency VARCHAR(5) = 'USD' OUTPUT,         
  @ErrCode INT = 0 OUTPUT  
AS    
/**  
 * Created by : Kaden  
 * Date   : 20130318  
 * Task   : Login to Affiliate   
 * DB   : DB052.Affiliate_MYM    
 * Revisions :  
 * •  
 * Parameters:  
 @Username: Username  
 @Password: Password  
 @LoginIP: IP login  
 *    
 */  
  
SET NOCOUNT ON    
DECLARE @LogData NVARCHAR(200)    
    
DECLARE @db_custid INT, @db_userpwd NVARCHAR(50), @db_roleid TINYINT, @failedcount INT    
DECLARE @IsClosed BIT, @status VARCHAR(30),@IsLocked BIT,@LastLoginDate Datetime    
DECLARE @SPName VARCHAR(50)    
  
SELECT @SPName = OBJECT_NAME(@@ProcID)     
  
SELECT  @db_custid = i.affID, @db_userpwd = ISNULL(Password, ''), @failedcount = LoginCount,  
  @LastLoginDate=ISNULL(LastLoginDate,CURRENT_TIMESTAMP),    
  @FirstName = firstname,@LastName = lastname,@Email = Email,   
  @IsClosed = IsClosed, @Status = Status,@IsLocked=ISNULL(IsLocked,0),    
  @HasSecurityQuestion = (CASE WHEN Question IS NULL OR Answer IS NULL THEN 0 ELSE 1 END),    
  @MailOption = MailOption, @PreferLang = d.PreferredLanguage,   
  @IsAllowedPersonalizedPage=i.IsPageEnabled,@AffLevel=i.Level, @AffType = AffType,  
  @Currency=ISNULL(e.Code,'USD')  
FROM AffInfo i WITH(NOLOCK)    
 INNER JOIN AffDetail d WITH(NOLOCK) ON i.AffID = d.affID    
 LEFT JOIN Exchange e WITH(NOLOCK) ON i.Currency = e.ExchangeID    
WHERE i.username = @UserName OR i.Email= @UserName     
     
-- user not found    
IF (@@ROWCOUNT = 0 OR (@InputAffType = 3 AND @AffType <> 3) or (@InputAffType <> 3 AND @AffType = 3))--Check for kiosk system  
BEGIN    
  SELECT @LogData = 'Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'    
  EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData    
  SELECT @ErrCode=101          
  RETURN    
END    
    
--check Account IsClosed    
IF(ISNULL(@IsClosed,0) = 1)    
BEGIN    
  SELECT @LogData = 'Failed login attempt (account is Closed), ServerID:' + dbo.Aff_ToString(@ServerID)    
  EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData    
  SELECT @ErrCode=102    
  RETURN  
END      
    
--check Account Is Locked     
IF (ISNULL(@IsLocked,0) = 1 AND DATEDIFF(mi,@LastLoginDate,CURRENT_TIMESTAMP)<10)    
BEGIN    
  SELECT @LogData = 'Failed login attempt (account is Locked), ServerID:' + dbo.Aff_ToString(@ServerID)    
  EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData    
  SELECT @ErrCode=103  
  RETURN    
END    
  
UPDATE AffDetail WITH (ROWLOCK, UPDLOCK)    
SET  LastLoginDate = CURRENT_TIMESTAMP    
WHERE AffID = @db_custid    
    
--check pending or expired    
IF @status <> 'Approved'     
BEGIN      
  SELECT @LogData = 'Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)    
  EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData    
     
  SELECT @LogData =  @UserName + ' IP:' + @LoginIP + ' Account not approved.' + dbo.Aff_ToString(@ServerID)    
  EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @Details = @LogData    
     
  SELECT @ErrCode=101       
  RETURN    
END     
    
IF @db_userpwd <> @Password    
 BEGIN    
   SELECT @LogData = 'Failed login attempt (wrong password), ServerID:' + dbo.Aff_ToString(@ServerID)    
   EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData      
      
   SELECT @failedcount = @failedcount + 1      
   IF @failedcount > 5       
   BEGIN    
     UPDATE AffInfo WITH(ROWLOCK, UPDLOCK) SET IsLocked = ~ISNULL(IsLocked,0) WHERE AffID = @db_custid    
    
     SELECT @LogData = 'The A/C is Locked due to 5 wrong password attempts'    
     EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData          
     select @ErrCode=103    
   END    
   ELSE    
   BEGIN    
  SELECT @ErrCode=101    
   END  
       
   UPDATE AffDetail WITH(ROWLOCK, UPDLOCK) SET logincount = @failedcount WHERE AffID = @db_custid      
   RETURN    
 END    
    
-- Successful    
SELECT @AffId = @db_custid    
--Unlock user after 10 minute login sucessfully automatically    
    
if(ISNULL(@IsLocked,0) = 1)    
BEGIN     
  UPDATE AffInfo WITH(ROWLOCK,UPDLOCK)    
  SET isLocked=~ isLocked    
  WHERE AffID = @db_custid    
END    
    
UPDATE AffDetail WITH(ROWLOCK, UPDLOCK)    
SET logincount = 0, LastLoginIP = @LoginIP, LastLoginDate = CURRENT_TIMESTAMP    
WHERE AffID = @db_custid    

update on_user with (ROWLOCK) set IsKickedout=1, ServerID=0 where CustID = @AffId

--Login onuser
insert into on_user  
 (custid, NetSessionID, on_sessionid, ServerId, IsKickedout, IP, SubAccID, reload_time)  
values  
 (@AffId, @NetSessionid, 0, @ServerID, 0, @LoginIP, 0, current_timestamp)  

Select @OnUserID = SCOPE_IDENTITY()  

SELECT @LogData = 'Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)    
EXEC [dbo].[Aff_WriteLog] @Creator = @db_custid, @AffID = @db_custid, @Typename = 'LoginAffiliate', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateInternalLogin]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateInternalLogin]
	@AdminID int,
	@UserName varchar(50),	
	@LoginIP varchar(20),
	@ServerID int,	
	@Language varchar(20) = 'en-US',
	@InputAffType int = 1,--Check Kiosk system login
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
 *	Created: 20090316@Ken
 *	Task : Login Affiliate from Admin site (internal login)
 *	DB: DB052.Affiliate_MYM
 *
 *	Revisions:			
*/
SET NOCOUNT ON
declare @LogData nvarchar(200)

Declare @failedcount int
Declare @closed bit, @status varchar(30)
Declare @AdminUserName varchar(50)
Declare @AffID int
Declare @FirstName nvarchar(50)
Declare @LastName nvarchar(50)
Declare @Email nvarchar(50)
Declare @IsAllowedPersonalizedPage bit
Declare @Currency varchar(6)
Declare @AffType int
Declare @PreferLang varchar(11)
Declare @Prefix varchar(3)
Declare @AffLevel int

declare @SPName varchar(50)
select @SPName = OBJECT_NAME(@@ProcID) 

SELECT @AdminUserName = ''
SELECT @AdminUserName = UserName
FROM AdminUser WITH(NOLOCK)
WHERE CustID = @AdminID

SELECT @AffID = i.affID,
	@failedcount = LoginCount,
	@FirstName = firstname,
	@LastName = lastname,
	@Email = Email,
	@closed = IsClosed,
	@Status = Status,
	@PreferLang = d.PreferredLanguage,
	@IsAllowedPersonalizedPage=i.IsPageEnabled,
	@AffLevel=i.Level,
	@Prefix = isnull(Prefix, '$'),
	@AffType = AffType,
	@Currency = c.CurrencyCode
FROM AffInfo i with (nolock)
	INNER JOIN AffDetail d with(nolock) on i.AffID = d.affID
	left join Exchange e with(nolock) on e.ExchangeID = i.Currency
	inner join Currency c with(nolock) on i.Currency = c.CurrencyID
WHERE i.username = @UserName

-- user not found
IF (@@ROWCOUNT = 0 Or (@InputAffType = 3 and @AffType <> 3) or (@InputAffType <> 3 and @AffType = 3))--Check for kiosk system
BEGIN
	SELECT @LogData = '[FROM ADMIN] Failed login attempt (wrong username), ServerID:' + dbo.Aff_ToString(@ServerID) + ', [' + @UserName + ']'
	EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData

	select @ErrMsg = case @Language	when 'en-US' then 'Wrong username or password.'
									when 'zh-TW' then N'????????'
									when 'zh-CN' then N'????????'
									when 'J' then N'Wrong username or password.'
									when 'th-TH' then N'Wrong username or password.'
									when 'es-ES' then N'El nombre de usuario o la contraseña son incorrectos.'
									when 'vi-VN' then N'Tên truy c?p ho?c m?t kh?u sai.'
									when 'id-ID' then N'Nama pengguna dan kata sandi salah.'
									else N'Wrong username or password.'
								end	,@ErrCode=1006
END

IF IsNull(@closed, 1) = 1
	BEGIN
		SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is closed), ServerID:' + dbo.Aff_ToString(@ServerID)
		EXEC [dbo].[Aff_WriteLog] 
			@Creator = @AdminID, 
			@AffID = @AffID, 
			@Typename = 'LoginAdmin', 
			@SPName = @SPName, 
			@IP = @LoginIP, 
			@Details = @LogData

		select @ErrMsg =	case @Language	when 'en-US' then 'Your account is closed. Please contact your administrator!'
								when 'zh-TW' then N'????. ??????.'
								when 'zh-CN' then N'????,??????'
								when 'J' then N'Your account is closed. Please contact your administrator!'
								when 'th-TH' then N'Your account is closed. Please contact your administrator!'
								when 'es-ES' then N'Se ha cerrado su cuenta. Póngase en contacto con el administrador.'
								when 'vi-VN' then N'Tài kho?n c?a b?n b? dóng. Vui lòng liên h? v?i qu?n tr? viên c?a b?n!'
								when 'id-ID' then N'Rekening Anda sudah ditutup. Harap menghubungi administrator Anda!'
								else N'Your account is closed. Please contact your administrator!'
							end	,@ErrCode=1008
	END

--check pending or expired
IF @status <> 'Approved'	
BEGIN  
	SELECT @LogData = '[FROM ADMIN] Failed login attempt (account is not approved), ServerID:' + dbo.Aff_ToString(@ServerID)
	EXEC [dbo].[Aff_WriteLog] 
		@Creator = @AdminID, 
		@AffID = @AffID, 
		@Typename = 'LoginAdmin', 
		@SPName = @SPName, 
		@IP = @LoginIP, 
		@Details = @LogData
	
	select @ErrMsg =	case @Language	when 'en-US' then 'Account is not approved. Please contact your administrator!'
								when 'zh-TW' then N'?????,???????'
								when 'zh-CN' then N'?????,??????'
								when 'J' then N'Account is not approved. Please contact your administrator!'
								when 'th-TH' then N'Account is not approved. Please contact your administrator!'
								when 'es-ES' then N'No se ha aprobado la cuenta. Póngase en contacto con el administrador.'
								when 'vi-VN' then N'Tài kho?n không du?c ch?p nh?n. Vui lòng liên h? v?i qu?n tr? viên c?a b?n!'
								when 'id-ID' then N'Rekening tidak disetujui. Harap menghubungi administrator Anda!'
								else N'Account is not approved. Please contact your administrator!'
						end	,@ErrCode=1009
END 

SELECT @LogData = '[FROM ADMIN] Successful login, ServerID:' + dbo.Aff_ToString(@ServerID)
EXEC [dbo].[Aff_WriteLog] @Creator = @AdminID, @AffID = @AffID, @Typename = 'LoginAdmin', @SPName = @SPName, @IP = @LoginIP, @Details = @LogData

SELECT @AdminUserName [AdminUserName],
	@FirstName FirstName,
	@LastName LastName, 
	@Email Email, 
	@AffID AffID, 
	@PreferLang PreferLang, 
	@Prefix Prefix, 
	@IsAllowedPersonalizedPage IsAllowedPersonalizedPage, 
	@AffLevel AffLevel, 
	@AffType AffType, 
	@Currency Currency
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateIns]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_AffiliateIns    Script Date: 11/3/2009 5:46:27 PM ******/    
CREATE PROCEDURE [dbo].[Aff_User_AffiliateIns]     
 @AffId int OUTPUT,   
 @AffType tinyint = 1,     
 @firstname nvarchar(50),      
 @lastname nvarchar(50),      
 @Gender bit = null,      
 @email nvarchar(50),      
 @phone nvarchar(50),      
 @mobilephone nvarchar(50),      
    
 @address nvarchar(80),      
 @city nvarchar(50),       
 @state nvarchar(50),      
 @postal nvarchar(50),      
 @country nvarchar(50),       
 @emailformat bit = null,    
 @Currency int,    
 --------------------------------------------------       
 @SiteURL varchar(100),       
 @MoreSiteURLs varchar(1000) = NULL,      
 @PreferredLanguage varchar(5),      
 @PreferredPayment varchar(20), --Player, Neteller, Moneybookers, Wire, Cheque      
 @Player_Username varchar(30),      
 @Neteller_AccountID varchar(50) = null,      
 @Moneybookers_Email varchar(50) = null,      
 @Wire_BankName  nvarchar(100) = null,      
 @Wire_BankAddress nvarchar(200) = null,      
 @Wire_SwiftCode  nvarchar(20) = null,      
 @Wire_AccountName nvarchar(100) = null,       
 @Wire_AccountNo  varchar(50) = null,      
 @Cheque_FullName nvarchar(200) = null,      
 @Cheque_Address  nvarchar(200) = null,      
 @Cheque_City  nvarchar(50) = null,      
 @Cheque_State  nvarchar(50) = null,      
 @Cheque_Postal  nvarchar(50) = null,      
 @Cheque_Country  varchar(50) = null,       
 --------------------------------------------------         
 @Question   nvarchar(120),      
 @Answer    nvarchar(120),      
 @IP varchar(20),      
 @Browser varchar(100)='',  
 @language varchar(5) = 'en-US',      
 @username varchar(30) = NULL OUTPUT,      
 @ErrCode int = 0 OUTPUT,      
 @ErrMsg nvarchar(200) = '' OUTPUT      
AS    
/*        
Created:       
Task : Register new Affiliate      
DB: DB052.Affiliate_ZZun    
Original: [Aff_User_AffiliateIns]      
Revisions:        
    Long@20130911: do not check email existance in case of Kiosk
Param's Explanation:        
• @ErrCode:        
    = 0: Create agent successfully.        
    > 0: Specific Error.        
          
• @ErrMsg: Error description.        
*/       
SET NOCOUNT ON    
    
/*IF Exists(Select 1 From AffInfo with (nolock) where UserName2=@UserName2)      
BEGIN      
 SELECT @ErrMsg = case @Language     
      when 'en-US' then N'Nickname has been used. Please choose another one!'    
      when 'zh-TW' then N'Nickname has been used. Please choose another one!'    
      when 'zh-CN' then N'Nickname has been used. Please choose another one!'    
      when 'th-TH' then N'Nickname has been used. Please choose another one!?'    
      when 'es-ES' then N'Nickname has been used. Please choose another one!'    
      when 'vi-VN' then N'Nickname dã du?c s? d?ng. Vui lòng ch?n Nickname khác!'    
      when 'id-ID' then N'Nickname has been used. Please choose another one!'    
      else N'Nickname has been used. Please choose another one!'      
      end, @ErrCode = 1012    
 return    
END  */    
    
IF (select Name from AffType with(nolock) where TypeID = @AffType) not like '%kiosk%'
BEGIN 
	IF Exists(Select 1 From AffInfo with (nolock) where email=@email and Status <> 'Disapproved')      
	BEGIN      
	 SELECT @ErrMsg = case @Language     
		  when 'en-US' then 'Email Address has been used. Please choose another one!'    
		  when 'zh-TW' then N'?????????,??????????'    
		  when 'zh-CN' then N'?????????,??????????'    
		  when 'th-TH' then N'??????????????????????? ?????????????????????'    
		  when 'es-ES' then N'Esta dirección de correo electrónico ya se ha utilizado. Escoja otra diferente.'    
		  when 'vi-VN' then N'Ð?a ch? Email dã du?c s? d?ng. Vui lòng ch?n d?a ch? khác!'    
		  when 'id-ID' then N'Alamat Email sudah digunakan. Silakan pilih yang berbeda!'    
		  else N'Email Address has been used. Please choose another one!'      
		  end, @ErrCode = 121    
	 return    
	END       
END    
    
--Generate username-----------------      
Exec Aff_GenUsername @username = @username OUTPUT      
    
if exists(select 1 from AffInfo with (nolock) where username = @username)      
BEGIN      
 SELECT @ErrMsg = case @Language     
  when 'en-US' then 'Invalid affiliate information.'    
      when 'zh-TW' then N'?????????,??????????'    
      when 'zh-CN' then N'?????????,??????????'    
      when 'th-TH' then N'????????????????????????????.'     
      when 'es-ES' then N'La información de afiliación no es válida.'     
      when 'vi-VN' then N'Thông tin h?i viên không h?p l?.'     
      when 'id-ID' then N'Informasi afiliasi tidak valid.'     
      else N'Invalid affiliate information.'         
      end, @ErrCode = 122    
 return    
END     
--End generate username-----------------      
    
    
    
    
Insert into AffInfo(    
 [UserName]    
 --,[UserName2]    
 ,[FirstName]    
 ,[LastName]    
 ,[Status]    
 ,[IsClosed]    
 ,[Currency]    
 ,[RegisteredDate]    
 ,[Email]    
 ,[Password]    
 ,[IsLocked]  
 ,[AffType])    
Values    
(    
 @Username    
 --,@Username2    
 ,@FirstName    
 ,@LastName    
 ,'Pending'    
 ,0    
 ,@Currency    
 ,GetDate()    
 ,@Email    
 ,''    
 ,0    
 ,@AffType  
)    
    
if @@error <> 0    
BEGIN      
 SELECT @ErrMsg = case @Language       
    when 'en-US' then 'Create customer failed. Please try again.'      
    when 'zh-TW' then N'???????,?????.'      
    when 'zh-CN' then N'???????,?????.'      
    when 'th-TH' then N'???????????????????? ??????????????????'          
    when 'es-ES' then N'No se ha podido crear el cliente. Vuelva a intentarlo.'      
    when 'KO' then N'??? ????? ??????.  ?? ???? ???? ???? ????.'      
    when 'vi-VN' then N'T?o khách hàng không thành công. Hãy th? l?i.'      
    when 'id-ID' then N'Gagal membuat pelanggan. Harap coba lagi.'      
    else N'Create customer failed. Please try again.'      
   end,      
 @ErrCode = 123      
        
 -- ROLLBACK MANUALLY  `    
 Delete From AffInfo With (ROWLOCK) Where AffId = @AffId      
        
 return      
END      
    
select @AffId = @@IDENTITY    
    
Insert into AffDetail(    
 [AffID]    
 ,[UserName]    
 ,[SiteURL]    
 ,[MoreSiteURLs]    
 ,[PreferredLanguage]    
 ,[Gender]    
 ,[Address]    
 ,[Postal]    
 ,[City]    
 ,[State]    
 ,[CountryID]    
 ,[Phone]    
 ,[MobilePhone]    
 ,[Fax]    
 ,[Question]    
 ,[Answer]    
 ,[PreferredPayment]     
 ,[Player_Username]    
 ,[Neteller_AccountID]    
 ,[Moneybookers_Email]    
 ,[Wire_BankName]    
 ,[Wire_BankAddress]    
 ,[Wire_SwiftCode]    
 ,[Wire_AccountName]    
 ,[Wire_AccountNo]    
 ,[Cheque_FullName]    
 ,[Cheque_Address]    
 ,[Cheque_City]    
 ,[Cheque_State]    
 ,[Cheque_Postal]    
 ,[Cheque_Country]    
 ,[MailOption]    
)    
Values    
(    
 @AFfId    
 ,@Username    
 ,@SiteURL    
 ,@MoreSiteURLs    
 ,@PreferredLanguage    
 ,@Gender    
 ,@address    
 ,@postal    
 ,@city    
 ,@state    
 ,@country    
 ,@phone    
 ,@mobilephone    
 ,''    
 ,@Question    
 ,@Answer    
 ,@PreferredPayment     
 ,@Player_Username    
 ,@Neteller_AccountID    
 ,@Moneybookers_Email    
 ,@Wire_BankName    
 ,@Wire_BankAddress    
 ,@Wire_SwiftCode    
 ,@Wire_AccountName    
 ,@Wire_AccountNo    
 ,@Cheque_FullName    
 ,@Cheque_Address    
 ,@Cheque_City    
 ,@Cheque_State    
 ,@Cheque_Postal    
 ,@Cheque_Country    
 ,@EmailFormat    
)    
if @@error <> 0    
BEGIN      
 SELECT @ErrMsg = case @Language       
    when 'en-US' then 'Create customer failed. Please try again.'      
    when 'zh-TW' then N'???????,?????.'      
    when 'zh-CN' then N'???????,?????.'      
    when 'th-TH' then N'???????????????????? ??????????????????'          
    when 'es-ES' then N'No se ha podido crear el cliente. Vuelva a intentarlo.'      
    when 'KO' then N'??? ????? ??????.  ?? ???? ???? ???? ????.'      
    when 'vi-VN' then N'T?o khách hàng không thành công. Hãy th? l?i.'      
    when 'id-ID' then N'Gagal membuat pelanggan. Harap coba lagi.'      
    else N'Create customer failed. Please try again.'      
   end,      
 @ErrCode = 124      
        
 -- ROLLBACK MANUALLY  `    
 Delete From AffInfo With (ROWLOCK) Where AffId = @AffId      
 Delete From AffDetail With (ROWLOCK) Where AffId = @AffId      
        
 return      
END      
    
    
Declare @LogData varchar(5000), @SPName varchar(100)     
select @SPName = OBJECT_NAME(@@ProcID)    
      
Select @LogData = 'Add new Affifilate    
firstname='+ dbo.Aff_ToString(@firstname) + ',    
lastname'+ dbo.Aff_ToString(@lastname) + ',    
Gender='+ dbo.Aff_ToString(@Gender) + ',    
country='+ dbo.Aff_ToString(@country) + ',    
email='+ dbo.Aff_ToString(@email) + ',    
phone='+ dbo.Aff_ToString(@phone) + ',    
mobilephone='+ dbo.Aff_ToString(@mobilephone) + ',    
address='+ dbo.Aff_ToString(@address) + ',    
city='+ dbo.Aff_ToString(@city) + ',    
state='+ dbo.Aff_ToString(@state) + ',    
postal='+ dbo.Aff_ToString(@postal) + ',    
Currency='+ dbo.Aff_ToString(@Currency) + ',    
SiteURL='+ dbo.Aff_ToString(@SiteURL) + ',    
MoreSiteURLs='+ dbo.Aff_ToString(@MoreSiteURLs) + ',    
PreferredPayment='+ dbo.Aff_ToString(@PreferredPayment) + ',    
PreferredLanguage='+ dbo.Aff_ToString(@PreferredLanguage) + ',    
Player_Username='+ dbo.Aff_ToString(@Player_Username) + ',    
Neteller_AccountID='+ dbo.Aff_ToString(@Neteller_AccountID) + ',    
Moneybookers_Email='+ dbo.Aff_ToString(@Moneybookers_Email) + ',    
Wire_BankName='+ dbo.Aff_ToString(@Wire_BankName) + ',    
Wire_BankAddress='+ dbo.Aff_ToString(@Wire_BankAddress) + ',    
Wire_SwiftCode='+ dbo.Aff_ToString(@Wire_SwiftCode) + ',    
Wire_AccountName='+ dbo.Aff_ToString(@Wire_AccountName) + ',    
Wire_AccountNo='+ dbo.Aff_ToString(@Wire_AccountNo) + ',    
Cheque_FullName='+ dbo.Aff_ToString(@Cheque_FullName) + ',    
Cheque_Address='+ dbo.Aff_ToString(@Cheque_Address) + ',    
Cheque_City='+ dbo.Aff_ToString(@Cheque_City) + ',    
Cheque_State='+ dbo.Aff_ToString(@Cheque_State) + ',    
Cheque_Postal='+ dbo.Aff_ToString(@Cheque_Postal) + ',    
Cheque_Country='+ dbo.Aff_ToString(@Cheque_Country) + ',    
language='+ dbo.Aff_ToString(@language)     
    
EXEC [dbo].[Aff_WriteLog]    
 @Creator=@AffID,     
 @AffID=@AffID,    
 @Typename= 'UserInfo',     
 @SPName=@SPName,    
 @IP =@IP,    
 @Details=@LogData    
GO
/****** Object:  StoredProcedure [dbo].[Aff_User_AffiliateForgotPwd]    Script Date: 07/30/2013 04:24:25 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Aff_User_AffiliateForgotPwd]
	@Email nvarchar(50)=Null,
	@ValidCode nvarchar(10),
	@Language varchar(20) = 'en-US',	
	@AffID int OUTPUT,
	@Username varchar(30) = NULL OUTPUT,
	@Firstname nvarchar(50) = NULL OUTPUT,
	@Lastname nvarchar(50) = NULL OUTPUT, 
	@PreferredLanguage varchar(11) = null Output,
	@MailOption bit = 1 Output,
	@IP varchar(20) = '', 
	@ErrCode int = 0 OUTPUT
AS
/*
	Created: 20090930@VinhTrinh:
	Task : Affiliate require new password when they forget it.
	DB: DB052.Affiliate_MYM

	Revisions:
	  - 20130624: Long.Luu, modify for Aff User Core

	Param's Explanation:
	• @Email email request password
	• @ValidCode 
	• @AffID return affid
	• @Username return username
	• @Firstname return firstname
	• @Lastname return lastname
*/
SET NOCOUNT ON
Declare @IsClosed bit

select @AffID = null

SELECT @AffID=AffID, @Username=c.username, @Firstname = c.firstname, @Lastname = c.lastname, @IsClosed = IsClosed
FROM AffInfo c with(nolock) 
WHERE Email=@Email 
	and Status = 'Approved'


IF @AffID is null
BEGIN
	IF EXISTS(
				SELECT 1 
				FROM AffInfo with(nolock) 
				where Email=@Email and Status <> 'Approved'
			   )
	BEGIN
		SELECT @ErrCode = 105	 
		--Account is not approved. Please contact your administrator!
		RETURN 
	END

	SELECT @ErrCode = 104	
	--You have not entered an email address that we recognise. Please try again or <a href=ContactUs.aspx>contact us</a>. 
	RETURN 
	
END
ELSE IF @IsClosed = 1
BEGIN
	SELECT @ErrCode = 102
	--Your account is closed. Please contact your administrator!	 
	RETURN 
END

--Return preference language and mail option
select @PreferredLanguage = PreferredLanguage, @MailOption = MailOption
FROM AffDetail c with(nolock) 
WHERE AffID=@AffID

	
--Update customer store validcode in answer field,expiry in question field
UPDATE AffDetail with(rowlock,updlock) 
SET ValidCode=@ValidCode, CodeExpiry=dateadd(hh, 24, current_timestamp)
WHERE AffId=@AffId
Select @Errcode=0

--Write log
declare @SPName varchar(50), @LogData nvarchar(300)
Select @LogData = 'Forgot password for affiliateID:' + dbo.Aff_ToString(@AffID) + ' ValidCode:' + @ValidCode
select @SPName = OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @AffID,
	@AffID = @AffID,
	@Typename = 'Password', -- refer to table LogType
	@SPName = @SPName,
	@Details = @LogData,
	@IP = @IP
GO
CREATE PROCEDURE [dbo].[Aff_Link_AffiliateInsClickStatistics]    
    @AffiliateID int,  
    @AffDomain nvarchar(256) = '',--Url is showed in affiliate site
    @PageCode varchar(50)='sports',    
    @LanguageCode varchar(6)='en-US',  
    @IP varchar(20) = '',  
    @Browser nvarchar(50) = '',  
    @URLReferrer nvarchar(300)=NULL, 
    @DomainReferrer nvarchar(300)=null,
    @OS nvarchar(50) = '',  
    @Device nvarchar(50) = '',  
    @BrowserVersion nvarchar(16) = '',  
    @BrowserResolution  nvarchar(16) = '',  
    @BrowserLanguage nvarchar(8) = '',  
    @UserAgent nvarchar(256) = '',  
    @Country nvarchar(256) = '',  
    @RedirectPage nvarchar(256)=NULL OUTPUT,
    @ClickID bigint = 0 OUTPUT,     
    @Language varchar(5)= 'en-US', 
    @ErrCode int = 0 OUTPUT,  
    @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
/*  Created: 20130108@Long
Task : record clicking Banner action with a specific tracking code  
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
	- 20130830@Don: Change way to get country code by using function [GetCountryIDFromIP] instead of retrieving from table IP
*/  

SET NOCOUNT ON  

Declare @AffUsername nvarchar(30), @CountryId varchar(11), @Default12Betdomain nvarchar(100), @IsCasino bit, @LicenseeId nvarchar(20), @LangcodeMemSite nvarchar(5), @ActualPageCode varchar(100)

select @ActualPageCode=SName from SystemSettings (nolock) where SValue=@PageCode and [Type]='CustomerPage'

select @ActualPageCode=coalesce(@ActualPageCode,'sports')


select @URLReferrer = coalesce(@URLReferrer, 'none')
select @LicenseeId = SValue from SystemSettings nolock where SName = 'LicenseeID'
select @LangcodeMemSite = Svalue from SystemSettings nolock where SName = @LanguageCode and [Type] = 'LangMapping'

select @AffUsername = ai.Username, @CountryId = CountryId
from AffDetail ad with(nolock)
    inner join AffInfo ai with(nolock) on ai.AffId = ad.AffId
where ai.AffId = @AffiliateID
    and status='Approved'

--check Affiliate ID  
if (@AffUsername is null)
begin  
    select @ErrCode=101,@ErrMsg='This affiliate does not exists. Please contact administrator!'                                            
    return                            
end 
  
 --Checking Input member IP
IF COALESCE(@IP, '') = ''  
begin  
    select @ErrCode=102, @ErrMsg='The IP is required. Please check!'   
    return               
end  
  
--Get redirect link
 
Declare @AffDomainId int, @AffDomainName nvarchar(255)

Select @AffDomainId = DomainID, @AffDomainName = DomainName
From AffDomain nolock 
where @AffDomain like '%' + DomainName + '%'

select @Default12Betdomain = b.DomainName--If redirect page is null => redirect to this default domain
From AffDomainControl a with (nolock)
    inner join MemberDomain b with (nolock) on a.MemberDomainID = b.DomainID
where a.AffDomainId = @AffDomainId 
    and a.CountryId = '-'
    and [status] = 1


Select @RedirectPage = b.DomainName
from AffDomainControl a with (nolock)
    inner join MemberDomain b with (nolock) on a.MemberDomainID = b.DomainID
where a.CountryID = @CountryId and a.AffDomainId = @AffDomainId and [status] = 1

--Replace Aff Domain by 12bet domain to redirect to 12bet site
Select @RedirectPage = 'http://' + ltrim(rtrim(isnull(@RedirectPage, @Default12Betdomain))) + '?btag=' + @LicenseeId + '_' + cast(@AffiliateID as varchar(15)) + '_{clickid}&lang=' + @LangcodeMemSite + '&act=' + @ActualPageCode


Declare @CountryCode varchar(5), @CurrentDate smalldatetime, @CurrentTime smalldatetime
Set @CountryCode = dbo.GetCountryIDFromIP(@IP)
select @CurrentTime = CURRENT_TIMESTAMP, @CurrentDate = CONVERT(varchar(10), CURRENT_TIMESTAMP, 120)

select top 1 @ClickId = ClickId--, @RedirectPage = RedirectURL
from [ClickStatistics] nolock 
where IP = @IP 
    and [Date] = @CurrentDate
    and [URLReferrer] = @URLReferrer
    and SportCode = @PageCode
    and LanguageCode = @LanguageCode
    and AffId = @AffiliateID
    and Browser = @Browser

if (@ClickId <> 0)
Begin
    Update [ClickStatistics] with(rowlock, updlock)
    set ClickCount = ClickCount + 1
        , [UpdatedTime] = @CurrentTime
    where ClickId = @ClickId

    Select @RedirectPage = replace(@RedirectPage, '{clickid}', @ClickID)
End
Else
Begin
    INSERT INTO [ClickStatistics]  
               ([AffID]
               ,[UpdatedTime]  
               ,[IP]  
               ,[Date]  
               ,[Browser]  
               ,[URLReferrer]
               ,[DomainReferrer]  
               ,[OS]  
               ,[Device]  
               ,[BrowserVersion]  
               ,[BrowserResolution]  
               ,[BrowserLanguage]  
               ,[UserAgent]  
               ,[Country]  
               ,[LanguageCode] 
               ,[SportCode] 
               ,[RedirectURL]
               ,[Status]
               ,[ClickCount])  
    VALUES  
               (@AffiliateID 
               ,@CurrentTime 
               ,@IP  
               ,@CurrentDate 
               ,@Browser  
               ,coalesce(@URLReferrer, 'none')  
               ,coalesce(@DomainReferrer, 'none')
               ,@OS  
               ,@Device  
               ,@BrowserVersion  
               ,@BrowserResolution  
               ,@BrowserLanguage  
               ,@UserAgent  
               ,coalesce(@CountryCode,'(not set)',@Country)  
               ,@LanguageCode--Only store vn for vietnamese
               ,@PageCode
               ,@RedirectPage--if not Casino aff => redirect to main domain
               ,0
               ,1
               )     
    
    select @ClickID = SCOPE_IDENTITY()

    select @RedirectPage = replace(@RedirectPage, '{clickid}', @ClickID)

    update [ClickStatistics] with (rowlock, updlock)
    set [RedirectURL] = @RedirectPage
    where clickId = @ClickID
End
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateAllLanguages] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateAllLanguages] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateCurrenciesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateCurrenciesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateForgotPwd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateInternalLogin] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateLogin] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateRecoverPwd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSelDBTime] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSelDBTime] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSelEditInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSelEditInfo] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateStatementHistorySel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateStatementHistorySel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSupportedLanguagesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateSupportedLanguagesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateUpdInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_AffiliateUpdPwd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BannerSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BannerSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BannerSelType] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BannerSelType] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BaseCurrenciesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_BaseCurrenciesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsDetailBySite] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsDetailBySite] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsSelByPage] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsSelByPage] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsSelBySite] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ClickStatisticsSelBySite] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_CommGroupSelDetail] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_CommGroupSelDetail] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_CountrySelAll] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_CountrySelAll] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_CurrencyListSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_CurrencyListSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_DomainAffClientSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_DomainAffClientSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_EarningSelDaily] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_EarningSelDaily] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_EmailHistoryIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_EmailHistoryIns] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GetAllAffSystemSettings] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GetAllAffSystemSettings] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GetDefaultProductCommission] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_GetDefaultProductCommission] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_HotNewsDetail_New] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_HotNewsDetail_New] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_HotNewsSel_New] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_HotNewsSel_New] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_LanguageSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_LanguageSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Logout] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_Logout] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_OnUserSelNetSessionID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_OnUserSelNetSessionID] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequestIns] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequestSelInfoByAff] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequestSelInfoByAff] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PaymentRequestUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PlayerPayoutInfoSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PlayerPayoutInfoSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PlayersCurrenciesSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_PlayersCurrenciesSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ProductSelByAffID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_ProductSelByAffID] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_RecheckIn] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_RecheckIn] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_StatisticsSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_StatisticsSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SystemSettingsSelByName] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SystemSettingsSelByName] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SystemSettingsSelByType] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_SystemSettingsSelByType] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_TextSel] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_User_TextSel] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Link_AffiliateInsClickStatistics] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_Link_AffiliateInsClickStatistics] TO [bodbDownlineNetView] AS [dbo]
GO