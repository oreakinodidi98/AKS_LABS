# MySQL Fundamentals

MySQL is a relational database management system. You use it to store data in **tables** made up of **rows** and **columns**.

- A **database** is a container for tables
- A **table** stores related data, such as customers, orders, or products
- A **row** is a single record in a table
- A **column** defines one attribute of that record, such as `id`, `name`, or `created_at`
- SQL which stands for **Structured Query Language** is the language used to define, read, and change the data

## Connecting and working in MySQL

- Connect to MySQL from the command line: `mysql -u root -p`
- Show all databases: `SHOW DATABASES;`
- Switch to a database: `USE mydatabase;`
- Show the tables in the current database: `SHOW TABLES;`
- See the structure of a table: `DESCRIBE customers;`

## Core SQL language areas

SQL in MySQL is usually grouped into a few basic areas:

- **DDL** which is Data Definition Language is used to create or change database objects such as tables
- **DML** which is Data Manipulation Language is used to insert, update, or delete data
- **DQL** which is Data Query Language is used to read data, mainly with `SELECT`
- **DCL** which is Data Control Language is used for permissions and access

## Creating databases and tables

- Create a database:

```sql
CREATE DATABASE companydb;
```

- Switch into the database:

```sql
USE companydb;
```

- Create a table:

```sql
CREATE TABLE employees (
	id INT AUTO_INCREMENT PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	email VARCHAR(100) UNIQUE,
	department VARCHAR(50),
	salary DECIMAL(10,2),
	hire_date DATE
);
```

- `PRIMARY KEY` uniquely identifies each row
- `AUTO_INCREMENT` automatically generates the next numeric value
- `NOT NULL` means the column must have a value
- `UNIQUE` prevents duplicate values in that column

## Inserting data

- Insert one row:

```sql
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
VALUES ('Ada', 'Okafor', 'ada@company.com', 'Engineering', 85000.00, '2025-01-10');
```

- Insert multiple rows:

```sql
INSERT INTO employees (first_name, last_name, email, department, salary, hire_date)
VALUES
('John', 'Mensah', 'john@company.com', 'Sales', 62000.00, '2024-06-15'),
('Grace', 'Adebayo', 'grace@company.com', 'Engineering', 91000.00, '2023-09-01'),
('Mary', 'Diallo', 'mary@company.com', 'HR', 58000.00, '2022-11-20');
```

## Querying data with SELECT

The `SELECT` statement is the main way to read data from MySQL.

- Select all columns from a table:

```sql
SELECT * FROM employees;
```

- Select specific columns only:

```sql
SELECT first_name, last_name, department
FROM employees;
```

- Rename a column in the output using an alias:

```sql
SELECT first_name AS FirstName, salary AS AnnualSalary
FROM employees;
```

## Filtering rows with WHERE

Use `WHERE` when you only want rows that match a condition.

- Find employees in Engineering:

```sql
SELECT *
FROM employees
WHERE department = 'Engineering';
```

- Find employees with salary greater than 70000:

```sql
SELECT first_name, last_name, salary
FROM employees
WHERE salary > 70000;
```

- Combine conditions:

```sql
SELECT *
FROM employees
WHERE department = 'Engineering'
AND salary >= 85000;
```

- Use `OR` when either condition can match:

```sql
SELECT *
FROM employees
WHERE department = 'HR'
OR department = 'Sales';
```

## Common comparison operators

- Equals: `=`
- Not equal: `!=` or `<>`
- Greater than: `>`
- Less than: `<`
- Greater than or equal to: `>=`
- Less than or equal to: `<=`

## Useful filtering patterns

- Match a set of values with `IN`:

```sql
SELECT *
FROM employees
WHERE department IN ('Engineering', 'HR');
```

- Match a range with `BETWEEN`:

```sql
SELECT *
FROM employees
WHERE salary BETWEEN 60000 AND 90000;
```

- Match text patterns with `LIKE`:

```sql
SELECT *
FROM employees
WHERE email LIKE '%@company.com';
```

- `%` means any number of characters
- `_` means a single character

- Find rows where a value is missing:

```sql
SELECT *
FROM employees
WHERE email IS NULL;
```

## Sorting and limiting results

- Sort by salary from highest to lowest:

```sql
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC;
```

- Sort by hire date from oldest to newest:

```sql
SELECT first_name, hire_date
FROM employees
ORDER BY hire_date ASC;
```

- Return only the first 5 rows:

```sql
SELECT *
FROM employees
LIMIT 5;
```

## Aggregate functions

