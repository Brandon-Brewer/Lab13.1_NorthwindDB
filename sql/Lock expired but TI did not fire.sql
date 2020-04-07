/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	L.LoanNumber
  , L.Stat21Dt
  , L.LockExpireID

FROM QLODS..LKWD L
	LEFT JOIN QLODS..LKWDTrackingItemFact

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	
