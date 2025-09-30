CREATE function [dbo].[Aff_ToString] (  
 @Value sql_variant  
)  
RETURNS nvarchar(max)  
AS  
/*  
    DB : DB02.bodb02, DB03.on_user,DB03.bodb02,DB052.Affiliate_ZZun  
 Task : Convert a value to string for all data types  
 Author : Peter@20090909  
   
*/  
BEGIN      
 return cast(isnull(@Value,'') as nvarchar(max))  
END  