select *
from customer;

select first_name, last_name
from customer
where first_name = 'Carolyn';

SELECT *
FROM payment
ORDER BY amount DESC
LIMIT 20;

SELECT address
FROM address
WHERE address_id IN (
    SELECT address_id FROM store
);

SELECT a.address
FROM store s
JOIN address a ON s.address_id = a.address_id;

select
    payment_id,
    amount,
    EXTRACT(DAY FROM payment_date) AS day,
    EXTRACT(MONTH FROM payment_date) AS month,
    EXTRACT(ISODOW FROM payment_date) AS weekday_number
FROM payment;

select
    customer_id,
    rental_date::DATE AS rental_date_only,
    staff_id
FROM rental
WHERE rental_date >= '2005-06-01'
  AND rental_date < '2005-07-01';

SELECT
    title,
    description,
    length
FROM film
WHERE release_year > 2000
  AND length BETWEEN 60 AND 120
ORDER BY length DESC
LIMIT 20;
SELECT
    payment_id,
    payment_date::DATE AS payment_date_only,
    amount
FROM payment
WHERE payment_date >= '2007-04-01'
  AND payment_date < '2007-05-01'
  AND amount <= 4
ORDER BY amount DESC, payment_date ASC;

SELECT
    customer_id AS "Идентификатор",
    first_name AS "Имя",
    last_name AS "Фамилия"
FROM customer
WHERE first_name IN ('Jack', 'Bob', 'Sara')
  AND (last_name LIKE '%p%' or last_name LIKE '%P%')
ORDER BY customer_id ASC;

CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    birth_date DATE NOT NULL,
    address TEXT NOT NULL
);

truncate table students;
INSERT INTO students (id, first_name, last_name, age, birth_date, address)
VALUES (51, 'Ekaterina', 'Kachalina', 23, '2002-06-28', 'Melioratorov str, 12');

select *
from students;

INSERT INTO students (first_name, last_name, age, birth_date, address)
VALUES
    ('Anna', 'Sidorova', 24, '2002-03-12', 'Pushkina str, 10'),
    ('Nikita', 'Petrov', 21, '2005-07-19', 'Nevsky pr, 20');

select *
from students;

DELETE FROM students WHERE id = 51;

SELECT * FROM students;
DROP TABLE students;

SELECT * FROM students;

SELECT COUNT(DISTINCT first_name) AS unique_first_names
FROM customer;

SELECT
    amount,
    MIN(payment_date) AS first_payment_date,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_amount
FROM payment
GROUP BY amount
ORDER BY payment_count DESC, amount DESC
LIMIT 5;

SELECT
    s.store_id,
    COUNT(i.inventory_id) AS inventory_count
FROM store s
LEFT JOIN inventory i ON s.store_id = i.store_id
GROUP BY s.store_id;

SELECT
    s.store_id,
    a.address
FROM store s
JOIN address a ON s.address_id = a.address_id;

SELECT CONCAT(first_name, ' ', last_name) AS full_name
FROM customer
UNION
SELECT CONCAT(first_name, ' ', last_name)
FROM staff;

SELECT first_name FROM customer
EXCEPT
SELECT first_name FROM staff;

SELECT
    customer_id,
    rental_date::DATE AS rental_date_only,
    staff_id
FROM rental
WHERE rental_date >= '2005-06-01'
  AND rental_date < '2005-07-01';

    SELECT
        customer_id,
        COUNT(*) AS payment_count,
        AVG(amount) AS global_avg_amount, 
        ROUND(AVG(amount), 2) as round_global_avg_amount
    FROM payment
    GROUP BY customer_id
    having COUNT(*)>=40;

    SELECT
    a.actor_id,
    CONCAT(a.first_name, ' ', a.last_name) AS full_name,
    COUNT(fa.film_id) AS film_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY film_count DESC
LIMIT 1
;

SELECT
    DATE_TRUNC('month', r.rental_date) AS rental_month,
    ROUND(COALESCE(SUM(p.amount), 0), 1) AS total_revenue
FROM rental r
LEFT JOIN payment p ON r.rental_id = p.rental_id
GROUP BY DATE_TRUNC('month', r.rental_date)
ORDER BY rental_month;

SELECT
    c.name AS genre_name,
    COUNT(DISTINCT f.film_id) AS film_count,
    ROUND(AVG(p.amount), 2) AS avg_payment
FROM category c
JOIN film_category fc ON c.category_id = fc.category_id
JOIN film f ON fc.film_id = f.film_id
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id
GROUP BY c.category_id, c.name
HAVING COUNT(DISTINCT f.film_id) > 60
ORDER BY avg_payment DESC;

SELECT
    f.title,
    COUNT(*) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE EXTRACT(ISODOW FROM r.rental_date) = 6  -- 6 = суббота
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC, f.title ASC
LIMIT 5;

SELECT
    amount,
    payment_date::DATE AS payment_date,
    TO_CHAR(payment_date, 'Day') AS weekday_name
FROM payment;

WITH film_length_category AS (
    SELECT
        film_id,
        title,
        length,
        CASE
            WHEN length < 70 THEN 'Короткие'
            WHEN length >= 70 AND length < 130 THEN 'Средние'
            WHEN length >= 130 THEN 'Длинные'
        END AS length_category
    FROM film),
film_rental_stats AS (select f.film_id, f.length_category,
        COUNT(r.rental_id) AS rental_count
    FROM film_length_category f
    JOIN inventory i ON f.film_id = i.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    GROUP BY f.film_id, f.length_category)
SELECT
    length_category,
    COUNT(DISTINCT film_id) AS film_count,
    SUM(rental_count) AS total_rentals
FROM film_rental_stats
GROUP BY length_category
ORDER BY 
    CASE length_category
        WHEN 'Короткие' THEN 1
        WHEN 'Средние' THEN 2
        WHEN 'Длинные' THEN 3
    END;

CREATE TABLE weekly_revenue AS
SELECT
    EXTRACT(YEAR FROM rental_date) AS r_year,
    EXTRACT(WEEK FROM rental_date) AS r_week,
    SUM(amount) AS revenue
FROM rental r
LEFT JOIN payment p ON p.rental_id = r.rental_id
GROUP BY 1, 2
ORDER BY 1, 2;

SELECT * FROM weekly_revenue;

SELECT
    r_year,
    r_week,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY r_year, r_week), 0) AS cumulative_revenue
FROM weekly_revenue;

SELECT
    r_year,
    r_week,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY r_year, r_week), 0) AS cumulative_revenue,
    ROUND(AVG(revenue) OVER (ORDER BY r_year, r_week ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 0) AS moving_avg
FROM weekly_revenue;

SELECT
    r_year,
    r_week,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY r_year, r_week), 0) AS cumulative_revenue,
    ROUND(AVG(revenue) OVER (ORDER BY r_year, r_week ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 0) AS moving_avg,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY r_year, r_week)) / 
        NULLIF(LAG(revenue) OVER (ORDER BY r_year, r_week), 0) * 100,
        2
    ) AS revenue_growth_percent
FROM weekly_revenue;
