/*<info serverAlias="DBEXT-bodb02" ></info>*/
/*
	Created: 20240326@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Switch to use new account [Redmine: #201841]
		- Grant Permission SP/Func
		
*/ 
USE bodb02
GO
GRANT SELECT ON [dbo].[Exchange] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Customer] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Aff_API_ExchangeDailyOanda_Sel] TO [wsv_afinet]
GO
