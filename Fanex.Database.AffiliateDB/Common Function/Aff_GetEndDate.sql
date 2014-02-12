  
ALTER function [dbo].[Aff_GetEndDate] (  
@Date datetime)  
RETURNS datetime  
AS  
  
BEGIN    
 RETURN dateadd(ms, -3, dateadd(d, datediff(d, 0, @Date) + 1, 0))   
END