-- Supply chain shipments database: schema and analysis queries (MySQL)
-- ===== Schema =====
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS carriers;

CREATE TABLE carriers (
    carrier_id   INT AUTO_INCREMENT PRIMARY KEY,
    carrier_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE shipments (
    shipment_id      VARCHAR(10) PRIMARY KEY,
    carrier_id       INT NOT NULL,
    mode             VARCHAR(10) NOT NULL,
    origin           VARCHAR(50),
    destination      VARCHAR(50),
    order_date       DATE NOT NULL,
    ship_date        DATE NOT NULL,
    delivery_date    DATE NULL,
    promised_days    INT NOT NULL,
    weight_kg        DECIMAL(10,1) CHECK (weight_kg > 0),
    freight_cost_usd DECIMAL(10,2) CHECK (freight_cost_usd >= 0),
    FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id)
);

-- ===== Late rate by carrier (JOIN + GROUP BY) =====
SELECT c.carrier_name,
       COUNT(*) AS shipments,
       ROUND(100 * AVG(DATEDIFF(s.delivery_date, s.ship_date) > s.promised_days), 1) AS pct_late
FROM shipments s
JOIN carriers c ON c.carrier_id = s.carrier_id
WHERE s.delivery_date IS NOT NULL
GROUP BY c.carrier_name
ORDER BY pct_late DESC;

-- ===== Monthly volume and spend =====
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
       COUNT(*)                         AS shipments,
       ROUND(SUM(freight_cost_usd), 0)  AS total_spend_usd
FROM shipments
GROUP BY month
ORDER BY month;

-- ===== Busiest routes (HAVING) =====
SELECT origin, destination, COUNT(*) AS shipments,
       ROUND(AVG(freight_cost_usd), 0) AS avg_cost_usd
FROM shipments
GROUP BY origin, destination
HAVING COUNT(*) >= 10
ORDER BY shipments DESC
LIMIT 5;

-- ===== Shipment status labels (CASE) =====
SELECT shipment_id, mode,
       DATEDIFF(delivery_date, ship_date) - promised_days AS days_over,
       CASE
           WHEN delivery_date IS NULL THEN 'In transit / unknown'
           WHEN DATEDIFF(delivery_date, ship_date) <= promised_days THEN 'On time'
           WHEN DATEDIFF(delivery_date, ship_date) - promised_days <= 2 THEN 'Slightly late'
           ELSE 'Very late'
       END AS status
FROM shipments
ORDER BY days_over DESC
LIMIT 10;
