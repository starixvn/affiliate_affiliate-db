/*<info serverAlias="DBCUST-bodb_Licensee" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Creator: 20230522@Malcolm
	DB: DBCUST.bodb_Licensee
	Task: Rest pass [RedmineId : #180311]
*/

UPDATE Users
	set UserSalt = 'dT/cGDf7hCRm8A4daw==', UserPwd = '0C2C7CD92D6DD8D6C1BB57801EF7C3D11ADA20A8'
WHERE UserId = '11463' -- starixsas, old : dT/cGDf7hCRm8A4daw==, 7ADF099EE1D536D99A8F217C3CDFEA5D4160C005

UPDATE Users
	set UserSalt = 'LbkTcT4UY+A7eVb0FA==', UserPwd = 'F70F0A4195549221384D58543FEDBF4685E2526E'
WHERE UserId = '9374' --StarixQC1 old LbkTcT4UY+A7eVb0FA==, 138D06195904FEE1B8CF030822EC0BDAE6058C86