/****************************************************************
Lab 13.1: Northwind DB
Task: Practice writing SQL statements on the Northwind database.
By: Brandon Brewer
Date: 2020.04.06
****************************************************************/

--Query #1
--Select all the records from the "Customers" table.
SELECT *
FROM Northwind.dbo.Customers


--Query #2
--Get distinct countries from the Customers table.
SELECT DISTINCT cus.Country
FROM Northwind.dbo.Customers cus


--Query #3
--Get all the records from the table Customers where the Customer’s ID starts with “BL”.
SELECT *
FROM Northwind.dbo.Customers cus
WHERE cus.CustomerID LIKE 'BL%'


--Query #4
--Get the first 100 records of the orders table.
SELECT TOP 100 *
FROM Northwind.dbo.Orders


--Query #5
--Get all customers that live in the postal codes 1010, 3012, 12209, and 05023.
SELECT *
FROM Northwind.dbo.Customers cus
WHERE cus.PostalCode IN ('1010', '3012', '12209', '05023')


--Query #6
--Get all orders where the ShipRegion is not equal to NULL.SELECT *
FROM Northwind.dbo.Orders ord
WHERE ord.ShipRegion IS NOT NULL


--Query #7
--Get all customers ordered by the country, then by the city.
SELECT *
FROM Northwind.dbo.Customers cus
ORDER BY cus.Country, cus.City


--Query #8
--Add a new customer to the customers table. You can use whatever values.INSERT INTO Northwind.dbo.Customers(CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Fax)
VALUES('AAAAA', 'QL', 'Brandon Brewer', 'Software Engineer', '123 Main', 'Detroit', NULL, '48127', 'USA', '(313) 555-5555', NULL)

SELECT * 
FROM Northwind.dbo.Customers


--Query #9
--Update all ShipRegion to the value ‘EuroZone’ in the Orders table, where the ShipCountry is equal to France.UPDATE Northwind.dbo.Orders SET ShipRegion = 'EuroZone' WHERE ShipCountry = 'France'

SELECT *
FROM Northwind.dbo.Orders ord
WHERE ord.ShipCountry = 'France'


--Query #10
--Delete all orders from OrderDetails that have quantity of 1.
DELETE FROM Northwind.dbo.[Order Details] WHERE Quantity = 1

SELECT *
FROM Northwind.dbo.[Order Details] od
WHERE od.Quantity = 1


--Query #11
--Calculate the average, max, and min of the quantity at the orderdetails table.
SELECT
  AVG(od.Quantity) 'Average Quantity'
, MAX(od.Quantity) 'MAX Quantity'
, MIN(od.Quantity) 'MIN Quantity'
FROM Northwind.dbo.[Order Details] od


--Query #12
--Calculate the average, max, and min of the quantity at the orderdetails table, grouped by the orderid.
SELECT
  od.OrderID
, AVG(od.Quantity) 'Average Quantity'
, MAX(od.Quantity) 'MAX Quantity'
, MIN(od.Quantity) 'MIN Quantity'
FROM Northwind.dbo.[Order Details] od
GROUP BY od.OrderID


--Query #13
--Find the CustomerID that placed order 10290 (Orders table).SELECT ord.CustomerID
FROM Northwind.dbo.Orders ord
WHERE ord.OrderID = 10290


--Query #14
--Do an inner join, left join, right join on orders and customers tables.
SELECT *
FROM Northwind.dbo.Orders ord
	INNER JOIN Northwind.dbo.Customers cus ON cus.CustomerID = ord.CustomerID

SELECT *
FROM Northwind.dbo.Orders ord
	LEFT JOIN Northwind.dbo.Customers cus ON cus.CustomerID = ord.CustomerID

SELECT *
FROM Northwind.dbo.Orders ord
	RIGHT JOIN Northwind.dbo.Customers cus ON cus.CustomerID = ord.CustomerID


--Query #15
--Use a join to get the ship city and ship country of all the orders which are associated with an employee who is in London.
SELECT
  ord.OrderID
, ord.ShipCity
, ord.ShipCountry
FROM Northwind.dbo.Orders ord
	INNER JOIN Northwind.dbo.Employees em ON em.EmployeeID = ord.EmployeeID
WHERE em.City = 'London'


--Query #16
--Use a join to get the ship name of all orders that include a discontinued product. (See Orders, OrderDetails, and Products. 1 means discontinued.)SELECT
  ord.OrderID
, od.ProductID
, ord.ShipName
FROM Northwind.dbo.Orders ord
	LEFT JOIN Northwind.dbo.[Order Details] od ON od.OrderID = ord.OrderID
	LEFT JOIN Northwind.dbo.Products pro ON pro.ProductID = od.ProductID
