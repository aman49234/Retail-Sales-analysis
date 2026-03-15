DROP DATABASE IF EXISTS Global_Store;
CREATE DATABASE IF NOT EXISTS Global_Store;
USE Global_Store;

-- Remove rows with negative quantity or sales
DELETE FROM Sales
WHERE Quantity < 0 OR Sales < 0;

-- Optional: fix dates if they imported as text
-- Convert VARCHAR to DATE using STR_TO_DATE
UPDATE Sales
SET OrderDate = STR_TO_DATE(OrderDate, '%Y-%m-%d'),
    ShipDate  = STR_TO_DATE(ShipDate, '%Y-%m-%d')
WHERE OrderDate IS NOT NULL;





CREATE OR REPLACE VIEW vw_MonthlySales AS
SELECT 
    YEAR(OrderDate) AS Sales_Year,
    MONTH(OrderDate) AS Sales_Month,
    Region,
    SUM(Sales) AS Total_Sales,
    SUM(Profit) AS Total_Profit
FROM Sales
JOIN Customers ON Sales.CustomerID = Customers.CustomerID
GROUP BY YEAR(OrderDate), MONTH(OrderDate), Region;


SELECT * FROM vw_MonthlySales;


WITH MonthlyProductSales AS (
    SELECT 
        YEAR(OrderDate) AS Sales_Year,
        MONTH(OrderDate) AS Sales_Month,
        p.Category,
        p.ProductName,
        SUM(s.Sales) AS Total_Sales
    FROM Sales s
    JOIN Products p ON s.ProductID = p.ProductID
    GROUP BY YEAR(OrderDate), MONTH(OrderDate), p.Category, p.ProductName
),
RankedProducts AS (
    SELECT 
        Sales_Year,
        Sales_Month,
        Category,
        ProductName,
        Total_Sales,
        RANK() OVER (
            PARTITION BY Sales_Year, Sales_Month, Category
            ORDER BY Total_Sales DESC
        ) AS SalesRank
    FROM MonthlyProductSales
)
SELECT *
FROM RankedProducts
WHERE SalesRank <= 3
ORDER BY Sales_Year, Sales_Month, Category, SalesRank;

CREATE OR REPLACE VIEW vw_Customer_RFM AS
WITH RFM AS (
    SELECT 
        c.CustomerID,
        MAX(s.OrderDate) AS LastPurchaseDate,
        COUNT(DISTINCT s.OrderID) AS Frequency,
        SUM(s.Sales) AS Monetary,
        DATEDIFF(CURDATE(), MAX(s.OrderDate)) AS Recency
    FROM Sales s
    JOIN Customers c ON s.CustomerID = c.CustomerID
    GROUP BY c.CustomerID
)
SELECT 
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    NTILE(4) OVER (ORDER BY Recency ASC) AS Recency_Score,   -- lower recency = better
    NTILE(4) OVER (ORDER BY Frequency DESC) AS Frequency_Score,
    NTILE(4) OVER (ORDER BY Monetary DESC) AS Monetary_Score
FROM RFM;



SELECT * FROM vw_Customer_RFM;

