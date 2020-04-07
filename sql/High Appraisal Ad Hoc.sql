SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  L.LoanNumber
, L.Stat20Dt
, L.AppraisedValue
, L.EstimatedValue
FROM QLODS..LKWD L
	--INNER JOIN QLODS..LKWDTransFact ltf ON ltf.LoanNumber = L.LoanNumber
WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.AppraisedValue > L.EstimatedValue
	AND L.EstimatedValue > 0
	AND L.Stat20ID > 20170000
	AND L.LoanPurposeID = 7