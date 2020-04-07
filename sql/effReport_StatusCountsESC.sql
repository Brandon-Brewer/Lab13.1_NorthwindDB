DECLARE @StartDtID AS INT = 20171204
DECLARE @StartDtTime AS datetime 

SELECT
  em.CommonID      
, em.FullNameFirstLast
, tif.StatusDtID
, COUNT(*) 'StatusCount'
--, COUNT(DISTINCT CASE WHEN tif.StatusID <> 39 THEN tif.LoanNumber END) 'DistinctLoans'
--, COUNT(CASE WHEN TIF.StatusID <> 39 THEN 1 END) 'ConfirmedCalls'    
, COUNT(tif2.StatusID) 'ESC SC'
, COUNT(ome.LoanNumber) 'OME SC'
, COUNT(CASE WHEN ome.LoanNumber IS NULL AND tif2.LoanNumber IS NULL THEN 1 END) 'Non-OME SC'

FROM QLODS.dbo.LKWDTrackingItemFact tif
	LEFT JOIN QLODS..EmployeeMaster em ON tif.StatusUserID = em.EmployeeDimID
	LEFT JOIN QLODS.dbo.LKWDTrackingItemDim id on tif.TrackingItemID = id.TrackingItemID
	LEFT JOIN QLODS.dbo.LKWDTrackingItemStatusDim sd on tif.StatusID = sd.StatusID
	LEFT JOIN QLODS.dbo.LKWD lk ON tif.LoanNumber = lk.LoanNumber
	LEFT JOIN QLODS.dbo.LKWDTrackingItemFact tif2 ON tif2.LoanNumber = lk.LoanNumber
		AND tif2.TrackingItemID = 7125
		AND tif2.StatusID = 25
		AND tif2.StatusDateTime <= tif.StatusDateTime
	LEFT JOIN Reporting.dbo.vw_OME ome ON ome.LoanNumber = lk.LoanNumber
		AND tif.StatusDateTime BETWEEN ome.StartDateTime AND ome.EndStatusDateTime
		AND tif2.LoanNumber IS NULL

WHERE ID.TrackingItem IN
                        ('1538'                                                --ICC
                        ,'2128'                                                --Follow Up Call to Client
                        ,'2132'                                                --Post Suspense Call --not used in qslice
                        ,'2146'                                                --Final Goals Goal
                        ,'2549'                                                --Final Goals Call - Purchase                                        
                        ,'3062'                                                --Terms and Structure Call
                        ,'4917'                                                --Initial Call to Seller's Realtor
                        ,'4919'                                                --Initial Call to Client's Realtor
                        ,'4920'                                                --Follow up Call to seller's realtor
                        ,'4921'                                                --Follow up call to client's realtor
                        ,'5266'                                                --folder received ICC
                        ,'5267'                                                --folder received follow up call to client
                        ,'5501'                                                --Terms and structure have changed -- ccs to communicate
                        ,'6000'                                                --M1 ICC
                        ,'6001'                                                --m1 Client follow up call                             
                        ,'6002'                                                --M1st Client Call -- Approved Waiting for Property
                        ,'6042'                                                --FR: Inbound Client Call
                        ,'6057'                                                --M1st Realtor Initial Call
                        ,'6058'                                                --M1st Realtor Follow up call
                        ,'6067'                                                --M1st Realtor Call -- Approved waiting for property
                        ,'6856'                                                --MyQL Chat Communication                        
                        )
	AND tif.StatusID IN 
						(39 
						,98 
						,58 
						,25 
						,572
						,571
						,573
						,42 
						,43 
						,41 
						,321
						,325
						,324
						,322
						,323
						,326
						,56
						)
                                                       
	AND tif.StatusDtID = @StartDtID
	AND tif.DeleteFlg = 0
	AND lk.ReverseFlg = 0 
	AND tif.StatusUserID <> 1
	AND em.OpsDirector IN ('Jason Halliday', 'Ryan Meyers')

GROUP BY em.CommonID, em.FullNameFirstLast, tif.StatusDtID

ORDER BY em.FullNameFirstLast