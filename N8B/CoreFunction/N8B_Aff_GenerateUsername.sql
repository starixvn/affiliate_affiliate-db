/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_GenerateUsername]
	@PrefixName NVARCHAR(50),
	@UserName	NVARCHAR(50) OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: User site - Sign up - Generate username

	Revisions:
		- 20180601@Percy: Initialize function [Redmine: #87923]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @PrefixName = ISNULL(@PrefixName, '')

	DECLARE @Last_Id BIGINT, @Last_SubfixName BIGINT, @New_Id BIGINT, @New_SubfixName BIGINT, @Distance INT

	SELECT  TOP 1 @Last_Id = Id, @Last_SubfixName = SubfixName FROM dbo.Username_AutoIncrement WITH (NOLOCK)
	WHERE PrefixName = @PrefixName AND SubfixName IS NOT NULL
	ORDER BY Id DESC

	IF @Last_Id IS NULL
	BEGIN
		SELECT @Last_Id = 0, @Last_SubfixName = 1
	END

	INSERT INTO dbo.Username_AutoIncrement (PrefixName)
	VALUES (@PrefixName)

	SELECT @New_Id = SCOPE_IDENTITY()

	SELECT @Distance = COUNT(1) FROM dbo.Username_AutoIncrement WITH (NOLOCK)
	WHERE PrefixName = @PrefixName AND Id BETWEEN @Last_Id AND @New_Id

	SELECT @New_SubfixName = @Last_SubfixName + @Distance - 1

	DECLARE @Old_SubfixName INT
	SELECT  @Old_SubfixName = MAX(CONVERT(INT, RIGHT(username, LEN(username) - LEN(@PrefixName))))
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE username LIKE @PrefixName + '%'

	SELECT  @Old_SubfixName = @Old_SubfixName + 1

	SELECT  @New_SubfixName = CASE WHEN @New_SubfixName < @Old_SubfixName THEN @Old_SubfixName ELSE @New_SubfixName END

	UPDATE dbo.Username_AutoIncrement WITH (ROWLOCK, UPDLOCK)
	SET SubfixName = @New_SubfixName
	WHERE Id = @New_Id

	IF @New_SubfixName < 100 -- length < 3: 001, 002, ..., 099
		SELECT @UserName =  @PrefixName + RIGHT('00' + CONVERT(VARCHAR(10), @New_SubfixName), 3)
	ELSE
		SELECT @UserName =  @PrefixName + CONVERT(VARCHAR(10), @New_SubfixName)
END
GO