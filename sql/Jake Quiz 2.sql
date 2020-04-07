SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT L.LoanNumber
	, CONVERT(date,L.Stat33DT) AS 'Day Suspended'
	, DATEDIFF(second,L.Stat33Dt, GETDATE())/86400.0 AS 'Days In Suspense'
	, CONVERT(date,DATEADD(day,30,Stat33DT)) '30 day date'
	, CONVERT(date,COALESCE(L.Stat35Dt, L.Stat21Dt)) AS '35 or 21 Date'
	, CASE WHEN CONVERT(date,COALESCE(L.Stat35Dt, L.Stat21Dt)) = CONVERT(date,L.Stat35Dt) THEN 1 ELSE 0 END AS '35DateFlg'

FROM QLODS..LKWD L
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = L.CurrentStatusID

WHERE sd.StatusKey = 33
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

