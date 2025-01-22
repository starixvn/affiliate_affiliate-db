/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_SplitIndex]
(
	@string		NVARCHAR(4000),
	@splitter	CHAR,
	@index		INT
)  
RETURNS NVARCHAR(4000)
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

*/

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

	RETURN @string
END
GO