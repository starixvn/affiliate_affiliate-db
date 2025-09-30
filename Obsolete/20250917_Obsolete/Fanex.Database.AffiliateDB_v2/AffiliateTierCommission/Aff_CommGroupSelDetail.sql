USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[Aff_CommGroupSelDetail]   
	@GroupId INT = NULL,    
	@AffID INT = NULL  
AS

/*  
	Created: 20090719@DungTong
	Task: Get Group Setting for Editing an existing Group
	DB: DBAFF.Affiliate_Athena000
	Original:
  
	Revisions:
*/

BEGIN
	SET NOCOUNT ON  
  
	if @AffID is not null   
	begin  
		select @GroupId = groupid from affinfo with(nolock) where affid = @AffID  
	end
	
	declare @IsCurrencyEditable bit = 0
	if exists (select top 1 1 from dbo.AffCommission with(nolock) where GroupID = @GroupID)
	begin
		select @IsCurrencyEditable = 1
	end

	if @IsCurrencyEditable = 0
	begin
		if exists (select top 1 1 from dbo.AffInfo with(nolock) where GroupID = @GroupID)
		begin
			select @IsCurrencyEditable = 1
		end
	end
  
	select
		GroupID, GroupName, g.CreatedDate, g.Creator, Description, e.ExchangeID, e.Code as Currency, QualifiedAmount, @IsCurrencyEditable as IsCurrencyEditable  
	from CommGroup g (nolock)  
		inner join dbo.Exchange e on g.Currency = e.ExchangeID  
	where GroupID=@GroupID  
  
	select g.GroupID,g.ProductID,g.TierID,g.MinAmount,g.MaxAmount,g.MinQM,g.MaxQM,g.Commission  
	from GroupSetting g (nolock)       
	where g.GroupID=@GroupID   
  
	select DeductionID, DeductedPercentage  
	from DeductionSetting (nolock)  
	where GroupID=@GroupID  
  
	select ProductID, ProductName  
	from Product (nolock)
   
	select DTypeID, ProductID, DTypeName, DTypeDesc, DeductedPercentage   
	from DeductionType (nolock)
  
	select SValue as SupportedBaseCurrencies
	from SystemSettings (nolock)
	where Type='meta' and SName='SupportedBaseCurrencies'  

END
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSelDetail] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSelDetail] TO [vnteam]
GO