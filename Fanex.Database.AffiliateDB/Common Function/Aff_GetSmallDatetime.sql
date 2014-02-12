CREATE function [dbo].[Aff_GetSmallDatetime] (  
@Date datetime)  
RETURNS datetime  
AS  
BEGIN    
 RETURN cast (convert(varchar(10),@Date,120) as smalldatetime)  
END  