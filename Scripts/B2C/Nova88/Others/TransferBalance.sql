/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20211005@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Add new table, column to support Affiliate transfer to Player

	USE Affiliate_N88
	USE Affiliate_N8B
	USE Affiliate_N8G
*/

-- Step 1. Insert new permission for new function
	insert into dbo.AffFunctionInfo (FuncName, FuncNote, FuncDesc, FuncRender, CreateDate)
	values ('[TransferPlayerSetting]', '', 'Transfer Balance For Player Setting', 3, GETDATE())
		,('[TransferPlayerReport]', '', 'Transfer Balance For Player Report', 3, GETDATE())

	insert into dbo.AffGroupPolicy (GroupID, FuncID, Policy)
	select g.GroupID, f.FuncID, 3
	from dbo.AffGroupInfo g with (nolock)
		inner join dbo.AffFunctionInfo f with (nolock) on f.FuncName in ('[TransferPlayerSetting]', '[TransferPlayerReport]')

	insert into dbo.AffMemberPolicy (CustId, FuncId, Policy)
	select g.CustId, f.FuncID, 3
	from dbo.Affiliate_User g with (nolock)
		inner join dbo.AffFunctionInfo f  with (nolock) on f.FuncName in ('[TransferPlayerSetting]', '[TransferPlayerReport]')

-- Step 2. Add new columns for Transfer Limit Setting
	ALTER TABLE AffDetail
		ADD TransferLimit MONEY
			,DisabledTransfer BIT CONSTRAINT DF_AffDetail_DisabledTransfer DEFAULT(1) -- disable as default
	GO

	UPDATE dbo.AffDetail WITH (ROWLOCK)
	SET DisabledTransfer = 1
	GO

-- Step 3. Add new table for Transfer History
	CREATE TABLE dbo.TransferBalanceHistory
	(
		TransId					BIGINT NOT NULL IDENTITY (1000, 1)
		,TransTime				DATETIME
		,TransDate				DATETIME
		,Status					VARCHAR(20)
		,AffId					INT
		,AffUserName			VARCHAR(50)
		,Player_CustId			INT
		,Player_UserName		VARCHAR(50)
		,Player_Currency		INT
		,Player_CurrencyCode	VARCHAR(3)
		,CustId					INT
		,UserName				VARCHAR(50)
		,Currency				INT
		,CurrencyCode			VARCHAR(3)
		,Amount					MONEY
		,ExRate					FLOAT
		,LastSyncTime			DATETIME
		,SyncCount				TINYINT
		,SyncLog				VARCHAR(300)
		,CONSTRAINT PK_TransferBalanceHistory PRIMARY KEY NONCLUSTERED (TransId)
	) ON ReportData
	GO

	CREATE CLUSTERED INDEX CIX_TransferBalanceHistory ON dbo.TransferBalanceHistory (TransDate, AffId, CustId)
		ON ReportData
	GO