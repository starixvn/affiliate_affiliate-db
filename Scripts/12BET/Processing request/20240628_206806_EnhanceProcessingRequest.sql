/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 202406128@Sally
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	Enhance Processing Request function [RedmineID : #206806]
*/

ALTER TABLE dbo.ProcessingRequest 
ADD ChangeFirstName NVARCHAR(100)  NULL
	,ChangeLastName NVARCHAR(100) NULL

