SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

SELECT L.LoanNumber
	, CONCAT(MONTH(L.Stat21Dt),'-',YEAR(L.Stat21Dt)) 'Stat 21 Date'
	, [5331 First Cleared]			= ti5331.[first 5331 date]
	, [5648 First Completed]		= ti5648.[first 5648 date]
	, L.[1stStat35Dt]
	, [5331 to 5648 Turn Time]		= datediff(second, ti5331.[first 5331 date], ti5648.[first 5648 date])/86400.0
	, [5648 to Stat 35 Turn Time]	= datediff(second, ti5648.[first 5648 date], L.[1stStat35Dt])/86400.0
	, [5331 to Stat 35 Turn Time]	= datediff(second, ti5331.[first 5331 date], L.[1stStat35Dt])/86400.0
	, 

FROM QLODS..LKWD L
	OUTER APPLY (
					SELECT min(tif3.StatusDateTime) 'first 5331 date'
					FROM QLODS..LKWDTrackingItemFact tif3
						INNER JOIN QLODS..DateDim dd ON dd.DateID = tif3.StatusDtID
					WHERE tif3.LoanNumber = L.LoanNumber
						AND tif3.TrackingItemID = 5016 --Now TI 5331 instead TI 2148 Initial UW Review
						AND tif3.StatusID = 67 --cleared by underwriter
					GROUP BY tif3.LoanNumber
				)ti5331
	
	OUTER APPLY (
					SELECT min(tif2.StatusDateTime) 'first 5648 date'
					FROM QLODS..LKWDTrackingItemFact tif2
					WHERE tif2.LoanNumber = L.LoanNumber
						AND tif2.TrackingItemID = 5298 --TI 5648 Initial UW Review
						AND tif2.StatusID = 98 --completed
					GROUP BY tif2.LoanNumber
				)ti5648

WHERE L.LoanPurposeID <> 7
	AND L.Stat21ID > 20160400
	AND L.ReverseFlg = 0
	AND L.DeleteFlg = 0