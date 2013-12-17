ALTER PROCEDURE [dbo].[Aff_AffiliateInsClickStatistics_New]  
	@AffiliateID int,  
	@AffDomain nvarchar(256) = '',--Url is showed in affiliate site
	@PageCode varchar(50)='sportsbook',   
	@LanguageCode varchar(6)='en',  
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
*/  

SET NOCOUNT ON  

Declare @AffUsername nvarchar(30), @PreferredLanguage varchar(11), @Default12Betdomain nvarchar(100), @IsCasino bit

select @Default12Betdomain = '12ying.com'--If redirect page is null => redirect to this default domain

select @AffUsername = ai.Username, @PreferredLanguage = PreferredLanguage
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
Select @RedirectPage = (Select top 1 CValue  --Get link for some special affiliate
						From CommonSettings (nolock)  					
						Where [Type]=@PageCode
							and CName = @AffUsername)

if(@RedirectPage is null) 
begin  
	Declare @AffDomainId int, @AffDomainName nvarchar(255)

	Select @AffDomainId = DomainID, @AffDomainName = DomainName
	From AffDomain nolock 
	where @AffDomain like '%' + DomainName + '%'

	Select @RedirectPage = b.DomainName
	from AffDomainControl a with (nolock)
		inner join [12BetDomain] b with (nolock) on a.[12BetDomainID] = b.DomainID
	where a.MarketId = @PreferredLanguage and a.AffDomainId = @AffDomainId and [status] = 1

	--Replace Aff Domain by 12bet domain to redirect to 12bet site
	Select @RedirectPage = 'http://www.' + isnull(@RedirectPage, @Default12Betdomain) + '/' + cast(@AffiliateID as varchar(15)) + '/' + @PageCode + '/' + @LanguageCode + '/{clickid}/index.aspx'
End
Else
Begin --This aff is special aff and pagecode = '12betcasino'
	select @LanguageCode = (case when @LanguageCode = 'ch' then 'cs' 
						when @LanguageCode = 'eneuro' or @LanguageCode = 'es' then 'en'
						when @LanguageCode = 'vn' then 'vi'
						else @LanguageCode
						end)	
	select @RedirectPage = replace(@RedirectPage, '{custid}', @AffiliateID)
	select @RedirectPage = replace(@RedirectPage, '{target}', @pagecode)
	select @RedirectPage = replace(@RedirectPage, '{lang}', @LanguageCode)
	select @RedirectPage = replace(@RedirectPage, '{/TrackingCode}', '')
End


Declare @CountryCode varchar(5), @IPNum bigint
select @IPNum = [dbo].[Aff_IPConvertToNumber](@IP)  
Set @CountryCode=(Select top(1) Code3 from IPv4Addresses (nolock) where @IPNum between [From] and [To])  



INSERT INTO [ClickStatistics1]  
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
		   ,[Status])  
VALUES  
           (@AffiliateID 
           ,getdate() 
           ,@IP  
           ,CONVERT(varchar(10), CURRENT_TIMESTAMP, 120)  
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
           ,(case when @LanguageCode = 'vi' then 'vn' else @LanguageCode end)--Only store vn for vietnamese
           ,@PageCode
           ,@RedirectPage--if not Casino aff => redirect to main domain
		   ,0
           )     

select @ClickID = SCOPE_IDENTITY()

select @RedirectPage = replace(@RedirectPage, '{clickid}', @ClickID)

update [ClickStatistics1] with (rowlock, updlock)
set [RedirectURL] = @RedirectPage
where clickId = @ClickID

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics_New] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateInsClickStatistics_New] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateInsClickStatistics_New] TO [vnteam]