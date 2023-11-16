/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_RegisteredMember_Sel]
	@AffName		NVARCHAR(50) =''
	,@Username		NVARCHAR(50) =''
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
		- 20231116@Eddie: Enhance performance [RedmineID: #196930]
		
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Username = LTRIM(RTRIM(ISNULL(@Username, ''))), @AffName = LTRIM(RTRIM(ISNULL(@AffName, '')))

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowStart	= @PageSize * (@PageIndex - 1) + 1
			,@RowEnd	= @RowStart + @PageSize - 1

	-- Inactivated members
	CREATE TABLE #InactivedMembers(Username NVARCHAR(50), Firstname NVARCHAR(50), Lastname NVARCHAR(50), CreatedDate DATETIME, AffId INT, Currency TINYINT)

	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql = 'SELECT Username, Firstname, Lastname, creatdate, AffiliateID, currency
					FROM OPENQUERY(DBDEPOSIT, ''SELECT Username, Firstname, Lastname, creatdate, AffiliateID, currency
											   FROM Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
											   WHERE actstatus NOT IN (2, 9) AND (Username LIKE '''''+ @Username +''''' OR '''''+ @Username+''''' = '''''''')''
								   )'

	BEGIN TRY
		INSERT INTO #InactivedMembers (Username, Firstname, Lastname, CreatedDate, AffId,currency)
		EXEC (@sql)
	END TRY
	BEGIN CATCH
	END CATCH

	CREATE CLUSTERED INDEX CIX_AffId_Currency_CreatedDate_Username ON #InactivedMembers(AffId, Currency, CreatedDate DESC, Username ASC)
	
	SELECT @NRows = COUNT(1)
	FROM #InactivedMembers m
		LEFT JOIN dbo.AffInfo ai WITH(NOLOCK) ON m.AffId = ai.AffID
	WHERE ai.UserName LIKE '%' + @AffName + '%' OR @AffName = ''
	
	SELECT r.Username, r.Firstname, r.Lastname, r.CreatedDate, r.AffName, r.Currency
	FROM
	(
		SELECT m.Username, m.Firstname, m.Lastname, m.CreatedDate, ai.UserName AS AffName, e.Currency, ROW_NUMBER() OVER(ORDER BY m.CreatedDate DESC, m.Username ASC) AS Rn
		FROM #InactivedMembers m
			LEFT JOIN Exchange_Current e ON e.ExchangeID = m.Currency
			LEFT JOIN dbo.AffInfo ai WITH(NOLOCK) ON m.AffId = ai.AffID
		WHERE ai.UserName LIKE '%' + @AffName + '%' OR @AffName = ''
	) r
	WHERE r.Rn >= @RowStart AND r.Rn <= @RowEnd
	
	DROP TABLE #InactivedMembers
END
GO