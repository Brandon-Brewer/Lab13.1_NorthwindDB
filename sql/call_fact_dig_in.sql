/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [JacketNumber]
	  ,[StartDateID]
	  ,em.FullNameFirstLast
	  ,em.JobTitle
	  ,[CallFactID]
      ,[CallID]
      ,[UCID]
      ,[CallEmployeeID]
      ,[CallEmployeeCommonID]
      ,[CallCapstoneEmployeeID]
      ,[CallFromPhoneNumberID]
      ,[CallToPhoneNumberID]
      ,[CallDirectionID]
      ,[CallOutComeID]
      ,[StationID]
      ,[VDNID]
      ,[StartDateTime]
      ,[StartTimeID]
      ,[EndDateTime]
      ,[EndDateID]
      ,[EndTimeID]
      ,[Duration]
      ,[IsTransferFlg]
      ,[IsInternalFlg]
      ,[IsObservedFlg]
      ,[LastStatusID]
      ,[GCID]
      ,[InstanceID]
      ,[MktgValidFlg]
      ,[LeadRecapIncludeFlg]
      ,[BranchID]
      ,[LeadAgeSeconds]
      ,[AllocatedFlg]
      ,[ObserverEmployeeID]
      ,[ObserverCommonID]
      ,[ObserverCapstoneEmployeeID]
      ,[ObserverActionID]
      ,[SRCID]
      ,[InsertDtDW]
      ,[LastUpdateDtDW]
      ,[LastUpdateByDW]
      ,[IsSystemGenerated]
      ,[CallMadeBySystemDimID]
      ,[CallCampaignDimID]
      ,[LoanPoolHistoryFactID]
      ,[DialMethodDimId]
      ,[CallMethodDimId]
      ,[CtiCallMethodDimID]
      ,[CallerId]
  FROM [BICallData].[dbo].[CallFact] cf
	LEFT JOIN QLODS.dbo.EmployeeMaster em ON em.CommonID = cf.CallEmployeeCommonID  
  WHERE 1=1
	AND CallFromPhoneNumberID = 2022716203
	AND StartDateID > 20170700

  ORDER BY StartDateTime DESC



  SELECT *
  FROM Ultipro..UltiproEmployee
  WHERE WorkPhoneExtension = '71376'


  SELECT *
  FROM BICallData..VDNDim
  WHERE VDN = 26014

  --SELECT *
  --FROM BICallData..CallOutcomeDim
  --WHERE CallOutcomeID = 27

  --SELECT *
  --FROM BICallData..SystemSourceDim
  --WHERE SystemSourceDimID = 2

  SELECT *
  FROM BICallData..VWCallMadeBySystem
  WHERE systemsourcedimID = 2
  