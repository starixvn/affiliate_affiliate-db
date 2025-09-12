/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20250912@Danny
	DB: DBAFF12BET-Affiliate_12BET
	Task: Remove Affiliate_12BET: ImportData_UAT job

*/


-- Step 1 drop job

USE msdb;
EXEC sp_delete_job 
    @job_name = N'Affiliate_12BET: ImportData_UAT';
GO


-- Step 2 drop unused SPs
USE Affiliate_12BET;

DROP PROCEDURE IF EXISTS Aff_GetMemberStatistics_test;
DROP PROCEDURE IF EXISTS Task_Aff_ImportDataTest;
DROP PROCEDURE IF EXISTS Task_Aff_ImportData_3rdProductTest;
DROP PROCEDURE IF EXISTS Task_APIProduct_ImportQueue_ProcessTest;
DROP PROCEDURE IF EXISTS Task_APIProduct_ImportQueue_ProductTest;
DROP PROCEDURE IF EXISTS Task_Aff_ImportData_API_JobTest;
DROP PROCEDURE IF EXISTS Task_Aff_ImportData_JobTest;
DROP PROCEDURE IF EXISTS Task_NewAff_ImportData_API_JobTest;
DROP PROCEDURE IF EXISTS Task_APIProduct_ImportQueueTest;
DROP PROCEDURE IF EXISTS Task_APIProduct_ImportQueue_Process_JobTest;
DROP PROCEDURE IF EXISTS Aff_BannerMediaIns_test;
DROP PROCEDURE IF EXISTS Aff_BannerSelDetail_1_test;
DROP PROCEDURE IF EXISTS Aff_BannerUpd_1_test;
DROP PROCEDURE IF EXISTS Aff_BannerSelByParentCate_test;
DROP PROCEDURE IF EXISTS Aff_BannerSel_1_test;
DROP PROCEDURE IF EXISTS Task_NewAPIProduct_ImportQueue_ProcessTest;
DROP PROCEDURE IF EXISTS Task_NewAPIProduct_ImportQueue_ProductTest;
DROP PROCEDURE IF EXISTS Task_APIProduct_CallTimeByProductSelTest;
DROP PROCEDURE IF EXISTS Task_APIProduct_CallTimeInsTest;
DROP PROCEDURE IF EXISTS Task_NewAPIProduct_ImportQueueTest;
DROP PROCEDURE IF EXISTS Task_NewAPIProduct_ImportQueue_Process_JobTest;


-- Step 3 drop unused Table
DROP TABLE IF EXISTS bettrans_Topaz2Test;
DROP TABLE IF EXISTS bettrans_BTi2Test;
DROP TABLE IF EXISTS bettrans_N2Test;
DROP TABLE IF EXISTS bettrans_EATest;
DROP TABLE IF EXISTS AffMediaLink_test;
DROP TABLE IF EXISTS APIProduct_TimeTrackerTest;
DROP TABLE IF EXISTS APIProduct_ImportQueueTest;
DROP TABLE IF EXISTS APIProductMappingSettingsTest;
DROP TABLE IF EXISTS APIProductSettingsTest;
DROP TABLE IF EXISTS bettrans_APIProductsTest;
DROP TABLE IF EXISTS ProductsTest;
DROP TABLE IF EXISTS SystemSettingsTest;
DROP TABLE IF EXISTS bettrans_Betsoft2Test;
DROP TABLE IF EXISTS bettrans_PlaytechTest;