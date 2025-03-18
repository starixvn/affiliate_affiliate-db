/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_SpecificRedirectDomain]()
RETURNS TABLE
AS

/*
	Created: 20250226@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: 12B - RedirectPage for specific domain of the Affiliate

	Revisions:
		- 20250226@Sally: Initialize Function [RedmineID: #212201]
		- 20250304@Sally: Add specific Links 12BETAFF16416 [RedmineID: #219049]
        - 20250304@Sally: Remove redirect domain 12BETAFF16416 [RedmineID: #219049]
        - 20250306@Lewis: Add 12BETAFF16450 [RedmineID: #219200]
        - 20250311@Lewis: Add new specific link [RedmineID: #219613]
        - 20250313@Lewis: Add 12BETAFF16494 [RedmineID: #219984]
        - 20250318@Lewis: Add new specific link [RedmineID: #220465]
*/

RETURN
	SELECT AffDomain, AffUsername, RedirectDomain
	FROM
	( VALUES ('join.best5689.com', '12BETAFF16000', 'https://www.620elv.com/')
		,('join.best5689.com', '12BETAFF16186', 'https://www.620elv.com/')
		,('join.best5689.com', '12BETAFF16097', 'https://www.620elv.com/')
        ,('join.best5689.com', '12BETAFF16096', 'https://www.620elv.com/')

		,('go.12real.com', '12BETAFF16105','https://www.nen77.com/')
		,('go.12real.com', '12BETAFF16204','https://www.nen77.com/')
		,('go.12real.com', '12BETAFF16205','https://www.nen77.com/')
        ,('go.5689fun.com', '12BETAFF15932','https://www.12kaixin.com/')
        ,('go.5689fun.com', '12BETAFF16325','https://www.12amber.com/')
        ,('go.6789sutzo.com', '12BETAFF16326','https://www.12amethyst.com/')

        ,('12aff.best5689.com', '12BETAFF15932','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF130','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF16311','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF16314','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF16225','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF14617','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF13902','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF16313','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF15775','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF16214','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF13506','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF13065','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF7782','https://www.12bfacai.com/')
        ,('12aff.best5689.com', '12BETAFF16050','https://www.12bfacai.com/')

        ,('go.9012ijk.com', '12BETAFF16343','https://www.12amethyst.com/')
        ,('go.12fifa18.com', '12BETAFF16105','https://www.12crystal.com/')
        ,('go.sbc31.com', '12BETAFF16344','https://www.12amberclub.com/')
        ,('go.tha88.com', '12BETAFF16342','https://www.12bola.com/')
        ,('go.apa56.com', '12BETAFF16342','https://www.bola112.com/')
        ,('go.12qiuball.com', '12BETAFF16341','https://www.12vndb.com/')
        ,('go.all2356.com', '12BETAFF16386','https://www.12bwinb.com/')
        ,('go.amo38.com', '12BETAFF16386','https://www.12bplay.com/')
        ,('go.12winball.com', '12BETAFF16007','https://www.12bbe.com/')
        ,('goto.12bsprt1.com', '12BETAFF16338','https://www.12bsaff1.com/')
        ,('goto.12bsprt2.com', '12BETAFF16336','https://www.12bsaff2.com/')
        ,('goto.12bsprt3.com', '12BETAFF16337','https://www.12bsaff3.com/')

		,('goto.12binrlink1.com', '12BETAFF16416','https://www.12binr3.com/')
		,('goto.12binrlink2.com', '12BETAFF16450','https://www.12binr4.com/')
		,('goto.12binlink1.com', '12BETAFF16472','https://www.12befun.com/')
		,('goto.12bvnlink1.com', '12BETAFF16479','https://www.12belucky.com/')
		,('goto.12bthlink1.com', '12BETAFF16478','https://www.12bigwin.com/')
		--,('goto.12bvnlink1.com', '12BETAFF16473','https://www.12fun.com/')
		,('goto.12bmylink1.com', '12BETAFF16475','https://www.12befun2.com/')
		,('goto.12binlink1.com', '12BETAFF16476','https://www.12besuper.com/')
		,('goto.12bthlink1.com', '12BETAFF16477','https://www.12belegend.com/')
		,('goto.12binlink1.com', '12BETAFF16454','https://www.12beking.com/')
		,('goto.12bthlink1.com', '12BETAFF16455','https://www.12befair.com/')
		,('goto.12bvnlink1.com', '12BETAFF16456','https://www.12betheone.com/')
		,('goto.12bmylink1.com', '12BETAFF16457','https://www.12beplay.com/')
		,('goto.12bvnlink1.com', '12BETAFF16480','https://www.12becool.com/')
		,('goto.12bmylink1.com', '12BETAFF16481','https://www.12befun1.com/')
		,('goto.12binlink1.com', '12BETAFF16482','https://www.12be365.com/')
		,('goto.12bthlink1.com', '12BETAFF16483','https://www.12bejackpot.com/')
		,('goto.2356all.com', '12BETAFF16494','https://www.sukan12.com/')
		,('goto.elv520.com', '12BETAFF16492','https://www.12vex.com/')

		,('goto.12bmylink1.com', '12BETAFF16342','https://www.12befun2.com/')
		,('goto.12bvnlink1.com ', '12BETAFF16473','https://www.12kix.com/')
	) AS t(AffDomain, AffUsername, RedirectDomain)
		
GO
