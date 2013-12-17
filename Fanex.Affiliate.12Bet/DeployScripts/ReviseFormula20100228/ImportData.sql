/*
 On April 1, 2010
 This script is run again to import data from 01/02/2010 -> 31/03/2010 */
 
Declare @AffId int, @Fromdate smalldatetime, @Todate smalldatetime

Select @FromDate = 'Jan 01 2008',--Setting date generate data
	@ToDate = dateadd(d, -1, convert(varchar(10), current_timestamp, 120))

IF Datediff(d, @ToDate, Current_Timestamp) <= 0-- Not allow calculate in current date
	Select @ToDate = dateadd(d, -1, convert(varchar(10), current_timestamp, 120))

Begin Transaction

Begin Try
	delete AffDaily where winlostdate between @Fromdate and @ToDate--Delete data from Old Data

	DECLARE Aff_Cursor CURSOR FOR 
	SELECT distinct AffID
	FROM MemberDaily with(nolock)
	WHERE winlostdate between @Fromdate and @ToDate

	OPEN Aff_Cursor

	FETCH NEXT FROM Aff_Cursor 
	INTO @AffId

	WHILE @@FETCH_STATUS = 0
	BEGIN    
		insert into AffDaily
		Exec Aff_AffiliateDailySelForImport @AffID=@AffId,@Fromdate=@Fromdate,@Todate=@Todate
		-- Get the next vendor.
		FETCH NEXT FROM Aff_Cursor 
		INTO @AffId
	END 
	CLOSE Aff_Cursor
	DEALLOCATE Aff_Cursor
End Try
Begin Catch
	select 'Error when you insert Data: ' + ERROR_MESSAGE() AS ErrorMessage
	CLOSE Aff_Cursor
	DEALLOCATE Aff_Cursor
	Rollback transaction
	Return
End Catch

Commit Transaction
Select 'Insert Data successfully '