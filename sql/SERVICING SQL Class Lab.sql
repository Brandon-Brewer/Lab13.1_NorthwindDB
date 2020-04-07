Set Transaction Isolation Level Read Uncommitted

SELECT COUNT(1)
FROM SRC.ServicingMSP.LONFILE_master (NOLOCK) lon --the main servicing trans table
--WHERE lon.DELTA_FILE_BYTE 



SELECT TOP 1000 *
FROM SRC.ServicingMSP.TFRCLSUR_master (NOLOCK) fcl
WHERE 1=1 --placeholder used since servicing have a lot of logic in the where clause.  
	AND fcl.FC_SETUP_DT BETWEEN '5/1/17' AND GETDATE()
	AND fcl.LN_NO = '3224047718'
	AND fcl.end_effective_date = '12/31/2075' --This allows us to pull the most recent/current entry since it is the most effective


--DROP TABLE IF EXISTS #deleted  --look into CTE (faster than temp table, but no index and crap allowed)
SELECT COUNT(1)
--INTO #deleted
FROM SRC.ServicingMSP.DFTFILE_master (NOLOCK) dft
WHERE 1=1
	AND dft.DELTA_FILE_BYTE = 'D'
	AND dft.begin_effective_date BETWEEN '6/1/17' AND GETDATE()
	AND dft.end_effective_date = '12/31/2075' --to make sure the rows that are deleted are sill deleted



SELECT COUNT(1)
FROM SRC.ServicingMSP.LONFILE_master (NOLOCK) lon
WHERE 1=1
	AND lon.LN_PIF_DT = '6/22/2017' --paid in full date.  This field is about 98% accurate (explain in the query below)



SELECT TOP 1 * --the LeftPortifolioReversalDate is the reason for the 2% error
FROM SRC.ServicingGS.DerivedCoreMetrics (NOLOCK) gs  --Golden Source is the go-to table if the data exist there
WHERE 1=1  --below are common filters in the servicing world
	AND gs.MostRecentRecordFlag = 1
	AND gs.LoanTypeDescription <> 'PERSONAL'
	AND gs.LeftPortfolioReason IS NOT NULL


