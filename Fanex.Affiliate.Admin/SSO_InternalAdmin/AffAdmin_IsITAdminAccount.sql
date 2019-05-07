/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_IsITAdminAccount]
(
	@UserID		INT,
	@LicenseeID INT,
	@IsITAdmin	BIT = 0 OUTPUT
)
AS

/*
	Created: 20151117@Victor
	DB: DBCUST.bodb_Licensee
	Remark: Check IT Admin account
	
	Revisions:
		- 20190424@Percy: Move function to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SELECT @IsITAdmin = IsITAdmin FROM dbo.AffAdmin_f_IsITAdmin (@UserID, @LicenseeID)
END
GO