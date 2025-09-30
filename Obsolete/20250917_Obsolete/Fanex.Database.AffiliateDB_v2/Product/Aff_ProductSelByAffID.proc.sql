CREATE PROCEDURE [dbo].[Aff_ProductSelByAffID]
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

Grant execute on [dbo].[Aff_ProductSelByAffID] to [bodbAdminNet]

GO

Grant execute on [dbo].[Aff_ProductSelByAffID] to [bodbDownlineNet]

GO

Grant execute on [dbo].[Aff_ProductSelByAffID] to [bodbDownlineNetView]

GO

Grant View definition on [dbo].[Aff_ProductSelByAffID] to [vnteam]