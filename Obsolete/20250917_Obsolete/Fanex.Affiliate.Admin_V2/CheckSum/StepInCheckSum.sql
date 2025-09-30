/*
Step 1: Get affiliate member/player list 
	- SP [Aff_GetMembers]
Step 2: Get check sum data from IBC system 
	- Original SP [Aff_PlayersWinlostByProductSel] & [Aff_PlayersFundingSel] (db052,db056)
	- SP [Aff_CheckSum_WinlostByProduct]
Step 3: Get check sum data from AFF system 
	- SP [Task_CheckSum_WinlostByProduct] (affiliate db)
*/