/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_MediaCategory_Sel]
(
)
RETURNS TABLE
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function store Category on Media Gallery

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

	Params Explanation:
		- TypeId:
			1: Banner List
			2: Text List
		- TargetId:
			1: Member
			2: Affiliate
		- ParentCategoryId: main Category
*/

RETURN
	SELECT CategoryId, Category, ParentCategoryId, ParentCategory, TypeId, 1 AS TargetId
	FROM (
		VALUES
		-- Banner: TypeId = 1, CategoryId: 1 --> 1000
			-- Sportsbook: 1 --> 50
			(1, 'Sports'			, 1, 'Sports'	, 1)
			,(2, 'SB Bonus'			, 1, 'Sports'	, 1)
			,(3, 'Soccer'			, 1, 'Sports'	, 1)
			,(4, 'Basketball'		, 1, 'Sports'	, 1)
			,(5, 'Tennis'			, 1, 'Sports'	, 1)
			-- Casino: 51 --> 100
			,(51, 'Casino'			, 51, 'Casino'		, 1)
			,(52, 'Casino Bonus'	, 51, 'Casino'		, 1)
			,(53, 'Baccarat'		, 51, 'Casino'		, 1)
			,(54, 'Blackjack'		, 51, 'Casino'		, 1)
			,(55, 'Slot'			, 51, 'Casino'		, 1)
			,(56, 'Roulette'		, 51, 'Casino'		, 1)
			,(57, 'Sic bo'			, 51, 'Casino'		, 1)
			-- Number Game: 101 --> 150
			,(101, 'Number Game'	, 101, 'Number Game', 1)
			-- Racebook: 151 --> 200
			/* ,(151, 'Racebook'		, 151, 'Racebook'	, 1) -- removed */
			-- Exchange: 201 --> 250
			,(201, 'Exchange'		, 201, 'Exchange', 1)
			-- ESports: 251 --> 300
			,(251, 'E-Sports'		, 251, 'E-Sports', 1)
			-- Playtech: 301 --> 350
			,(301, 'Playtech'		, 301, 'Playtech', 1)
			-- Live Casino: 351 --> 400
			,(351, 'Live Casino'	, 351, 'Live Casino', 1)
			-- Arcade: 401 --> 450
			,(401, 'Arcade'			, 401, 'Arcade', 1)
			-- P2P: 451 --> 500
			,(451, 'P2P'			, 451, 'P2P', 1)
			-- Keno: 501 --> 550
			,(501, 'Keno'			, 501, 'Keno', 1)
			-- Lottery: 551 --> 600
			,(551, 'Lottery'		, 551, 'Lottery', 1)
		
		-- Text: TypeId = 2, CategoryId: 1001 --> 2000
	) AS MediaCategory (CategoryId, Category, ParentCategoryId, ParentCategory, TypeId)

	UNION ALL

	SELECT CategoryId, Category, ParentCategoryId, ParentCategory, TypeId, 2 AS TargetId
	FROM (
		VALUES
		-- Banner: TypeId = 1, CategoryId: 5001 --> 6000
			(5001, 'Sign up'		, 5001, 'Sign up'	, 1)
		
		-- Text: TypeId = 2, CategoryId: 6001 --> 7000
	) AS MediaCategory (CategoryId, Category, ParentCategoryId, ParentCategory, TypeId)
GO