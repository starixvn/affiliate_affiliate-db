/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" selecters="bodbAdminNet,bodbDownlineNet" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_Get_SecurityQuestions]
(
	@Language VARCHAR(20) = 'en-US'
)
RETURNS TABLE
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Login function - Core function - Security Questions

	Revisions:
		- 20200220@Percy: Initiliaze function [RedmineID: #128775]
		- 20220301@Malcolm: Add Hindi Language [RedmineId: #169142]
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
			ELSE QuestionNameEN END AS Question
	FROM (
		VALUES
			(12,N'Name of your childhood bestfriend?',N'你儿时最好的朋友的名字？',N'你兒時最好的朋友的名字？',N'Nama teman baik saya ?',N'Tên người bạn thân nhất thời niên thiếu của bạn?',N'บอกชื่อเพื่อนที่คุณสนิทที่สุดในวัยเด็ก?', N'आपके बचपन के सबसे अच्छे दोस्त का नाम?')
			,(13,N'Your childhood nickname?',N'你的童年外号？',N'你的童年外號？',N'Julukan nama waktu kecil ?',N'Tên thường gọi thời niên thiếu của bạn?',N'ชื่อเล่นของคุณในวัยเด็กคือ?', N'आपका बचपन का उपनाम?')
			,(14,N'Name of the first girl you had a crush on?',N'你喜欢的第一个女孩的名字？',N'你喜歡的第一個女孩的名字？',N'Nama wanita pertama yang tidak saya suka ?',N'Tên bạn gái đầu tiên của bạn?',N'บอกชื่อคนที่คุณหลงรักครั้งแรกในชีวิต?', N'उस लड़की का नाम जिसे आप पसंद करते थे?')
			,(15,N'Name of your most memorable teacher?',N'你最难忘的老师的名字？',N'你最難忘的老師的名字？',N'Nama guru kenangan saya?',N'Tên giáo viên bạn yêu quý nhất?',N'บอกชื่อคุณครูที่คุณจำได้แม่นยำที่สุด?', N'आपके सबसे यादगार शिक्षक का नाम?')
			,(16,N'Name of your first teacher?',N'你的第一位老师的名字？',N'你的第一位老師的名字？',N'Nama guru pertama saya?',N'Tên giáo viên đầu tiên của bạn?',N'บอกชื่อคุณครูคนแรกของคุณในวัยเด็ก?', N'आपके पहले शिक्षक का नाम?')
			,(17,N'Name of your oldest cousin?',N'你年纪最大堂兄的名字？',N'你年紀最大堂兄的名字？',N'Nama sepupu tertua saya?',N'Tên anh họ lớn tuổi nhất của bạn?',N'บอกชื่อลูกพี่ลูกน้องที่มีอายุเยอะที่สุดในตระกูล?', N'आपके सबसे पुराने चचेरे भाई का नाम?')
	) AS t(
			QuestionID
			,QuestionNameEN
			,QuestionNameCS
			,QuestionNameCH
			,QuestionNameID
			,QuestionNameVN
			,QuestionNameTH
			,QuestionNameHI
		)
GO