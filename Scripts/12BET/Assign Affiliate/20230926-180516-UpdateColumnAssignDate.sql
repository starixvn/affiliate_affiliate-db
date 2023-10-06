/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20230926@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Update column AssignDate by CreatedDate [RedmineID: #180516]
*/

DROP TABLE IF EXISTS #TmpMemberInfoUpd

DROP TABLE IF EXISTS #TmpMemberInfoUpdTOP2000

CREATE TABLE #TmpMemberInfoUpd (IBCCustID INT PRIMARY KEY, UserName VARCHAR(30), CreatedDate DATETIME)

CREATE TABLE #TmpMemberInfoUpdTOP2000 (IBCCustID INT PRIMARY KEY, UserName VARCHAR(30), CreatedDate DATETIME)

INSERT INTO #TmpMemberInfoUpd(IBCCustID, UserName, CreatedDate)
SELECT IBCCustID, UserName, CreatedDate
FROM [dbo].[vw_MemberInfo] WITH (NOLOCK)



WHILE 1 = 1
BEGIN
	DELETE TOP(2000) FROM #TmpMemberInfoUpd
	OUTPUT DELETED.IBCCustID, DELETED.UserName, DELETED.CreatedDate
	INTO #TmpMemberInfoUpdTOP2000(IBCCustID, UserName, CreatedDate)
	
	UPDATE mi WITH(ROWLOCK, UPDLOCK)
	SET mi.AssignDate = u.CreatedDate
	FROM dbo.MemberInfo mi
		INNER JOIN #TmpMemberInfoUpdTOP2000 u ON mi.IBCCustID = u.IBCCustID AND mi.UserName = u.UserName
	
	IF @@ROWCOUNT < 2000
		BREAK
		
	DELETE FROM #TmpMemberInfoUpdTOP2000
	
	WAITFOR DELAY '00:00:00.280'
END

DROP TABLE #TmpMemberInfoUpdTOP2000
DROP TABLE #TmpMemberInfoUpd
GO
