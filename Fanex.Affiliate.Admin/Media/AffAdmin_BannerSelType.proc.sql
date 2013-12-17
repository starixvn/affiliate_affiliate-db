CREATE PROCEDURE [dbo].[AffAdmin_BannerSelType]
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
GRANT EXECUTE ON [dbo].[AffAdmin_BannerSelType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_BannerSelType] TO [vnteam]