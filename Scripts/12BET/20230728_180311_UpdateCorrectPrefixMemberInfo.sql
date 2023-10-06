/*<info serverAlias="DB052-Affiliate_12BET"></info>*/
/*
  Created:20230728@Bobby
  Task: 180311 - Correct prefix MemberInfo
  Remark: Run on DB052 only

*/
USE [Affiliate_12BET];
GO

DROP TABLE IF exists #tmpMemberUpd;

CREATE TABLE #tmpMemberUpd (IBCCustId INT PRIMARY KEY, username2 VARCHAR(30));

-- 3015 members
INSERT INTO #tmpMemberUpd(IBCCustId, username2)
SELECT mi.IBCCustId, c.username2
FROM [dbo].[vw_MemberInfo] mi WITH(NOLOCK)
INNER JOIN bodb02.dbo.vw_Customer c WITH(NOLOCK) ON c.username2 = '12Bet$' + mi.UserName and c.custid = mi.IBCCustID
WHERE mi.UserName not  like '12Bet$%';

-- Verify
--SELECT * FROM #tmpMemberUpd

--SELECT mi.IBCCustId, c.username2
--FROM [dbo].[vw_MemberInfo] mi WITH(NOLOCK)
--INNER JOIN bodb02.dbo.vw_Customer c WITH(NOLOCK) ON c.username2 = '12Bet$' + mi.UserName and c.custid = mi.IBCCustID
--left join #tmpMemberUpd u on u.IBCCustId = mi.IBCCustID
--WHERE mi.UserName not  like '12Bet$%' and u.IBCCustId is null;


IF EXISTS (SELECT 1 FROM #tmpMemberUpd)
BEGIN
  UPDATE mi WITH(ROWLOCK, UPDLOCK)
  SET mi.UserName = u.username2
  FROM dbo.MemberInfo mi
  INNER JOIN #tmpMemberUpd u ON u.IBCCustId = mi.IBCCustID
END