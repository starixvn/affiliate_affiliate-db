/*<info serverAlias="DBN88-bodb_N88" isFunction="0" isNested=""></info>*/
/*	
	Created: 20241111@Sally
	Task: Add Total Deposit & Support Report by Date [RedmineID: #213344]
	DB: DBN88/bodb_N88
	- Grant permission for 'wsv_afinet'
*/
USE bodb_N88
GO

GRANT SELECT ON [dbo].[DepositInfo] TO [wsv_afinet]