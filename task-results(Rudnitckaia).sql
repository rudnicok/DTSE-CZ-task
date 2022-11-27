--TASK1--
CREATE TABLE IF NOT EXISTS TempTask AS SELECT *
FROM customers c
--JOIN orders ON c.customer_id=orders.customer_id
--To avoid repeating customer_id column temporaty tables for orders and contracts can be created with ALTER-DROP one column
JOIN orders USING (customer_id)
JOIN contacts USING (customer_id);
--As I understood we need to show just customers who have contacts&orders, to show all customers I'd use LEFT JOIN instead of INNER JOIN
--Since the dataframe will be used for following tasks, i have kept it in the table TempTask.

--TASK2--
SELECT 
	first_name,
    last_name,
    email,
    order_id,
    item,
    COUNT(*) AS "Count"
FROM TempTask
GROUP BY
	order_id
HAVING Count(*) > 1
ORDER BY order_id;

--Another option might be by rowid, but if we have many items or different statuses for the order -all parameters should be considered in the conditions
SELECT first_name,
    last_name,
    email,
    order_id,
    item
FROM TempTask
WHERE rowid > (
  SELECT MIN(rowid) FROM TempTask ts  
  WHERE TempTask.order_id = ts.order_id
  AND TempTask.customer_id = ts.customer_id
);

--TASK3--
SELECT DISTINCT 
	first_name,
    last_name,
    email,
    order_id,
    item
FROM TempTask
ORDER BY last_name;

--TASK4--
SELECT DISTINCT
	first_name || " " || last_name AS full_name,
    order_id,
  	--I usually use IIF, but it's not available here, probably the matter of the version
    CASE 
    	WHEN order_value <= 25 THEN 
        	"SMALL" 
        WHEN order_value > 100 THEN
        	"BIG"
        ELSE "MEDIUM"
        END order_size
FROM TempTask
ORDER BY order_id ASC;

--TASK5--
SELECT DISTINCT item
FROM orders
WHERE INSTR(item,"ea") > 0 
	OR SUBSTR (item, 1, 3) = "Key"
-- Probably it's more correct way to work with strings, but I prefer to use LIKE - WHERE item LIKE "%ea%" OR item like ("Key%")
	
--TASK 6--
--Self-join
SELECT c1.last_name || " " || c1.first_name as "Customer" ,
	c2.last_name || " " || c2.first_name as "Referred by"
FROM customers c1 JOIN customers c2 ON c1.referred_by_id=c2.customer_id
ORDER BY c1.last_name asc