Aggregate functions let you calculate values across multiple rows.

- Count rows:

```sql
SELECT COUNT(*) AS total_employees
FROM employees;
```

- Find the average salary:

```sql
SELECT AVG(salary) AS average_salary
FROM employees;
```

- Find the minimum and maximum salary:

```sql
SELECT MIN(salary) AS lowest_salary, MAX(salary) AS highest_salary
FROM employees;
```

- Find the total salary amount:

```sql
SELECT SUM(salary) AS salary_total
FROM employees;
```

## Grouping data

Use `GROUP BY` when you want to summarize rows by a column.

```sql
SELECT department, COUNT(*) AS employee_count, AVG(salary) AS avg_salary
FROM employees
GROUP BY department;
```

- Filter grouped results with `HAVING`:

```sql
SELECT department, COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) >= 2;
```

- `WHERE` filters rows before grouping
- `HAVING` filters the grouped result after aggregation

## Updating data

Use `UPDATE` to change existing rows.

```sql
UPDATE employees
SET salary = 95000.00
WHERE email = 'grace@company.com';
```

- Be careful with `UPDATE` statements. Without a `WHERE` clause, every row in the table can be changed.

## Deleting data

Use `DELETE` to remove rows.

```sql
DELETE FROM employees
WHERE id = 3;
```

- Be careful with `DELETE`. Without a `WHERE` clause, every row can be removed.

## Basic joins

Joins are used to query data across related tables.

- Example `departments` table:

```sql
CREATE TABLE departments (
	id INT AUTO_INCREMENT PRIMARY KEY,
	department_name VARCHAR(50) NOT NULL
);
```

- Example table with a foreign key:

```sql
CREATE TABLE staff (
	id INT AUTO_INCREMENT PRIMARY KEY,
	first_name VARCHAR(50),
	department_id INT,
	FOREIGN KEY (department_id) REFERENCES departments(id)
);
```

- `INNER JOIN` returns rows that match in both tables:

```sql
SELECT s.first_name, d.department_name
FROM staff s
INNER JOIN departments d ON s.department_id = d.id;
```

- `LEFT JOIN` returns all rows from the left table even if there is no match on the right:

```sql
SELECT s.first_name, d.department_name
FROM staff s
LEFT JOIN departments d ON s.department_id = d.id;
```

## Useful built-in functions

- Current date and time:

```sql
SELECT NOW();
```

- Current date only:

```sql
SELECT CURDATE();
```

- Convert text to uppercase:

```sql
SELECT UPPER(first_name)
FROM employees;
```

- Count the number of characters in a value:

```sql
SELECT first_name, LENGTH(first_name)
FROM employees;
```

## Subqueries

A subquery is a query inside another query.

```sql
SELECT first_name, salary
FROM employees
WHERE salary > (
	SELECT AVG(salary)
	FROM employees
);
```

This query returns employees whose salary is above the average salary.

## Basic query flow to remember

When writing a query, the pattern is usually:

```sql
SELECT column1, column2
FROM table_name
WHERE condition
GROUP BY column_name
HAVING aggregate_condition
ORDER BY column_name
LIMIT 10;
```

Not every query uses all clauses, but this is the usual structure to remember.

## Practical examples

- Find all employees hired in 2024:

```sql
SELECT *
FROM employees
WHERE hire_date >= '2024-01-01'
AND hire_date < '2025-01-01';
```

- Find the top 3 highest-paid employees:

```sql
SELECT first_name, last_name, salary
FROM employees
ORDER BY salary DESC
LIMIT 3;
```

- Count employees in each department:

```sql
SELECT department, COUNT(*) AS total
FROM employees
GROUP BY department;
```

- Find employees whose name starts with A:

```sql
SELECT *
FROM employees
WHERE first_name LIKE 'A%';
```

## Good habits when writing MySQL queries

- End each SQL statement with `;`
- Start with `SELECT` queries when exploring data before using `UPDATE` or `DELETE`
- Use `WHERE` carefully so you only affect the rows you intend to affect
- Use aliases to make results easier to read
- Keep table and column names clear and consistent
- Use `LIMIT` when testing queries against large tables

## Summary

- MySQL stores data in relational tables
- `SELECT` is the most important command for reading data
- `WHERE`, `ORDER BY`, `GROUP BY`, and `LIMIT` are core parts of querying
- `INSERT`, `UPDATE`, and `DELETE` are used to modify data
- Joins let you combine data from related tables
- The best way to get comfortable is to practice by writing small queries and changing them step by step
