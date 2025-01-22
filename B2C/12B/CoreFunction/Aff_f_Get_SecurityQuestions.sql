/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_Get_SecurityQuestions]
(
	@Language VARCHAR(20) = 'en-US'
)
RETURNS TABLE
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Login function - Core function - Security Questions

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

*/

RETURN
	SELECT
		QuestionID
		,CASE @Language
			WHEN 'en-US' THEN QuestionNameEN
			WHEN 'zh-CN' THEN QuestionNameCS
			WHEN 'zh-TW' THEN QuestionNameCH
			WHEN 'id-ID' THEN QuestionNameID
			WHEN 'vi-VN' THEN QuestionNameVN
			WHEN 'th-TH' THEN QuestionNameTH
			WHEN 'ko-KR' THEN QuestionNameKO
			WHEN 'es-ES' THEN QuestionNameES
			WHEN 'ja-JP' THEN QuestionNameJP
			WHEN 'en-IN' THEN QuestionNameHIEN
			WHEN 'en-GB' THEN QuestionNameENEURO
			WHEN 'km-KH' THEN QuestionNameKH
			WHEN 'bn-BD' THEN QuestionNameBN
			ELSE QuestionNameEN END AS Question
	FROM (
		VALUES
			(11,N'Name of the worst kid who bullied you?',N'欺负你的人的名字？',N'欺負你的人的名字？',N'Nama anak yang pernah melakukan bully terhadap saya ? ',N'Tên của đứa bạn thường hay bắt nạt bạn?',N'บอกชื่อเด็กที่ชอบแกล้งคุณบ่อยสุดในวัยเด็ก?',N'학창 시절 나를 괴롭히던 친구 이름?',N'Name of the worst kid who bullied you?',N'Name of the worst kid who bullied you?',N'Name of the worst kid who bullied you?',N'Name of the worst kid who bullied you?', N'ឈ្មោះក្មេងអាក្រក់បំផុតដែលមើលងាយអ្នក?',N'Name of the worst kid who bullied you?')
			,(12,N'Name of your childhood bestfriend?',N'你儿时最好的朋友的名字？',N'你兒時最好的朋友的名字？',N'Nama teman baik saya ?',N'Tên người bạn thân nhất thời niên thiếu của bạn?',N'บอกชื่อเพื่อนที่คุณสนิทที่สุดในวัยเด็ก?',N'학창 시절 가장 친한 친구는?',N'Name of your childhood bestfriend?',N'Name of your childhood bestfriend?',N'Name of your childhood bestfriend?',N'Name of your childhood bestfriend?', N'ឈ្មោះ​មិត្ត​ភក្តិ​កាលពីវ័យ​កុមារ​របស់​អ្នក?',N'Name of your childhood bestfriend?')
			,(13,N'Your childhood nickname?',N'你的童年外号？',N'你的童年外號？',N'Julukan nama waktu kecil ?',N'Tên thường gọi thời niên thiếu của bạn?',N'ชื่อเล่นของคุณในวัยเด็กคือ?',N'학창 시절 별명은?',N'Your childhood nickname?',N'Your childhood nickname?',N'Your childhood nickname?',N'Your childhood nickname?', N'ឈ្មោះហៅក្រៅកាលពីវ័យកុមារភាពរបស់អ្នក?',N'Your childhood nickname?')
			,(14,N'Name of the first girl you had a crush on?',N'你喜欢的第一个女孩的名字？',N'你喜歡的第一個女孩的名字？',N'Nama wanita pertama yang tidak saya suka ?',N'Tên bạn gái đầu tiên của bạn?',N'บอกชื่อคนที่คุณหลงรักครั้งแรกในชีวิต?',N'당신의 첫 사랑 이름은?',N'Name of the first girl you had a crush on?',N'Name of the first girl you had a crush on?',N'Name of the first girl you had a crush on?',N'Name of the first girl you had a crush on?', N'ឈ្មោះមនុស្សស្រីដំបូងដែលអ្នកធ្លាប់ស្រលាញ់?',N'Name of the first girl you had a crush on?')
			,(15,N'Name of your most memorable teacher?',N'你最难忘的老师的名字？',N'你最難忘的老師的名字？',N'Nama guru kenangan saya?',N'Tên giáo viên bạn yêu quý nhất?',N'บอกชื่อคุณครูที่คุณจำได้แม่นยำที่สุด?',N'가장 기억에 남는 선생님은?',N'Name of your most memorable teacher?',N'Name of your most memorable teacher?',N'Name of your most memorable teacher?',N'Name of your most memorable teacher?', N'ឈ្មោះគ្រូដែលអ្នកចងចាំបំផុត?',N'Name of your most memorable teacher?')
			,(16,N'Name of your first teacher?',N'你的第一位老师的名字？',N'你的第一位老師的名字？',N'Nama guru pertama saya?',N'Tên giáo viên đầu tiên của bạn?',N'บอกชื่อคุณครูคนแรกของคุณในวัยเด็ก?',N'가장 첫 담임 선생님 이름은?',N'Name of your first teacher?',N'Name of your first teacher?',N'Name of your first teacher?',N'Name of your first teacher?', N'ឈ្មោះគ្រូដំបូងរបស់អ្នក?',N'Name of your first teacher?')
			,(17,N'Name of your oldest cousin?',N'你年纪最大堂兄的名字？',N'你年紀最大堂兄的名字？',N'Nama sepupu tertua saya?',N'Tên anh họ lớn tuổi nhất của bạn?',N'บอกชื่อลูกพี่ลูกน้องที่มีอายุเยอะที่สุดในตระกูล?',N'당신의 가장 친한 친척 이름은?',N'Name of your oldest cousin?',N'Name of your oldest cousin?',N'Name of your oldest cousin?',N'Name of your oldest cousin?', N'ឈ្មោះបងប្អូនជីដូនមួយរបស់អ្នកដែលគាត់មានអាយុច្រើនជាងគេ?',N'Name of your oldest cousin?')
	) AS t(
			QuestionID
			,QuestionNameEN
			,QuestionNameCS
			,QuestionNameCH
			,QuestionNameID
			,QuestionNameVN
			,QuestionNameTH
			,QuestionNameKO
			,QuestionNameES
			,QuestionNameJP
			,QuestionNameHIEN
			,QuestionNameENEURO
			,QuestionNameKH
			,QuestionNameBN
		)
GO