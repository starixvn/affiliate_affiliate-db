CREATE Procedure [dbo].[AffAdmin_AffiliateSelDBTime]  
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
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateSelDBTime] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateSelDBTime] TO [vnteam]