/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_RegisteredMember_Sel]
	@AffName NVARCHAR(30) =''
	,@Username	NVARCHAR(30) =''
	,@PageSize		INT = 50
	,@PageIndex		INT = 1
	,@NRows			INT = 0 OUTPUT
AS

/*  
	Created: 20210528@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Member - registered member

	Revisions:
		- 20210528@Malcolm: Initialize SP [RedmineID: #149210]
		
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Username = LTRIM(RTRIM(ISNULL(@Username, ''))), @AffName = LTRIM(RTRIM(ISNULL(@AffName, '')))

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
			,@RowEnd	= @RowStart + @PageSize - 1

	-- Inactivated members
	DECLARE @InactivedMembers TABLE (Username NVARCHAR(50), Firstname NVARCHAR(50), Lastname NVARCHAR(50), CreatedDate DATETIME, AffId INT)

	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql = 'SELECT Username, Firstname, Lastname, creatdate, AffiliateID
					FROM OPENQUERY(DBDEPOSIT, ''SELECT Username, Firstname, Lastname, creatdate, AffiliateID
												FROM Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
												WHERE actstatus NOT IN (2, 9)
												''
									)'
	BEGIN TRY
		INSERT INTO @InactivedMembers (Username, Firstname, Lastname, CreatedDate, AffId)
		EXEC (@sql)
	END TRY
	BEGIN CATCH
	END CATCH

	
	SELECT @NRows = COUNT(1)
	FROM @InactivedMembers m
		LEFT JOIN dbo.AffInfo ai WITH(NOLOCK) ON m.AffId = ai.AffID
	WHERE (m.Username LIKE '%' + @Username + '%' OR m.Username = '')
		AND (ai.UserName LIKE '%' + @AffName + '%' OR ai.UserName = '')
	
	SELECT r.Username, r.Firstname, r.Lastname, r.CreatedDate, r.AffName
	FROM
	(
		SELECT m.Username, m.Firstname, m.Lastname, m.CreatedDate, ai.UserName AS AffName, ROW_NUMBER() OVER(ORDER BY m.CreatedDate DESC, m.Username ASC) AS Rn
		FROM @InactivedMembers m
			LEFT JOIN dbo.AffInfo ai WITH(NOLOCK) ON m.AffId = ai.AffID
		WHERE (m.Username LIKE '%' + @Username + '%' OR m.Username = '')
			AND (ai.UserName LIKE '%' + @AffName + '%' OR ai.UserName = '')
	) r
	WHERE r.Rn >= @RowStart AND r.Rn <= @RowEnd
END
GO