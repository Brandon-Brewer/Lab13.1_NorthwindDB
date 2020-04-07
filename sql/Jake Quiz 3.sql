SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT L.LoanNumber
	, sd.StatusFullDesc 'Current Status'
	, L.CurrStatDt 'Current Status Date' --this will be the current 41 time used for the first21 to current 41 TT.  See datediff below.
	, First21.TransDateTime 'First21DtTm'
	, First21.TransDtID 'First21Dt'
	, First21.TransTmID 'First21time'
	, DATEDIFF(day, First21.TransDateTime, L.CurrStatDt) 'First21 to Current41'
	, First21.StatusUserID
	, em.FullNameFirstLast
	, CASE WHEN suspenses.[Number of Suspenses] IS NULL THEN 0 ELSE suspenses.[Number of Suspenses] END AS 'Number of Suspenses'
			

FROM QLODS..LKWD L 
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = L.CurrentStatusID

	OUTER APPLY (
					SELECT COUNT(*) AS 'Number of Suspenses'
					FROM QLODS..LKWDTransFact ltf 
					WHERE ltf.LoanNumber = L.LoanNumber
						and ltf.StatusID = 117 --the statusID for Suspense (stat 33)
						and ltf.EventTypeID = 2  --when the status changes
						and ltf.Deleteflg = 0
					GROUP BY ltf.LoanNumber
				) suspenses

	
	OUTER APPLY (
					SELECT TOP 1 TransDtID, TransTmID, TransDateTime, StatusUserID
					FROM QLODS..LKWDTransFact ltf
					WHERE ltf.LoanNumber = L.LoanNumber
						and ltf.StatusID = 76 --the statusID for Folder (stat 21)
						and ltf.EventTypeID = 2 --when the status changes
						and ltf.Deleteflg = 0
					ORDER BY ltf.TransDtID ASC
							, ltf.TransTmID ASC
				) First21

	LEFT JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = First21.StatusUserID
							

WHERE sd.StatusKey = 41 --looking at loans in FSO (stat 41)
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

