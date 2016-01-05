ALTER  FUNCTION  [dbo].[AffAdmin_f_FunctionInfo_Select]
(		
	@FunctionID INT,
	@LicenseeID INT
)
RETURNS @tbData TABLE
(
	FunctionID		INT,
	LicenseeID		INT,
	FunctionName	NVARCHAR(50),
	FunctionNote	NVARCHAR(2000),
	FunctionDesc	NVARCHAR(50),
	FunctionRender	TINYINT,
	CreateDate		DATETIME,
	ModifyDate		DATETIME,
	DisplayOrder	TINYINT,
	Creator			INT,
	ParentID		INT,
	Filenames		VARCHAR(2000)
) 
AS	
/*
Created:20151113@Victor
Task :  SSO from Internal Admin to Affiliate Admin
DB: DBAFF - Affiliate database

Revisions:
Param's Explanation:

*/

BEGIN
	SET @FunctionID = ISNULL(@FunctionID,'')

	INSERT INTO @tbData (FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames)
	SELECT f.FunctionID, LicenseeID, FunctionName, FunctionNote, FunctionDesc, FunctionRender, CreateDate, ModifyDate, DisplayOrder, Creator, ParentID, Filenames
	FROM DBLIC.bodb_licensee.dbo.Aff_FunctionInfo f WITH (NOLOCK) 
		INNER JOIN DBLIC.bodb_licensee.dbo.Aff_LicenseeFunction lf WITH (NOLOCK) ON f.FunctionID = lf.FunctionID 
	WHERE (@FunctionID = '' OR f.FunctionID = @FunctionID)
		AND lf.LicenseeID = @LicenseeID
		AND lf.IsActive = 1

	RETURN
END
GO
GRANT SELECT ON [dbo].[AffAdmin_f_FunctionInfo_Select] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_f_FunctionInfo_Select] TO [vnteam] AS [dbo]