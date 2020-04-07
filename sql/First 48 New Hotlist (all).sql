SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--DROP TABLE IF EXISTS #bp
SELECT 
  L.LoanNumber
, First48.First48DtID
, IUR.IURDtId
, IUR.IURday
, fso.FSODtId
, fso.FSOday
--, fso48.[48FSODtId]
--, FSO48.[48FSOday]
FROM QLODS..LKWD L
	CROSS APPLY(
				SELECT ticsf.StatusDtId 'First48DtID'
				FROM QLODS..TrackingItemCurrentStatusFact ticsf
				WHERE ticsf.LoanNumber = L.LoanNumber
					AND ticsf.TrackingItemID = 7405  --TI 8152 First48 Pilot Identifier 
					AND ticsf.StatusID = 11
				) AS First48
	
	OUTER APPLY(
				SELECT
					  dd.DateID 'IURDtId'
					, dd.DayOfWeekName 'IURday'
				FROM QLODS..LKWDTrackingItemFact tif
					INNER JOIN QLODS..DateDim dd ON dd.DateID = tif.StatusDtID
					INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = tif.StatusUserID
				WHERE tif.LoanNumber = L.LoanNumber
						AND tif.TrackingItemID = 5298 --TI 5648 Initial Underwrite Review
						AND tif.StatusID = 98 --Completed
						AND tif.DeleteFlg = 0
						AND em.OpsTeamLeader LIKE '%Barb%'
				) AS IUR

	OUTER APPLY(
				SELECT
					  dd2.DateID 'FSODtId'
					, dd2.DayOfWeekName 'FSOday'
				FROM QLODS..LKWDTrackingItemFact tif2
					INNER JOIN QLODS..DateDim dd2 ON dd2.DateID = tif2.StatusDtID
					INNER JOIN QLODS..EmployeeMaster em2 ON em2.EmployeeDimID = tif2.StatusUserID
				WHERE tif2.LoanNumber = L.LoanNumber
						AND tif2.TrackingItemID = 6195 --TI 6449 Pre Final Sign Off Review Needed
						AND tif2.StatusID = 58 --Completed/Confirmed
						AND tif2.DeleteFlg = 0
						AND em2.OpsTeamLeader LIKE '%Barb%'
				) AS FSO	
	
	--OUTER APPLY(
	--			SELECT
	--				  dd3.DateID '48FSODtId'
	--				, dd3.DayOfWeekName '48FSOday'
	--			FROM QLODS..LKWDTrackingItemFact tif3
	--				INNER JOIN QLODS..DateDim dd3 ON dd3.DateID = tif3.StatusDtID
	--				INNER JOIN QLODS..EmployeeMaster em3 ON em3.EmployeeDimID = tif3.StatusUserID
	--			WHERE tif3.LoanNumber = L.LoanNumber
	--					AND tif3.TrackingItemID = 6195 --TI 6449 Pre Final Sign Off Review Needed
	--					AND tif3.StatusID = 58 --Completed/Confirmed
	--					AND tif3.DeleteFlg = 0
	--					AND em3.OpsTeamLeader LIKE '%Barb%'
	--			) AS FSO48
			
							
WHERE 1=1 
	AND L.Stat21ID > 20170300
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

ORDER BY First48.First48DtID
	