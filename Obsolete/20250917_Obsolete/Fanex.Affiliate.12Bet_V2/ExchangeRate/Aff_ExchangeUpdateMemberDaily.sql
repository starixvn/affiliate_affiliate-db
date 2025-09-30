ALTER PROCEDURE [dbo].[Aff_ExchangeUpdateMemberDaily]	
	@ExchangeId int,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
--DB06.bodb02
SELECT @ErrCode = 0

declare @FirstDateOfThisMonth smalldatetime
set @FirstDateOfThisMonth = dateadd(m, datediff(m, 0, current_timestamp), 0)

update b WITH(ROWLOCK,UPDLOCK)
set b.AffExRate = ex.Actualrate2
from MemberDaily b
	inner join Exchange_Current ex with(nolock) on b.Currency = ex.ExchangeId
where ex.ExchangeId = @ExchangeId	
	and b.winlostdate >= @FirstDateOfThisMonth

IF @@Error <> 0
BEGIN	
	SELECT @ErrCode = 101, @ErrMsg = 'Update exchange rate is unsuccessful.'
	return
END


GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeUpdateMemberDaily] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeUpdateMemberDaily] TO [vnteam]