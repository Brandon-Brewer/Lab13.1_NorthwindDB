/****** Test query to pull calls Routed to Refi Hunt ******/
/****** Look at Avaya Agent Activity in BIG **************/
/** Filter: Yesterday, Carolynn Sharp
Answered NonRouted Calls
Answered NonRouted Time
Answered Routed Calls
Answered Routed Time
Available Time
Average Hold Time
Avg Answered Routed Time
Dialed Calls
Dialed External Calls
Dialed Internal Calls
Othertime
Staff Time
Total AUX time
*********************************************************/
SELECT TOP (1000) [CallFactID]
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
      ,[StartDateID]
      ,[StartTimeID]
      ,[EndDateTime]
      ,[EndDateID]
      ,[EndTimeID]
      ,[Duration]
      ,[IsTransferFlg]
      ,[IsInternalFlg]
      ,[IsObservedFlg]
      ,[JacketNumber]
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
  WHERE cf.CallEmployeeCommonID = 2022103 --Looking at Carolynn Sharp as example
	AND cf.StartDateID = 20170821 --Checking yesterday
	AND cf.CallDirectionID = 2 --Inbound
	--vdnid is -1 on nonrouted calls