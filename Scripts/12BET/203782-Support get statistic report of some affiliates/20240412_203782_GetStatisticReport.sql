/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20240412@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Support get statistic report of some affiliates [RedmineID: #203782]
*/

DECLARE @AffiliateName TABLE (Username NVARCHAR(30), Id INT IDENTITY(1,1))

DECLARE @Id INT = 1, @Username NVARCHAR(30) = ''

INSERT INTO @AffiliateName(Username)
VALUES
('12BETAFF12620')
,('12BETAFF12716')
,('12BETAFF14326')
,('12BETAFF14351')
,('12BETAFF14327')
,('12BETAFF14477')
,('12BETAFF14478')
,('12BETAFF14928')
,('12BETAFF13902')

WHILE 1=1
BEGIN
	
	SELECT @Username = Username
	FROM @AffiliateName
	WHERE Id = @Id

	IF @@ROWCOUNT = 0
		RETURN

	EXEC Aff_Admin_AffiliateReport_Detail_Sel_Eddie_xtest @Username=@Username,@FromDate='2019-01-01 00:00:00',@ToDate='2024-03-31 00:00:00',@SortType=1,@SortDirectionType=0, @IsExportExcel = 1

	SET @Id += 1
END

SELECT MonthDate, Affiliate, Signup, FDM, Winlost, Earning, Turnover, TotalClick 
FROM StorageTable WITH (NOLOCK)
ORDER BY MonthDate, Affiliate



