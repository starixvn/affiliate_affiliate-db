/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" selecters="bodbAdminNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_MediaCategory_Sel]
(
)
RETURNS TABLE
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core function store Category on Media Gallery

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]

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
			(1, 'Sportsbook'		, 1, 'Sportsbook'	, 1)
			,(2, 'SB Bonus'			, 1, 'Sportsbook'	, 1)
			,(3, 'Soccer'			, 1, 'Sportsbook'	, 1)
			,(4, 'Basketball'		, 1, 'Sportsbook'	, 1)
			,(5, 'Tennis'			, 1, 'Sportsbook'	, 1)
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
			,(151, 'Racebook'		, 151, 'Racebook'	, 1)
		
		-- Text: TypeId = 2, CategoryId: 1001 --> 2000
			,(1001, 'Bonus'			, 1001, 'Bonus'		, 2)
			,(1002, 'Football'		, 1002, 'Football'	, 2)
			,(1003, 'Poker'			, 1003, 'Poker'		, 2)
			,(1004, 'Casino'		, 1004, 'Casino'	, 2)
			,(1005, 'Basketball'	, 1005, 'Basketball', 2)
			,(1006, 'Tennis'		, 1006, 'Tennis'	, 2)
	) AS MediaCategory (CategoryId, Category, ParentCategoryId, ParentCategory, TypeId)

	UNION ALL

	SELECT CategoryId, Category, ParentCategoryId, ParentCategory, TypeId, 2 AS TargetId
	FROM (
		VALUES
		-- Banner: TypeId = 1, CategoryId: 5001 --> 6000
			(5001, 'Sign up'		, 5001, 'Sign up'	, 1)
		
		-- Text: TypeId = 2, CategoryId: 6001 --> 7000
			,(6001, 'Sign up'		, 6001, 'Sign up'	, 2)
	) AS MediaCategory (CategoryId, Category, ParentCategoryId, ParentCategory, TypeId)
GO