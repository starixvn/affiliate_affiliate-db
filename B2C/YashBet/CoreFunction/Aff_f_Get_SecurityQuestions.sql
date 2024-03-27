/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_Get_SecurityQuestions]
(
	@Language VARCHAR(20) = 'en-US'
)
RETURNS TABLE
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Login function - Core function - Security Questions

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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
			WHEN 'hi-IN' THEN QuestionNameHI
			WHEN 'ms-MY' THEN QuestionNameMS
			WHEN 'km-KH' THEN QuestionNameKH
			WHEN 'bn-BD' THEN QuestionNameBN
			ELSE QuestionNameEN END AS Question
	FROM (
		VALUES
			(12,N'Name of your childhood bestfriend?',N'你儿时最好的朋友的名字？',N'你兒時最好的朋友的名字？',N'Nama teman baik saya ?',N'Tên người bạn thân nhất thời niên thiếu của bạn?',N'บอกชื่อเพื่อนที่คุณสนิทที่สุดในวัยเด็ก?', N'आपके बचपन के सबसे अच्छे दोस्त का नाम?', N'Nama kawan baik masa kecil anda?', N'ឈ្មោះ​មិត្ត​ភក្តិ​របស់​អ្នកកាលនៅកុមារភាព?', N'আপনার ছোটবেলার সেরা বন্ধুর নাম?')
			,(13,N'Your childhood nickname?',N'你的童年外号？',N'你的童年外號？',N'Julukan nama waktu kecil ?',N'Tên thường gọi thời niên thiếu của bạn?',N'ชื่อเล่นของคุณในวัยเด็กคือ?', N'आपका बचपन का उपनाम?', N'Nama panggilan masa kecil anda?', N'ឈ្មោះហៅក្រៅរបស់អ្នកកាលនៅកុមារភាព', N'আপনার ছোটবেলার ডাক নাম?') 
			,(14,N'Name of the first girl you had a crush on?',N'你喜欢的第一个女孩的名字？',N'你喜歡的第一個女孩的名字？',N'Nama wanita pertama yang tidak saya suka ?',N'Tên bạn gái đầu tiên của bạn?',N'บอกชื่อคนที่คุณหลงรักครั้งแรกในชีวิต?', N'उस लड़की का नाम जिसे आप पसंद करते थे?', N'Nama gadis pertama yang anda suka?', N'ឈ្មោះមនុស្សស្រីដំបូងដែលអ្នកធ្លាប់លួចស្រលាញ់?', N'প্রথম যে মেয়েটির প্রতি আপনার ক্রাশ ছিল তার নাম?' )
			,(15,N'Name of your most memorable teacher?',N'你最难忘的老师的名字？',N'你最難忘的老師的名字？',N'Nama guru kenangan saya?',N'Tên giáo viên bạn yêu quý nhất?',N'บอกชื่อคุณครูที่คุณจำได้แม่นยำที่สุด?', N'आपके सबसे यादगार शिक्षक का नाम?', N'Nama guru anda yang paling diingati?', N'ឈ្មោះគ្រូរបស់អ្នកដែលគួរឱ្យចងចាំបំផុត?', N'আপনার সবচেয়ে স্মরণীয় শিক্ষকের নাম?')
			,(16,N'Name of your first teacher?',N'你的第一位老师的名字？',N'你的第一位老師的名字？',N'Nama guru pertama saya?',N'Tên giáo viên đầu tiên của bạn?',N'บอกชื่อคุณครูคนแรกของคุณในวัยเด็ก?', N'आपके पहले शिक्षक का नाम?', N'Nama guru pertama anda?', N'ឈ្មោះគ្រូដំបូងរបស់អ្នក?', N'আপনার প্রথম শিক্ষকের নাম?')
			,(17,N'Name of your oldest cousin?',N'你年纪最大堂兄的名字？',N'你年紀最大堂兄的名字？',N'Nama sepupu tertua saya?',N'Tên anh họ lớn tuổi nhất của bạn?',N'บอกชื่อลูกพี่ลูกน้องที่มีอายุเยอะที่สุดในตระกูล?', N'आपके सबसे पुराने चचेरे भाई का नाम?', N'Nama sepupu sulung anda?', N'ឈ្មោះបងប្អូនជីដូនមួយរបស់អ្នកដែលបងជាងគេ?', N'আপনার সবচেয়ে বড় মামাতো ভাইয়ের নাম?')
	) AS t(
			QuestionID
			,QuestionNameEN
			,QuestionNameCS
			,QuestionNameCH
			,QuestionNameID
			,QuestionNameVN
			,QuestionNameTH
			,QuestionNameHI
			,QuestionNameMS
			,QuestionNameKH
			,QuestionNameBN
		)
GO