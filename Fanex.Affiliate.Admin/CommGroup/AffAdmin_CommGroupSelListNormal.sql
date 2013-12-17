-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_CommGroupSelListNormal]		
	@UserID int = null,
	@Currency varchar(255)=null    
AS

/*
Created: 20130903@Joseph
Task : Get Commission Group List (groupid<1000) for dropdown list
DB: DB052.Affiliate_MYM
Original:Aff_CommGroupSelListNormal

Params Explaination:
   if AffID<> -1: need to check whether this private group is already assigned to this Aff
   output : Change AffID=0 if existed
Revisions:	
	- Get NoCommission group (for all currency)
*/
SET NOCOUNT ON

if @Currency = 'All'
begin 
	SELECT AttributeID as CurrencyID INTO #tmpCurrency
	FROM dbo.Aff_f_GetCurrencybyUser (@UserID,1)
	
	Select GroupId,	
		   GroupName
	From CommGroup with (nolock)
	Where GroupName = 'NoCommission'

	Union ALL

	select 
		cg.GroupId,	
		cg.GroupName    
	from CommGroup cg with (nolock)     
		inner join #tmpCurrency tmp  ON cg.Currency=tmp.CurrencyID
	where cg.IsDeleted=0 
		and @Currency is not null 
		and (@Currency ='All' or cg.currency=coalesce(@Currency,0))

	
end
else
begin
	declare @TblCurrency table (id int primary key, rank int, val nvarchar( 6) )

	insert into @TblCurrency 
	select a.id, a.rank, a.val
	from [dbo].[strSplit] ( @Currency, ',' ) a
		inner JOIN dbo.Aff_f_GetCurrencybyUser (@UserID,1) b on a.val = b.AttributeID 

	Select GroupId,	
		   GroupName
	From CommGroup with (nolock)
	Where GroupName = 'NoCommission'

	Union ALL

	select 
		cg.GroupId,	
		cg.GroupName    
	from CommGroup cg with (nolock)     
		inner join @TblCurrency tmp on cg.Currency = tmp.val
	where cg.IsDeleted=0
end


GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelListNormal] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupSelListNormal] TO [vnteam]