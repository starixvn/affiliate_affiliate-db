ALTER PROCEDURE [dbo].[DEP_AdminUpdAffID] @DepositCustID INT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
BEGIN
	/*
Created: 20090910@Peter
Task : Remove a member  from Affiliate
DB: [DBDeposit].Deposit_DB
Original: 

Revisions:

Param's Explanation:

@ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert unsuccessful.
@ErrMsg: Error description.
*/
	BEGIN
		SET NOCOUNT ON

		--Check DepositCustID
		IF (
				NOT EXISTS (
					SELECT TOP (1) 1
					FROM Deposit_Customer WITH (NOLOCK)
					WHERE CustID = @DepositCustID
						AND isnull(AffiliateID, 0) > 0
					)
				)
		BEGIN
			SELECT @ErrMsg = 'This member does not exist in Affiliate System or be removed before!'
				,@ErrCode = 1001

			RETURN
		END

		BEGIN TRY
			UPDATE Deposit_Customer WITH (ROWLOCK, UPDLOCK)
			SET AffiliateID = 0
				,LastModifyDate = current_timestamp
			WHERE CustID = @DepositCustID
		END TRY

		BEGIN CATCH
			SELECT @ErrMsg = 'Remove member failed!'
				,@ErrCode = 1002

			RETURN
		END CATCH
	END
END
GO

GRANT EXECUTE ON [dbo].[DEP_AdminUpdAffID] TO [bodbAffiliateNet]
GO

GRANT VIEW DEFINITION ON [dbo].[DEP_AdminUpdAffID] TO [vnTeam]
GO


