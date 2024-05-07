/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"  isFunction="0" isNested="0"></info>*/
/*
	Created: 20240422@Sally
	DB: DBN88-bodb_N88
	Task:  Calculate commission by Turnover [RedmineID: #203756]
	Step 1:
		- Add Config GroupType
*/

ALTER TABLE dbo.CommGroup -- 104 rows
	ADD GroupTypeId INT NOT NULL
	CONSTRAINT DF_CommGroup_GroupTypeId DEFAULT (1)
GO

EXEC sp_rename  '[dbo].[rptAffCommission].[QMTurnover]', 'NetTurnover', 'COLUMN';
GO
EXEC sp_rename  '[dbo].[rptAffCommissionDetail].[QMTurnover]', 'NetTurnover', 'COLUMN';

GO
CREATE TABLE dbo.GroupType (
	GroupTypeId INT IDENTITY(1,1) NOT NULL,
	GroupTypeBy VARCHAR(50) NOT NULL,
	GroupTypeName NVARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	DisplayOrder SMALLINT NOT NULL,
	CONSTRAINT [PK_GroupType] PRIMARY KEY CLUSTERED 
	(
		[GroupTypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO

SET IDENTITY_INSERT dbo.GroupType ON
INSERT INTO dbo.GroupType (GroupTypeId, GroupTypeBy, GroupTypeName, DisplayOrder)
	SELECT GroupTypeId, GroupTypeBy, GroupTypeName, DisplayOrder
	FROM (
		SELECT 1 AS GroupTypeId, 'Winloss' AS GroupTypeBy, 'Calculate Revenue Share by Winloss' AS GroupTypeName, 1 AS DisplayOrder
		UNION ALL
		SELECT 2 AS GroupTypeId, 'Turnover' AS GroupTypeBy, 'Calculate Revenue Share by Turnover' AS GroupTypeName, 2 AS DisplayOrder
	)t

SET IDENTITY_INSERT dbo.GroupType OFF
GO
INSERT INTO dbo.Deductions (DeductionId, DeductionName, DeductedPercentage, IsTest, IsDeleted, DeductedAmount, IsDeductedPercent, Commission)
	VALUES (16, 'Kill Rate', 0.03000000, 0, 0, NULL, 1, 0);
