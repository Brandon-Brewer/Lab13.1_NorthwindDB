Set Transaction Isolation Level Read Uncommitted

Select TIF.LoanNumber
, TIF.TrackingSeqNum
, TIF.StatusSeqNum
, TID.TrackingItemDesc
, TIF.TrackingItemID
, TIF.StatusDateTime
, TISD.StatusDescription
, EM.FullNameFirstLast
, EM.JobTitle
, TIF.DeleteFlg
FROM QLODS..LKWDTrackingItemFact TIF
       Inner Join QLODS..LKWDTrackingItemDim TID ON TID.TrackingItemID = TIF.TrackingItemID
       Inner Join QLODS..LKWDTrackingItemStatusDim TISD ON TISD.StatusID = TIF.StatusID
       Inner Join QLODS..LKWD L ON L.LoanNumber = TIF.LoanNumber
       Inner Join QLODS..EmployeeMaster EM ON EM.EmployeeDimID = TIF.StatusUserID
              Where TID.TrackingItem = 5957 -- Change to preferred tracking item
                     --AND TIF.DeleteFlg = 0
                     AND L.DeleteFlg = 0
                     AND L.ReverseFlg = 0
                     AND L.ClosingID BETWEEN 20170500 AND 20170599
                           Order By TIF.LoanNumber, TIF.TrackingSeqNum, TIF.StatusSeqNum