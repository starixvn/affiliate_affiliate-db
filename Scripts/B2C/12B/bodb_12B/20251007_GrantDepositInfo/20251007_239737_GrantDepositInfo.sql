/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20251007@Sophia
	DB: bodb_12B
	Task: Grant SELECT permission on DepositInfo table to wsv_afinetv user	[RedmineID: #239737]
	
*/

USE [bodb_12B]
GO

-- Grant SELECT permission on DepositInfo table to wsv_afinetv
GRANT SELECT ON [dbo].[DepositInfo] TO [wsv_afinetv]
GO
  