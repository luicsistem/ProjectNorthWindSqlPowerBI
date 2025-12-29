--Resumen de vistas
--Tipo	Vista
--Fact	vw_FactSales
--Dim	vw_DimCustomers
--Dim	vw_DimProducts
--Dim	vw_DimEmployees
--Dim	vw_DimShippers
--Dim	vw_DimDate


-- SQL – Creación de vw_DimCustomers

CREATE OR ALTER VIEW dbo.vw_DimCustomers
AS
SELECT
    c.CustomerID,
    c.CompanyName,
    c.ContactName,
    c.Country,
    c.City,
    ISNULL(c.Region, 'N/A') AS Region,
    c.PostalCode
FROM Customers c;
GO

-- SQL – Creación de vw_DimProducts

CREATE OR ALTER VIEW dbo.vw_DimProducts
AS
SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    s.CompanyName AS SupplierName,
    s.Country AS SupplierCountry,
    p.UnitPrice,
    p.Discontinued
FROM Products p
INNER JOIN Categories c
    ON p.CategoryID = c.CategoryID
INNER JOIN Suppliers s
    ON p.SupplierID = s.SupplierID;
GO

--  SQL – Creación de vw_DimEmployees

CREATE OR ALTER VIEW dbo.vw_DimEmployees
AS
SELECT
    e.EmployeeID,
    e.FirstName + ' ' + e.LastName AS FullName,
    e.Title,
    e.HireDate,
    e.Country,
    e.City,
    e.ReportsTo,
    m.FirstName + ' ' + m.LastName AS ManagerName
FROM Employees e
LEFT JOIN Employees m
    ON e.ReportsTo = m.EmployeeID;
GO

-- --  SQL – Creación de vw_DimShippers

CREATE OR ALTER VIEW dbo.vw_DimShippers
AS
SELECT
    s.ShipperID,
    s.CompanyName
FROM Shippers s;
GO

-- SQL – Creación de vw_DimDate (Minimalista)
-- vw_DimDate – versión correcta (sin recursión)
CREATE OR ALTER VIEW dbo.vw_DimDate
AS
WITH DateRange AS (
    SELECT
        MIN(CAST(OrderDate AS date)) AS StartDate,
        MAX(CAST(OrderDate AS date)) AS EndDate
    FROM Orders
),
Numbers AS (
    SELECT number
    FROM master..spt_values
    WHERE type = 'P'
)
SELECT
    DATEADD(DAY, n.number, dr.StartDate) AS [Date],
    YEAR(DATEADD(DAY, n.number, dr.StartDate)) AS [Year],
    MONTH(DATEADD(DAY, n.number, dr.StartDate)) AS [Month],
    DATENAME(MONTH, DATEADD(DAY, n.number, dr.StartDate)) AS MonthName,
    CONCAT(
        YEAR(DATEADD(DAY, n.number, dr.StartDate)),
        RIGHT('0' + CAST(MONTH(DATEADD(DAY, n.number, dr.StartDate)) AS varchar(2)), 2)
    ) AS YearMonth,
    DATEPART(QUARTER, DATEADD(DAY, n.number, dr.StartDate)) AS Quarter
FROM DateRange dr
JOIN Numbers n
    ON DATEADD(DAY, n.number, dr.StartDate) <= dr.EndDate;
GO

-- *****************************************************
-- SQL – vw_DimDate Enterprise-grade

CREATE OR ALTER VIEW dbo.vw_DimDate
AS
WITH DateRange AS (
    SELECT
        MIN(CAST(OrderDate AS date)) AS StartDate,
        MAX(CAST(OrderDate AS date)) AS EndDate
    FROM Orders
),
Numbers AS (
    SELECT number
    FROM master..spt_values
    WHERE type = 'P'
),
Calendar AS (
    SELECT
        DATEADD(DAY, n.number, dr.StartDate) AS [Date]
    FROM DateRange dr
    JOIN Numbers n
        ON DATEADD(DAY, n.number, dr.StartDate) <= dr.EndDate
)
SELECT
    [Date],

    -- Año / Mes / Trimestre
    YEAR([Date]) AS [Year],
    MONTH([Date]) AS MonthNumber,
    DATENAME(MONTH, [Date]) AS MonthName,
    CONCAT(
        YEAR([Date]),
        RIGHT('0' + CAST(MONTH([Date]) AS varchar(2)), 2)
    ) AS YearMonth,
    DATEPART(QUARTER, [Date]) AS Quarter,

    -- Orden correcto en Power BI
    YEAR([Date]) * 100 + MONTH([Date]) AS MonthYearSort,

    -- Flags dinámicos
    CASE WHEN [Date] = CAST(GETDATE() AS date) THEN 1 ELSE 0 END AS IsToday,

    CASE 
        WHEN YEAR([Date]) = YEAR(GETDATE()) THEN 1 
        ELSE 0 
    END AS IsCurrentYear,

    CASE 
        WHEN YEAR([Date]) = YEAR(GETDATE())
         AND MONTH([Date]) = MONTH(GETDATE()) THEN 1
        ELSE 0
    END AS IsCurrentMonth,

    CASE 
        WHEN YEAR([Date]) = YEAR(GETDATE())
         AND DATEPART(QUARTER, [Date]) = DATEPART(QUARTER, GETDATE()) THEN 1
        ELSE 0
    END AS IsCurrentQuarter,

    CASE 
        WHEN YEAR([Date]) = YEAR(GETDATE())
         AND [Date] <= CAST(GETDATE() AS date) THEN 1
        ELSE 0
    END AS IsYTD,

    CASE 
        WHEN YEAR([Date]) = YEAR(GETDATE())
         AND MONTH([Date]) = MONTH(GETDATE())
         AND [Date] <= CAST(GETDATE() AS date) THEN 1
        ELSE 0
    END AS IsMTD,

    CASE 
        WHEN YEAR([Date]) = YEAR(GETDATE())
         AND DATEPART(QUARTER, [Date]) = DATEPART(QUARTER, GETDATE())
         AND [Date] <= CAST(GETDATE() AS date) THEN 1
        ELSE 0
    END AS IsQTD

FROM Calendar;
GO


Select * From vw_DimDate
-- *************************************************************
