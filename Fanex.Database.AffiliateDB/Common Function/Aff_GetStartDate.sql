CREATE function [dbo].[Aff_GetStartDate] (  
@Date datetime)  
RETURNS datetime  
AS  
BEGIN    
 RETURN dateadd(d, datediff(d, 0, @Date), 0)   
END  