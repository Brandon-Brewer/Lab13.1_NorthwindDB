/****************************************************************
08.01.2017 - Brandon Brewer - Rollback Report

Finds Rollback'd folders
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	L.LoanNumber
	, ltf.TransDtID 
	, ltf.TransTmID
	, sd.StatusLongDesc
	, ltf.RollBackFlg
	, ltf.PrevStatusID

FROM QLODS..LKWD L
	INNER JOIN QLODS..LKWDTransFact ltf ON ltf.LoanNumber = L.LoanNumber
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = ltf.StatusID

WHERE 1=1
	--AND L.DeleteFlg = 0
	--AND L.ReverseFlg = 0
	AND ltf.EventTypeID = 2
	AND ltf.RollBackFlg = 1
	AND ltf.StatusID = 76
	--AND ltf.LoanNumber = '3382684196'
	--AND ltf.StatusID = 199
	--AND ltf.PrevStatusID = 76
	AND ltf.TransDtID > 20170000
	
ORDER BY ltf.TransDtID DESC, ltf.TransTmID DESC             
