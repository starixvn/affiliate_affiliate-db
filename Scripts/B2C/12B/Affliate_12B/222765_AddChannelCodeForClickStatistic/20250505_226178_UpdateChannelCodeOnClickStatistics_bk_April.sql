/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250505@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Update Data for ChannelCode on  ClickStatistics_BK [RedmineID: #226178]
		 

*/

USE [Affiliate_12B]
GO

DECLARE @BatchSize INT = 2000
CREATE TABLE #batch (ClickId INT PRIMARY KEY, ChannelCode VARCHAR(50))

-----------ClickStatistics_bk
DROP TABLE IF EXISTS Tmp_ClickStatistics_bk
CREATE TABLE Tmp_ClickStatistics_bk (ClickId INT PRIMARY KEY, ChannelCode VARCHAR(50))

INSERT INTO Tmp_ClickStatistics_bk (ClickId, ChannelCode)
Select r.ClickId,  r.ChannelCode 
from DBSPARE.Affiliate_12B_20250430.dbo.ClickStatistics r WITH (NOLOCK)  
WHERE r.Date >= '2025-04-01' 
 

WHILE (1=1)
BEGIN
	TRUNCATE TABLE #batch

	DELETE TOP (@BatchSize) T
	OUTPUT deleted.ClickId, deleted.ChannelCode
		INTO #batch(ClickId,ChannelCode)
	FROM Tmp_ClickStatistics_bk t 

	IF @@ROWCOUNT = 0 BREAK
	 
	UPDATE a
	SET a.ChannelCode = b.ChannelCode
	FROM ClickStatistics_bk a WITH (ROWLOCK, UPDLOCK)
	INNER JOIN #batch b ON a.ClickId = b.ClickId
	
	WAITFOR DELAY '00:00:00:280'

END	


--- DROP TABLE Tmp_ClickStatistics_bk