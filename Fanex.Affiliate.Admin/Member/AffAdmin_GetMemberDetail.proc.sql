ALTER PROCEDURE [dbo].[AffAdmin_GetMemberDetail]
	@LicenseeID INT,
	@UserName VARCHAR(30)
AS
/*  Author:20140827@Bobby.Nguyen
	Task: Get member detail    
	DB:	DBAFFATHENA000\Affiliate_Athena000 
	Revisions:           
		- 20140909@Bobby: Create SP
		- 20141711@Bobby: Update to get country info
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site                
	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @NAVal CHAR(5)
	
	SELECT @UserName 	= LTRIM(RTRIM(@UserName))
		, @NAVal 		= '-'
	
	SELECT TOP 1
		m.UserName
		,ai.UserName 					AS AffUserName
		,m.CreatedDate
		,m.RegisteredDate
		,ex.Code 						AS Currency
		,ISNULL(m.FirstName, @NAVal) 	AS FirstName
		,ISNULL(m.LastName, @NAVal) 	AS LastName
		,ISNULL(m.Email, @NAVal) 		AS Email
		,ISNULL(m.Phone, @NAVal) 		AS Phone
		,ISNULL(m.Address, @NAVal) 		AS Address
		,ISNULL(ct.Country, @NAVal) 	AS Country
		,m.AffAffectedDate
		,m.IsRemoved
		,CASE WHEN m.IsRemoved = 1 THEN mr.RemovedDate 
				ELSE NULL 
			END 						AS RemovedDate
		,CASE WHEN m.IsRemoved = 1 THEN mr.RemovedBy 
				ELSE NULL 
			END 						AS RemovedBy
	FROM dbo.MemberInfo m WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK)
		ON m.AffID = ai.AffID
		INNER JOIN dbo.Exchange ex WITH(NOLOCK)
		ON m.Currency = ex.ExchangeID
		CROSS APPLY (
			SELECT MAX(r.RemovedDate) AS RemovedDate
					, ad.UserName AS RemovedBy
				FROM dbo.MemberRemoval r WITH(NOLOCK)
					INNER JOIN dbo.AffAdmin_f_AdminUserInfo_Select('',@LicenseeID) ad
					ON r.RemovedBy = ad.UserID
				WHERE r.UserName = m.UserName
				GROUP BY ad.UserName
				
				UNION
				SELECT RemovedDate
					, '-' AS RemovedBy
				FROM (
					SELECT CAST(0 AS SMALLDATETIME) AS RemovedDate
				) t
				WHERE m.IsRemoved = 0
		) AS mr
		LEFT JOIN [dbo].[IP2NationCountries] ct WITH(NOLOCK)
			ON m.CountryID = ct.Code OR m.CountryID = ct.Iso_Code_2
			
	WHERE m.UserName = @UserName
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetMemberDetail] TO [bodbAdminNet] AS [dbo]