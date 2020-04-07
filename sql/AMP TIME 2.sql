Set Transaction Isolation Level Read Uncommitted

SELECT
  L.LoanNumber 'Loan Number'
, MONTH(COALESCE(L.ClosingDt, L.FalloutDt)) 'Month Name'
, lpd.LoanPurpose
, pb.ProductBucket
, pb.Jumboflg
, [Total Time (min)]	= SUM(sf.SessionDuration)/60.0
, L.SelfEmployFlg

FROM QLODS..LKWD L 
	INNER JOIN BILoan.Loan.SessionFact sf ON sf.LoanNumber = L.LoanNumber
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	INNER JOIN Reporting..vwProductBuckets pb ON pb.ProductId = L.ProductID
	INNER JOIN BICommon.TeamMember.JobTitleBridge jtb ON jtb.CommonID = sf.AccessedByCommonId
		AND sf.StartDtID BETWEEN jtb.ActiveStartDtID AND jtb.ActiveEndDtID
	INNER JOIN BICommon.TeamMember.JobTitleDim jtdim ON jtdim.JobTitleID = jtb.JobTitleID
		AND (jtdim.JobTitle LIKE '%UW%' OR jtdim.JobTitle LIKE '%Underwrit%')
		AND jtdim.JobTitle NOT LIKE '%VP%'
		AND jtdim.JobTitle NOT LIKE '%DVP%'
		AND jtdim.JobTitle NOT LIKE '%Dir%'
		AND jtdim.JobTitle NOT LIKE '%TL%'
		AND jtdim.JobTitle NOT LIKE '%QLMS%'
		AND jtdim.JobTitle NOT LIKE '%Train%'
		AND jtdim.JobTitle NOT LIKE '%Trng%'

WHERE COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170699
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	
GROUP BY
	  L.LoanNumber
	, MONTH(COALESCE(L.ClosingDt, L.FalloutDt))
	, lpd.LoanPurpose
	, pb.ProductBucket
	, pb.Jumboflg
	, L.SelfEmployFlg