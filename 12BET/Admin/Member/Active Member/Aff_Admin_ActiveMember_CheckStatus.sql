/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_ActiveMember_CheckStatus]
	@Username	NVARCHAR(MAX) = ''
	,@ErrCode	INT = 0 OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Member - Active Member - Check Status

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Username = LTRIM(RTRIM(ISNULL(@Username, '')))
	SELECT @ErrCode = 0, @ErrMsg = ''

	IF @Username = ''
		RETURN

	DECLARE @tblUsernames TABLE (Username NVARCHAR(MAX))
	INSERT INTO @tblUsernames (Username)
	SELECT DISTINCT LTRIM(RTRIM(val)) FROM dbo.strSplit(@Username, ',')

	IF @@ROWCOUNT > 100
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'The function can only check up to 100 accounts per request.'

		-- return empty tables
			-- Activated members
		SELECT NULL AS Username, NULL AS IBCUsername, NULL AS Firstname, NULL AS Lastname, NULL AS IBCCustId, NULL AS CreatedDate
		WHERE 1 = 0
			
			-- Inactivated members
		SELECT NULL AS Username, NULL AS Firstname, NULL AS Lastname
		WHERE 1 = 0
		
		RETURN
	END

	-- Reset param @Username due to LTRIM/RTRIM
	SELECT @Username = NULL
	SELECT @Username = COALESCE(@Username + ',', '') + Username FROM @tblUsernames

	-- Activated members
	DECLARE @ActivedMembers TABLE (Username NVARCHAR(50), IBCUsername NVARCHAR(50), Firstname NVARCHAR(50), Lastname NVARCHAR(50), IBCCustId INT, CreatedDate DATETIME)
	INSERT INTO @ActivedMembers (Username, IBCUsername, Firstname, Lastname, IBCCustId, CreatedDate)
	SELECT u.Username, c.username AS IBCUsername, c.Firstname, c.Lastname, c.custid AS IBCCustId, c.creatdate AS CreatedDate
	FROM bodb02.dbo.Customer c WITH (NOLOCK)
		CROSS APPLY (SELECT u.Username FROM @tblUsernames u WHERE c.username2 = CONVERT(VARCHAR(50), '12BET$' + u.Username)) u

	-- Inactivated members
	DECLARE @InactivedMembers TABLE (Username NVARCHAR(50), Firstname NVARCHAR(50), Lastname NVARCHAR(50))
	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql = 'SELECT Username, Firstname, Lastname
					FROM OPENQUERY(DBDEPOSIT, ''SELECT Username, Firstname, Lastname
												FROM Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
												WHERE username IN (''''' + REPLACE(@Username, ',', ''''',''''') + ''''')
													AND accstatus NOT IN (2, 9)
												''
									)'
	BEGIN TRY
		INSERT INTO @InactivedMembers (Username, Firstname, Lastname)
		EXEC (@sql)
	END TRY
	BEGIN CATCH
	END CATCH
	
	-- Invalid members
	DECLARE @InvalidUsername NVARCHAR(MAX)
	SELECT  @InvalidUsername = COALESCE(@InvalidUsername + ',', '') + u.Username
	FROM @tblUsernames u
		LEFT JOIN @ActivedMembers am ON u.Username = am.Username
		LEFT JOIN @InactivedMembers im ON u.Username = im.Username
	WHERE am.Username IS NULL AND im.Username IS NULL

	IF ISNULL(@InvalidUsername, '') <> ''
		SELECT @ErrCode = 102, @ErrMsg = 'These members do not exist: ' + @InvalidUsername

	-- Return result
		-- Activated members
	SELECT Username, IBCUsername, Firstname, Lastname, IBCCustId, CreatedDate
	FROM @ActivedMembers
			
		-- Inactivated members
	SELECT Username, Firstname, Lastname
	FROM @InactivedMembers
END
GO