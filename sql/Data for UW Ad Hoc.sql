/****************************************************************
Data for Underwriting Promotion/Demotion Ad Hoc

Business Owner: Erin (Eiseman) Reynolds

Last Updated 08.29.2017  -- Brandon Brewer
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	L.LoanNumber
  , DATENAME(month, L.Stat60Dt)	'Stat60 Month'
  , L.Stat60Dt
  , emUW.FullNameFirstLast		'Underwriter'
  , emAUW.FullNameFirstLast		'Associate Underwriter'
  , L.SelfEmployFlg
  , [Spanish Speaking Flag]		= CASE WHEN lacd.[Spanish Speaking Flag] = 'Yes' THEN 1 ELSE 0 END
  , pb.Jumboflg
  , pb.ProductBucket
  , pd.Product
  , pd.ProductType
  , pd.ProductDescription
  , pd.ProductShortDescription
  , lpd.LoanPurpose
  , lcgd.FriendlyName 'Loan Channel'
  , iuw.[First IUW] 'First IUW Outstanding datetime'
  , firstStatus.StatusDescription 'First Status After Outstanding'
  , firstStatus.StatusDateTime	'First Status After Outstanding datetime'
  , cr.[Last Client Ready]
  
FROM QLODS..LKWD L
	LEFT JOIN QLODS..EmployeeMaster emUW ON emUW.EmployeeDimID = L.LoanUnderwriterID
	LEFT JOIN QLODS..EmployeeMaster emAUW ON emAUW.EmployeeDimID = L.AssociateUnderwriterID
	LEFT JOIN Reporting.dbo.vw_LoanAttributes_ClientDemographics lacd ON lacd.LoanNumber = L.LoanNumber
	LEFT JOIN QLODS..ProductDim pd ON pd.ProductID = L.ProductID
	LEFT JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	LEFT JOIN Reporting.dbo.vwProductBuckets pb ON pb.ProductId = L.ProductID
	LEFT JOIN QLODS..LoanChannelGroupDim lcgd ON lcgd.LoanChannelGroupID = L.LoanChannelGroupID
	OUTER APPLY(
				SELECT min(tif.StatusDateTime) 'First IUW'
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = L.LoanNumber
					AND tif.TrackingItemID = 5298 --IUW
					AND tif.StatusID = 11 --Outstanding
					AND tif.DeleteFlg = 0
				GROUP BY tif.LoanNumber
				)iuw
	OUTER APPLY(
				SELECT TOP 1 tisd.StatusDescription, tif2.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif2
					INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = tif2.StatusID
				WHERE tif2.LoanNumber = L.LoanNumber
					AND tif2.TrackingItemID = 5298 --IUW
					AND tif2.DeleteFlg = 0
					AND tif2.StatusDateTime > iuw.[First IUW]
				ORDER BY tif2.StatusDtID ASC, tif2.StatusTmID ASC
				)firstStatus
	OUTER APPLY(
				SELECT max(tif3.StatusDateTime) 'Last Client Ready'
				FROM QLODS..LKWDTrackingItemFact tif3
				WHERE tif3.LoanNumber = L.LoanNumber
					AND tif3.TrackingItemID = 5659 --TrackingItem = 5957 All Client Conditions Have Been Cleared
					AND tif3.StatusID = 67 --Cleared by Underwriter
					AND tif3.DeleteFlg = 0
				GROUP BY tif3.LoanNumber
				)cr

WHERE 1=1
	AND L.Stat60ID BETWEEN 20170600 AND 20170799
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0

ORDER BY L.Stat60ID, L.Stat60TmID
