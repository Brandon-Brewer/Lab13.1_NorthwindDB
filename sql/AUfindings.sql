Set Transaction Isolation Level Read Uncommitted

SELECT 
  L.LoanNumber
, rf.*

FROM QLODS..LKWD L
	INNER JOIN QLODS..LKWDRocketFinding rf ON rf.LoanNumber = L.LoanNumber

WHERE 1=1
	AND L.CurrentStatusID IN (83, 117)
	AND L.CLTV <= 80
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND rf.AUEngineID = 4 --LP