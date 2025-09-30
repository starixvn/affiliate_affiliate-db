ALTER PROCEDURE [dbo].[Aff_UpdAffType] 
	@UserId INT
	,@AffID INT
	,@AffType TINYINT
	,@IP NVARCHAR(15) = ''
	,@Language VARCHAR(5) = 'en-US'
	,@ErrCode INT = 0 OUTPUT
AS
/*Created: 20140210@Brian
Task : Update AffType
DB:  DB052.Affiliate_12BET

Revisions:    
	- 20140226@Bobby: Update AffType for AFF user
			
Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	IF (
			NOT EXISTS (
				SELECT 1
				FROM AffInfo(NOLOCK)
				WHERE AffID = @AffID
				)
			)
	BEGIN
		SELECT @ErrCode = 13 --'Error! This affiliate does not exist!'

		RETURN
	END

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET AffType = @AffType
	WHERE AffID = @AffID

	DECLARE @SPName VARCHAR(50)
		,@Detail NVARCHAR(4000)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	SELECT @Detail = 'Update AffInfo AffType. AffID= ' + dbo.Aff_ToString(@AffID) + 'AffType= ' + dbo.Aff_ToString(@AffType)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@AffID = @AffID
		,@Typename = 'AffInfo'
		,-- refer to table LogType  
		@SPName = @SPName
		,@Details = @Detail
		,@IP = @IP
END
