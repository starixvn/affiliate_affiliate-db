/****** Object:  UserDefinedFunction [dbo].[Aff_SplitIndex]    Script Date: 12/15/2010 11:41:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[Aff_SplitIndex]
 (@string NVARCHAR(4000), @splitter CHAR, @index INT)  
RETURNS NVARCHAR(4000) AS  
BEGIN 

	IF SUBSTRING(@string, len(@string), 1) <> @splitter
		SET @string = @string + @splitter

	DECLARE @word NVARCHAR(4000) SET @word = ''
	DECLARE @start INT SET @start = 1
	DECLARE @i INT SET @i = 1
	DECLARE @charindex INT SET @charindex = CHARINDEX(@splitter, @string, @start)

	WHILE (@charindex <> 0)
	BEGIN
		  SET @word= SUBSTRING(@string, @start, @charindex - @start)
		  SET @start= @charindex + 1
		  SET @charindex= CHARINDEX(@splitter, @string, @start)
		  IF @i = @index RETURN @word
		  SET @i=@i+1
	END

	Return @string

END

