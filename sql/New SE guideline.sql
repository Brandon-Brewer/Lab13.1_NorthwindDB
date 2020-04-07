/****************************************************************
Loans that might qualify for the new Self Employment guideline
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT DISTINCT
	L.LoanNumber

FROM QLODS..LKWD L
	CROSS APPLY(
				SELECT
					  SRD.ReasonText
					, SRDD.ReasonDetailText
				FROM QLODS..LKWDTransFact ltf
					INNER JOIN QLODS..LKWDStatusReasonGroupBridge SRGB ON SRGB.ReasonGroupID = ltf.ReasonGroupID
					INNER JOIN QLODS..LKWDStatusReasonDim SRD ON SRD.ReasonID = SRGB.ReasonID
					INNER JOIN QLODS..LKWDStatusReasonDetailDim SRDD ON SRDD.ReasonDetailID = SRGB.ReasonDetailID
				WHERE ltf.LoanNumber = L.LoanNumber
					AND ltf.StatusID = 117
					AND ltf.EventTypeId = 2
					AND ltf.RollbackFlg = 0
					AND SRDD.ReasonDetailID IN (15, 72, 76, 78)
				) sus

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.CurrentStatusID = 117 --(35)Suspended







/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	L.LoanNumber
  , ti1162.StatusID
  , ti2843.StatusID
  , ti2883.StatusID
  
FROM QLODS..LKWD L
	INNER JOIN QLODS..TrackingItemCurrentStatusFact ticsf ON ticsf.LoanNumber = L.LoanNumber
		AND ticsf.TrackingItemID IN (1162, 2843, 2883)
		AND ticsf.StatusID IN (11, 49)	
	OUTER APPLY(
				SELECT ticsf1.StatusID
				FROM QLODS..TrackingItemCurrentStatusFact ticsf1 
				WHERE ticsf1.LoanNumber = L.LoanNumber
					AND ticsf1.TrackingItemID = 1162
					AND ticsf1.StatusID IN (11, 49)
				) ti1162
	OUTER APPLY(
				SELECT ticsf2.StatusID
				FROM QLODS..TrackingItemCurrentStatusFact ticsf2 
				WHERE ticsf2.LoanNumber = L.LoanNumber
					AND ticsf2.TrackingItemID = 2843
					AND ticsf2.StatusID IN (11, 49)
				) ti2843
	OUTER APPLY(
				SELECT ticsf3.StatusID
				FROM QLODS..TrackingItemCurrentStatusFact ticsf3
				WHERE ticsf3.LoanNumber = L.LoanNumber
					AND ticsf3.TrackingItemID = 2883
					AND ticsf3.StatusID IN (11, 49)
				) ti2883

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.CurrentStatusID IN (83, 117)

