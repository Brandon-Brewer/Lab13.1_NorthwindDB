Set Transaction Isolation Level Read Uncommitted

/**********
QUESTION 1
**********/
SELECT 
  L.LoanNumber
, lpd.LoanPurpose
, lcgd.FriendlyName 'Loan Channel'
, sd.StatusFullDesc

FROM QLODS..LKWD L
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	INNER JOIN QLODS..LoanChannelGroupDim lcgd ON lcgd.LoanChannelGroupID = L.LoanChannelGroupID
	INNER JOIN QLODS..StatusDim sd On sd.StatusID = L.CurrentStatusID
WHERE sd.StatusKey = 35
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0



/**********
QUESTION 2 a & b
**********/
SELECT 
--  ltf.LoanNumber
--, ltf.TransDateTime
--, em.JobTitle
  em.JobTitle
, count(*) 'Count of Suspenses'

FROM QLODS..LKWDTransFact ltf
	INNER JOIN QLODS..EventTypeDim etd ON etd.EventTypeID = ltf.EventTypeID
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = ltf.StatusID
	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = ltf.StatusUserID
WHERE ltf.TransDtID BETWEEN 20170500 AND 20170599
	AND etd.EventTypeID = 2
	AND sd.StatusKey = 33
	AND ltf.DeleteFlg = 0
	AND ltf.Rollbackflg = 0
GROUP BY em.JobTitle
ORDER BY 2 DESC

	

/**********
QUESTION 3
**********/
SELECT 
--  L.LoanNumber
--, L.Stat21Dt
--, L.Stat41Dt
  lpd.LoanPurpose
, [AVG 21 to 41 TT]		= AVG(DATEDIFF(MINUTE, L.Stat21Dt, L.Stat41Dt)/(60.0*24))

FROM QLODS..LKWD L
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID

WHERE L.ClosingID BETWEEN 20170500 AND 20170599
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
GROUP BY lpd.LoanPurpose
ORDER BY 2 DESC