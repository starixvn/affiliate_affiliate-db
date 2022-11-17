/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20221117@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update product name

*/

ALTER TABLE APIProduct_ImportQueue
ADD TpType INT NOT NULL DEFAULT -1
GO

ALTER TABLE APIProduct_ImportQueue
ADD SubItem VARCHAR(200) NOT NULL DEFAULT ''
GO

ALTER TABLE APIProduct_TimeTracker
ADD TpType INT NOT NULL DEFAULT -1
GO

ALTER TABLE APIProduct_TimeTracker
ADD SubItem VARCHAR(200) NOT NULL DEFAULT ''
GO

ALTER TABLE APIProduct_ImportQueue
ADD JsonData NVARCHAR(MAX)
GO

CREATE NONCLUSTERED INDEX IX_CheckInTime ON dbo.APIProduct_ImportQueue (CheckInTime)
GO

CREATE NONCLUSTERED INDEX IX_TpType_SubItem_WinlostDate ON dbo.APIProduct_ImportQueue (TpType, SubItem, WinlostDate)
GO

CREATE NONCLUSTERED INDEX [IX_TpType_SubItem] ON [dbo].[APIProduct_TimeTracker]
(
	TpType ASC
	,SubItem ASC
)
INCLUDE([Currency],[CallTime])  ON [ReportData]
GO

DECLARE @MinQueueId INT 

SELECT @MinQueueId = MIN(QueueId) FROM dbo.APIProduct_ImportQueue a WITH(NOLOCK) 

WHILE 1 = 1
BEGIN
	UPDATE dbo.APIProduct_ImportQueue WITH(ROWLOCK, UPDLOCK)
		SET TpType = -1, SubItem = ''
	WHERE QueueId >= @MinQueueId AND QueueId < @MinQueueId + 2000

	IF @@ROWCOUNT = 0
		BREAK

	SET @MinQueueId = @MinQueueId + 2000
END
GO

UPDATE Products WITH(ROWLOCK, UPDLOCK)
	SET ProductName = '12Emerald - Playtech'
WHERE ProductName = 'Playtech Casino'
GO

UPDATE Products WITH(ROWLOCK, UPDLOCK)
	SET ProductName = '12Opal - eBet'
WHERE ProductName = '12Opal - EBet'
GO

DECLARE @ID INT = 1

SELECT @ID = MIN(ID) FROM dbo.APIProduct_TimeTracker WITH(NOLOCK) 

WHILE 1 = 1
BEGIN
	UPDATE dbo.APIProduct_TimeTracker WITH(ROWLOCK, UPDLOCK)
		SET TpType = -1, SubItem = ''
	WHERE Id >= @ID AND Id < @ID + 2000
	
	IF @@ROWCOUNT = 0
		BREAK
	SET @ID += 2000
END