  
ALTER function [dbo].[Aff_GetProductID] (  
@ProductName varchar(2048))  
RETURNS smallint  
AS  
/*  
 Task : Get Product ID  
 Author : Peter@20090909  
   
*/  
BEGIN   
 DECLARE @ProductID smallint   
 SELECT @ProductID=ProductID from Product with (nolock)  
    where ProductName=@ProductName  
 RETURN @ProductID  
END  
  

