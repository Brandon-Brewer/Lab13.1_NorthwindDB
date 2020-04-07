SELECT 
  personloan.PersonLoanID
, personloan.LoanNumber
, personloan.PersonID
, personloan.TenantName
, person.FirstName
, person.MiddleName
, person.LastName
, person.MaritalStatus
, person.IsVeteran
, person.PreferredContactMethod
, person.Gender
, cit.CitizenshipResidencyName
, email.Email
, emp.JobTitle
, emp.CompanyName
, emp.HiredDate
, emp.MonthlyIncome
, emp.IsPrimaryEmployer
FROM SRC.Person.PersonLoan personloan WITH (NOLOCK)
	LEFT JOIN SRC.Person.Person person WITH (NOLOCK) ON person.PersonID = personloan.PersonID
	LEFT JOIN SRC.Person.CitizenshipResidencyType cit WITH (NOLOCK) ON cit.CitizenshipResidencyTypeID = person.CitizenShipResidencyTypeID
	LEFT JOIN SRC.Person.PersonContactResource contact WITH (NOLOCK) ON contact.PersonID = person.PersonID
	LEFT JOIN SRC.Person.Email email WITH (NOLOCK) ON email.ContactResourceID = contact.ContactResourceID
	LEFT JOIN SRC.Person.PersonEmployment emp WITH (NOLOCK) ON emp.PersonID = person.PersonID
WHERE personloan.LoanNumber = 3415663631