ALTER PROCEDURE [dbo].[AffAdmin_CommGroupAssign] 
	@UserId INT
	,@GroupId INT
	,@AffIDList NVARCHAR(4000)
	,@IP VARCHAR(20)
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
	,@RefNo BIGINT = NULL OUTPUT
AS
/*  
Created: 20090719@DungTong  
Task : Assign a commission group (GroupID<1000) for multiple Affilites   
DB: DB052.Affiliate_AoncashUAT
Original:  
  
Revisions: 
	-20140127@Bobby: add currency checking when assign CommGroup 
Parameters:  
.@UserID : Administrator user id  
.@GroupID : <1000  
.@AfIDList: list of AffID separated by comma.Maximum of 200 AffIDs are assiged each time                  
.@IP : IP of admin user               
.@ErrCode:    
              0 : no error raised  
              >0 : there was an error  
.@ErrMsg :     
              empty: no error raised  
              others : the error message detail                            
                            
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @AffId INT;
	DECLARE @AffCurrency TABLE (AffID INT, Currency INT);

	--currency checking
	INSERT INTO @AffCurrency(AffID, Currency)
	SELECT DISTINCT AffID, Currency
	FROM dbo.AffInfo WITH(NOLOCK)
	WHERE AffID IN (SELECT cast(val AS INT) AS AffID
						FROM dbo.strsplit(@AffIDList, ',')) 

	SELECT @AffId = AffID
	FROM @AffCurrency

	EXEC dbo.Aff_CheckPermissionOnAff @custid = @UserID
		,@AffId = @AffId
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF (@ErrMsg <> '') RETURN

	IF (NOT EXISTS (
				SELECT 1
				FROM dbo.CommGroup WITH(NOLOCK)
				WHERE GroupID = @GroupID 
					AND IsDeleted = 0
					AND (@GroupId = 102 
							OR Currency = ISNULL((SELECT TOP 1 Currency FROM @AffCurrency), Currency) 
					)
			)
		)
	BEGIN
		SELECT @ErrCode = 601

		RETURN
	END

	--Check AffIDList  
	/*    
    Input params is valid with the correct format. Use Try..Catch to eval the input value  
*/
	DECLARE @NoAff INT
		,@CountCurrency INT

	BEGIN TRY
		SELECT @NoAff = sum(1)
		FROM AffInfo WITH (NOLOCK)
		WHERE AffID IN (
				SELECT cast(val AS INT) AS AffID
				FROM dbo.strsplit(@AffIDList, ',')
				) 
				AND STATUS = 'approved' -- and IsClosed=0  

		IF (
				@NoAff <> (
					SELECT sum(1)
					FROM dbo.strsplit(@AffIDList, ',')
					)
				)
		BEGIN
			SELECT @ErrCode = 602

			RETURN
		END

		--Check Currency of Group and Currency of Match   
		SET @CountCurrency = 0

		SELECT @CountCurrency = count(DISTINCT currency)
		FROM AffInfo(NOLOCK)
		WHERE AffID IN (
				SELECT cast(val AS INT) AS AffID
				FROM dbo.strsplit(@AffIDList, ',')
				)

		IF (isnull(@CountCurrency, 0) > 1)
		BEGIN
			SELECT @ErrCode = 604

			RETURN
		END
	END TRY

	BEGIN CATCH
		SELECT @ErrCode = 603

		RETURN
	END CATCH

	--BEGIN TRANSACTION AFTER CHECKING VALID INPUT DATA  
	BEGIN TRANSACTION

	--Delete GroupID>1000 where GroupID in AffiliateID list and already assigned before  
	DELETE DeductionSetting
	WHERE GroupID IN (
			SELECT GroupID
			FROM AffInfo(NOLOCK)
			WHERE AffID IN (
					SELECT cast(val AS INT)
					FROM dbo.strsplit(@AffIDList, ',')
					) AND AffID = GroupID
			)

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 605

		RETURN
	END

	DELETE GroupSetting
	WHERE GroupID IN (
			SELECT GroupID
			FROM AffInfo(NOLOCK)
			WHERE AffID IN (
					SELECT cast(val AS INT)
					FROM dbo.strsplit(@AffIDList, ',')
					) AND AffID = GroupID
			)

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 606

		RETURN
	END

	DELETE CommGroup
	WHERE GroupID IN (
			SELECT GroupID
			FROM AffInfo(NOLOCK)
			WHERE AffID IN (
					SELECT cast(val AS INT)
					FROM dbo.strsplit(@AffIDList, ',')
					) AND AffID = GroupID
			)

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 607

		RETURN
	END

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET GroupID = @GroupID
	WHERE AffID IN (
			SELECT cast(val AS INT) AS AffID
			FROM dbo.strsplit(@AffIDList, ',')
			)

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 608

		RETURN
	END

	COMMIT TRANSACTION

	--Write the log   
	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100)

	IF (
			(
				SELECT count(1)
				FROM dbo.strsplit(@AffIDList, ',')
				) = 1
			)
		SELECT @AffID = cast(@AffIDList AS INT)
	ELSE
		SELECT @AffID = 0

	SELECT @LogData = N'Assign a common commission group.GroupID=' + dbo.Aff_ToString(@GroupID) + '\n AffIDList=' + dbo.Aff_ToString(@AffIDList)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@AffID = @AffID
		,@Typename = 'CommissionGroup'
		,@SPName = @SPName
		,@IP = @IP
		,@RefNo = @RefNo OUTPUT
		,@Details = @LogData
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupDel] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupDel] TO [vnteam]

