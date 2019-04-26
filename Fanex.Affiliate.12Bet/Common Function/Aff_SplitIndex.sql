/*<info serverAlias="DBCUST-bodb_Licensee,DBAFF-Affliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER FUNCTION [dbo].[Aff_SplitIndex]
(
	@string		NVARCHAR(4000),
	@splitter	CHAR,
	@index		INT
)  
RETURNS NVARCHAR(4000)
AS

/*
	DB: DBCUST.bodb_Licensee, DBAFF-Affliate_AthenaXXX

	Revisions:
		- 20101214@Peter : Move this SP to DB DB052.Affiliate_MYM
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20190424@Percy: Add more server: DBCUST.bodb_Licensee [RedmineID: #103658]
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