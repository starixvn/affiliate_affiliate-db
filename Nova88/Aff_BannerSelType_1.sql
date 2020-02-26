/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_BannerSelType_1]
	@TypeName varchar(50)=NULL
AS


/*
Created: unknow
Task :  
DB: DBAFFN8G-Affiliate_N8G

Revisions:    
	- 20200220@Percy: Initialize SP for DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
			  
*/

declare @BannerTypes table(Type varchar(50),value nvarchar(100), DisplayOrder int IDENTITY(1,1))
insert into @BannerTypes(Type,value)
select 'Size' as Type,Value
from (
       select top(1000) value,
      (select top(1) val from dbo.Aff_f_StringSplit(value,'x') where Id=1) width,
      (select top(1) val from dbo.Aff_f_StringSplit(value,'x') where Id=2) height,
       len((select top(1) val from dbo.Aff_f_StringSplit(value,'x') where Id=1)) as lw,
       len((select top(1) val from dbo.Aff_f_StringSplit(value,'x') where Id=2)) as lh
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