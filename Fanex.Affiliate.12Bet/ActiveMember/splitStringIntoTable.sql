IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].splitStringIntoTable') AND type in (N'P', N'PC'))
drop procedure splitStringIntoTable

go
create  FUNCTION splitStringIntoTable (@list nvarchar(MAX))  
   RETURNS @tbl TABLE (strVal nvarchar(30) NOT NULL) AS  

/*    
Created: 20120724@Thai  
Task : Split a string by delimiter ',' then insert texts into a table 
DB: 10.18.200.206.bodb02
Ex: 
	Input: zhang,thai,bill
	Output : zhang
			 thai
			 bill
    
Revisions:    
 - 20120724@[Reviewer]: [Description of revision]     
    
Param's Explanation:    
• @list: the string to be splitted
• @tbl:  the table
*/  

BEGIN  
   DECLARE @pos        int,  
           @nextpos    int,  
           @valuelen   int  
  
   SELECT @pos = 0, @nextpos = 1  
  
   WHILE @nextpos > 0  
   BEGIN  
      SELECT @nextpos = charindex(',', @list, @pos + 1)  
      SELECT @valuelen = CASE WHEN @nextpos > 0  
                              THEN @nextpos  
                              ELSE len(@list) + 1  
                         END - @pos - 1  
      INSERT @tbl (strVal)  
         VALUES (convert(nvarchar(30), ltrim(rtrim(substring(@list, @pos + 1, @valuelen)))))
      SELECT @pos = @nextpos  
   END  
   RETURN  
END