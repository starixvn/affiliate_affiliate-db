/*<info serverAlias="DBCUST-bodb_licensee" executers="bodbAdminNet,bodbLicenseeNet" isFunction="0" isNested="0"></info>*/
USE [bodb_licensee]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CheckIn]
	@CustID			INT,
	@NetSessionID	VARCHAR(30),
	@ServerID		INT,
	@On_UserID		INT OUTPUT,
	@IP				VARCHAR(15) = ''
AS

/*
	Created: 20151013@Victor
	Task: Check in
	DB: DBCUST.bodb_Licensee
	
	Revisions:
		- 20190424@Percy: Move SP to DBCUST.bodb_Licensee [RedmineID: #103658]
*/

BEGIN
	SET NOCOUNT ON
	
	UPDATE dbo.Aff_On_User WITH (ROWLOCK)
	SET IsKickedOut = 1
	WHERE CustID = @CustID AND ServerID = @ServerID
	
	INSERT INTO dbo.Aff_On_User (CustID, NetSessionID, ServerID, IsKickedOut, IP)
		VALUES (@custid, @NetSessionid, @ServerID, 0, @IP)

	SELECT @On_UserID = SCOPE_IDENTITY()
END
GO