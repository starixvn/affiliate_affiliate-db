/****** Object:  Stored Procedure dbo.Aff_AffiliateInsClickStatistics    Script Date: 7/29/2013 1:41:16 AM ******/
ALTER PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics]    
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
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateInsClickStatistics] TO [vnteam] AS [dbo]