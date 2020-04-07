SELECT ltf.LoanNumber
FROM QLODS..LKWDTransfact ltf
WHERE 1=1
	AND ltf.TransDtID = 20170626
	AND ltf.StatusID = 181 --Stat 40
	AND ltf.PrevStatusID = 83 --Stat 35
	AND ltf.EventTypeID = 2 --Status Change
	AND ltf.RollBackFlg = 0
	AND ltf.DeleteFlg = 0
