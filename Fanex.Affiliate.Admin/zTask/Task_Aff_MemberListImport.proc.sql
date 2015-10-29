ALTER PROCEDURE [dbo].[Task_Aff_MemberListImport]  		
	@ImportDate SMALLDATETIME  --import date
AS   
/*
	Created: 20140108@Bobby.Nguyen
	Task : Get list of member for task import member daily
	DB:  Affiliate DB
	Revisions:
		201501022@Bobby.Nguyen: Add more product list
		
	Param's explanation:
		@ImportDate: date of import member daily
		
*/
BEGIN

	SET NOCOUNT ON;

	SELECT mi.username  
	FROM dbo.MemberInfo mi WITH(NOLOCK)
		LEFT JOIN dbo.MemberRemoval mr WITH(NOLOCK) 
		ON mi.username = mr.username
	WHERE mi.AffAffectedDate <= @ImportDate -- from existing date at AFF system
		AND (
			mi.CreatedDate IS NOT NULL 
			AND mi.CreatedDate <= @ImportDate
		) --just deposit member and first deposit date
		AND (
			mi.IsRemoved = 0 
			OR (mi.IsRemoved = 1 AND mr.RemovedDate > @ImportDate)
		) -- before removal date
	
	-- List supported product
	SELECT [API_ProductID] AS ProductId
		, ProductName
	FROM dbo.Product WITH(NOLOCK)
	WHERE IsEnabled = 1
	
	RETURN 0
END
   