ALTER PROCEDURE [dbo].[AffAdmin_GetMemberDetail]
	@UserName VARCHAR(30)
AS
/*  Author:20140827@Bobby.Nguyen
	Task: Get member detail    
	DB:	DBAFFATHENA000\Affiliate_Athena000 
	Revisions:           
		- 20140909@Bobby: Create SP
                
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
					INNER JOIN AdminUser ad WITH(NOLOCK)
					ON r.RemovedBy = ad.CustID
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
		CROSS APPLY (
			SELECT TOP 1
				c.Country
			FROM [dbo].[IP2NationCountries] c WITH(NOLOCK)
			WHERE c.[Iso_Code_2] = m.CountryID 
				OR c.[Iso_Code_3] = m.CountryID

			UNION 
			SELECT Country
			FROM (
				SELECT '-' AS Country
			) t
			WHERE m.CountryID IS NULL
		) ct
	WHERE m.UserName = @UserName
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_GetMemberDetail] TO [bodbAdminNet]
GO
