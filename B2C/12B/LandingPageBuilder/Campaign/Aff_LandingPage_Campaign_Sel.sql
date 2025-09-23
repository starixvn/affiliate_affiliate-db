/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Campaign_Sel]
	@CampaignId INT = NULL
	,@StatusIds VARCHAR(50) = ''
AS

/*
	Created: 20250903@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: List of Campaign

	Revisions:
		- 20250903@Eddie: Initialize SP [RedmineID: #236797]
		- 20250917@Sophia: Added ORDER BY CampaignId DESC [RedmineID: #236797]

	Param's Explanation:
		- @CampaignId:
			+ NULL     : indicates dropdown list behavior
			+ not NULL : indicates popup behavior
		- @StatusIds:
			+ '0,1,2,3' : all status
			+ '0,2'     : multiple status
			+ '1'       : single status
*/

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Status TABLE (StatusId TINYINT);

	IF @CampaignId IS NOT NULL
	BEGIN

		SELECT cp.CampaignId
			  ,cp.CampaignName
			  ,cp.CampaignCode
			  ,cp.Description
			  ,cp.StatusId
			  ,f.Status
		FROM dbo.LandingPage_Campaign cp WITH (NOLOCK)
			INNER JOIN dbo.Aff_f_LandingPage_Campaign_Status() f ON f.StatusId = cp.StatusId
		WHERE cp.CampaignId = @CampaignId
		ORDER BY cp.CampaignId DESC;

	END
	ELSE
	BEGIN

		INSERT INTO @Status(StatusId)
		SELECT CAST(f.value AS TINYINT)
		FROM STRING_SPLIT(@StatusIds, ',') f;

		SELECT cp.CampaignId
			  ,cp.CampaignName
			  ,cp.CampaignCode
			  ,cp.Description
			  ,cp.StatusId
			  ,f.Status
		FROM dbo.LandingPage_Campaign cp WITH (NOLOCK)
			INNER JOIN dbo.Aff_f_LandingPage_Campaign_Status() f ON f.StatusId = cp.StatusId
		WHERE EXISTS(SELECT 1 FROM @Status s WHERE s.StatusId = cp.StatusId)
		ORDER BY cp.CampaignId DESC;

	END

END
GO