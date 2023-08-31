/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="1"></info>*/  
CREATE PROCEDURE [dbo].[Aff_Admin_Assign_Check]  
	@AffName	VARCHAR(50)
	,@AffId    	INT = 0 OUTPUT
	,@ErrCode  	INT = 0 OUTPUT
	,@ErrMsg   	NVARCHAR(4000) = '' OUTPUT
AS  
/*
	Created: 20230908@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Member - Active Member - Assign Affiliate - Check Affiliate to assign

	Revisions:  
			- 20230908@Eddie: Initialize SP [RedmineID: #180516]

	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	SELECT @AffName = LTRIM(RTRIM(ISNULL(@AffName, '')))

	-- Checking affiliate to assign
	SELECT @AffId = AffId
	FROM dbo.AffInfo WITH (NOLOCK)
	WHERE UserName = @AffName
	  AND Status = 'approved'
	  AND IsClosed = 0

	SELECT @AffId = ISNULL(@AffId, 0)

	IF @AffId = 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Affiliate'
	END
	ELSE SELECT @ErrCode = 0, @ErrMsg = ''

END