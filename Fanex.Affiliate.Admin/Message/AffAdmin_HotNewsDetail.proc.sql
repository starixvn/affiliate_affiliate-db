CREATE PROCEDURE [dbo].[AffAdmin_HotNewsDetail]
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

DECLARE @Names VARCHAR(8000)  
SET @Names =  stuff(
    (
    select cast(',' as varchar(max)) + '[' + l1.LanguageID +']'
    from Language l1 (nolock)   
    for xml path('')
    ), 1, 1, '')  

DECLARE @Query VARCHAR(8000)   
SET @Query = '
select n.[creator]
	  ,[posteddate]
	  ,[msgid]
	  ,[important]
	  ,c.username as creatorname
	  ,temp.*
	  FROM News n with (nolock)
	  LEFT JOIN AdminUser c WITH (NOLOCK) ON c.custid=n.[creator]
	  LEFT JOIN (
			select * from (select ResourceKey,ResourceValue,LanguageCode from RefResources r (nolock) 
			WHERE r.ResourceKey = ''' + @ID +''') a
			PIVOT
			(MIN(ResourceValue) FOR LanguageCode IN (' + @Names+ ')) pvt
	 ) temp ON temp.ResourceKey = ''' + @ID + '''
	 WHERE n.msgid = ' + convert(varchar(10),@MsgID)

exec (@Query)

GO
GRANT EXECUTE ON [dbo].[AffAdmin_HotNewsDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_HotNewsDetail] TO [vnteam]