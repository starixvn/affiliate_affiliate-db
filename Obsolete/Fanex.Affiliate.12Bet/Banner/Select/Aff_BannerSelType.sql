ALTER PROCEDURE [dbo].[Aff_BannerSelType]
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
GRANT EXECUTE ON [dbo].[Aff_BannerSelType] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelType] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_BannerSelType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_BannerSelType] TO [VNTeam]

