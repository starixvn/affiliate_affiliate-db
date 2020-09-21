/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_SplitIndex]
(
	@string		NVARCHAR(4000),
	@splitter	CHAR,
	@index		INT
)  
RETURNS NVARCHAR(4000)
AS

/*
	DB: DBAFFN8B-Affiliate_N8B

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Add more server: DBCUST.bodb_Licensee [RedmineID: #103658]
		- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
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