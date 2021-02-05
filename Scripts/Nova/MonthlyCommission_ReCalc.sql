/*<info serverAlias="DBAFFN8B-Affiliate_N8B"></info>*/
/*
	Created: 20210205@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Missing Platform Fee Setting (DeductionId = 10)

	
*/

use Affiliate_N8B
go

exec dbo.Task_Aff_Monthly_Commission @MonthDate = '2021-01-01', @IsForceUpdate = 1