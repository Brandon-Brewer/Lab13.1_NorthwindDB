/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	  L.LoanNumber
	, sd.StatusFullDesc
	, DATEDIFF(DAY, L.Stat21Dt, GETDATE()) 'Days In Process'

FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = L.CurrentStatusID

WHERE 1=1
	AND L.LoanPurposeID = 41 --41 New Construction 8:Construction
	AND sd.StatusKey BETWEEN 20 AND 41
	AND DATEDIFF(DAY, L.Stat21Dt, GETDATE()) > 59
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

ORDER BY DATEDIFF(DAY, L.Stat21Dt, GETDATE()) DESC



