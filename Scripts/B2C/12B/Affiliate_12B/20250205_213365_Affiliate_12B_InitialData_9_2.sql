/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250205@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Initial LandingPage [RedmineID: #212201]
*/

USE Affiliate_12B
GO

TRUNCATE TABLE LandingPage

INSERT INTO dbo.LandingPage(PageName, PageCode, IsDeleted)
SELECT t.PageName, t.PageCode, 0  AS IsDeleted
FROM (
		VALUES (N'Fishing'	  , N'fishing')
			  ,(N'Games'	  , N'game')
			  ,(N'Join'		  , N'join')
			  ,(N'Home'		  , N'home')
			  ,(N'Sports'	  , N'sports')
			  ,(N'Promotion'  , N'promotion')
			  ,(N'Live-Casino', N'live-casino')
			  ,(N'Slots'	  , N'slots')
			  ,(N'Number Game', N'numberGame')
			  ,(N'Keno'		  , N'keno')
			  ,(N'Lottery'	  , N'lottery')
			  ,(N'E-Sports'	  , N'eSport')
) AS t(PageName, PageCode)
	LEFT JOIN dbo.LandingPage l WITH (NOLOCK) ON l.PageName = t.PageName AND l.PageCode = t.PageCode
WHERE l.PageName IS NULL
   OR l.PageCode IS NULL