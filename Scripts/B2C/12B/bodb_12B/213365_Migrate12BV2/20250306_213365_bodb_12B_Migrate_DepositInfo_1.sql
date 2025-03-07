/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250305@Sally
	DB: DB12B-bodb_12B
	Task: Support new Aff 12B [RedmineId : #212201]
		4.1 Create temp table for the depositinfo data 		

*/


USE bodb_12B
GO
DROP TABLE IF EXISTS dbo.tmpFPDImport 
GO
CREATE TABLE dbo.tmpFPDImport(
	CustId INT,
	FDT DATETIME,
	FDAmount MONEY,
	CONSTRAINT PK_tmpFPDImport PRIMARY KEY (CustId)
)
GO

--- Pass those files to local disk 
BULK INSERT tmpFPDImport
FROM 'D:\FDT_FDM_Import02.csv'
WITH (
    FORMATFILE = 'D:\FDT_FDM_Import_FormatFile02.xml',
    FIRSTROW = 2
);

SELECT count(1)FROM dbo.tmpFPDImport m with (NOLOCK)
