ALTER function [dbo].[Aff_GetLogType] (  
@LogName varchar(2048))  
RETURNS int  
AS  
/*  
 Task : Get Log Type  
 Author : Peter@20090909  
   
*/  
BEGIN   
 DECLARE @LogType int   
 SELECT @LogType=TypeID from LogType (nolock)  
    where TypeName=@LogName  
 RETURN @LogType  
END  