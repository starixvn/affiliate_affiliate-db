/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20251013@Sophia
	DB: DB12B-bodb_12B
	Task: Add Status,CustID column to existing clustered index CIX_DepositInfo [RedmineId : #239737]
 
*/

USE bodb_12B
GO


-- Alter existing clustered index to add CustId as additional key column
/****** Object:  Index [CIX_DepositInfo]    Script Date: 10/13/2025 10:58:22 AM ******/
CREATE CLUSTERED INDEX [CIX_DepositInfo] ON [dbo].[DepositInfo]
(
	[WinlostDate] ASC,
    [Status] ASC,
	[CustId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = ON, DROP_EXISTING = ON, ONLINE = ON, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [ReportData]
GO
 