WHERE pro.Discontinued = 1


--Query #17
--Get employees’ firstname for all employees who report to no one.SELECT em.FirstName
FROM Northwind.dbo.Employees em
WHERE em.ReportsTo IS NULL


--Query #18
--Get employees’ firstname for all employees who report to Andrew.
SELECT em.FirstName
FROM Northwind.dbo.Employees em
	INNER JOIN Northwind.dbo.Employees leader ON leader.EmployeeID = em.ReportsTo
		AND leader.FirstName = 'Andrew'


--Extended Query #1
--Select all records from the customers table.
SELECT *
FROM Northwind.dbo.Customers


--Extended Query #2
--Find all customers living in London or Paris.
SELECT *
FROM Northwind.dbo.Customers cus
WHERE cus.City IN ('London', 'Paris')


--Extended Query #3
--Make a list of cities where customers are coming from. The list should not have any duplicates or nulls.
SELECT DISTINCT cus.City
FROM Northwind.dbo.Customers cus
WHERE cus.City IS NOT NULL


--Extended Query #4
--Show a sorted list of employees’ first names.
SELECT em.FirstName
FROM Northwind.dbo.Employees em
ORDER BY em.FirstName


--Extended Query #5
--Find the average of employees’ salaries.
--Salary data is not in the database.
SELECT *
FROM Northwind.dbo.Employees


--Extended Query #6
--Show the first name and last name for the employee with the highest salary.
--Salary data is not in the database.
SELECT *
FROM Northwind.dbo.Employees


--Extended Query #7
--Find a list of all employees who have a BA.SELECT *
FROM Northwind.dbo.Employees em
WHERE 1=1
	AND (em.Notes LIKE '%BA in%'
	OR em.Notes LIKE '%BA degree%')


--Extended Query #8
--Find total for each order.
SELECT
  ord.OrderID
, [OrderTotal] = ROUND(SUM(od.Quantity * od.UnitPrice * (1 - od.Discount)), 2)
FROM Northwind.dbo.Orders ord
	LEFT JOIN Northwind.dbo.[Order Details] od ON od.OrderID = ord.OrderID
GROUP BY ord.OrderID


--Extended Query #9
--Get a list of all employees who got hired between 1/1/1994 and today.
SELECT *
FROM Northwind.dbo.Employees em
WHERE em.HireDate > '1994-01-01'


--Extended Query #10
--Find how long employees have been working for Northwind (in years!)SELECT
  em.FirstName
, em.LastName
, em.HireDate
, [Seniority (years)] = DATEDIFF(day, em.HireDate, GETDATE()) / 365.0
FROM Northwind.dbo.Employees em


--Extended Query #11
--Get a list of all products sorted by quantity (ascending and descending order).
SELECT 
  p.ProductName
, p.UnitsInStock
FROM Northwind.dbo.Products p
ORDER BY p.UnitsInStock

SELECT 
  p.ProductName
, p.UnitsInStock
FROM Northwind.dbo.Products p
ORDER BY p.UnitsInStock DESC


--Extended Query #12
--Find all products that are low on stock (quantity less than 6)SELECT 
  p.ProductName
, p.UnitsInStock
FROM Northwind.dbo.Products p
WHERE p.UnitsInStock < 6


--Extended Query #13
--Find a list of all discontinued products.
SELECT pro.ProductName
FROM Northwind.dbo.Products pro
WHERE pro.Discontinued = 1


--Extended Query #14
--Find a list of all products that have Tofu in them.
SELECT pro.ProductName
FROM Northwind.dbo.Products pro
WHERE pro.ProductName LIKE '%tofu%'


--Extended Query #15
--Find the product that has the highest unit price.
SELECT TOP 1
  pro.ProductName
, pro.UnitPrice
FROM Northwind.dbo.Products pro
ORDER BY pro.UnitPrice DESC


--Extended Query #16
--Get a list of all employees who got hired after 1/1/1993.SELECT *
FROM Northwind.dbo.Employees em
WHERE em.HireDate > '1993-01-01'


--Extended Query #17
--Get all employees who have title : “Ms.” And “Mrs.”
SELECT *
FROM Northwind.dbo.Employees em
WHERE em.TitleOfCourtesy IN ('Ms.', 'Mrs.')


--Extended Query #18
--Get all employees who have a Home phone number that has area code 206.
SELECT *
FROM Northwind.dbo.Employees em
WHERE em.HomePhone LIKE '(206)%'