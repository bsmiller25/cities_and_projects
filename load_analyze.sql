-- 1. Create tables and import both csv files into a database

-- create cities table
DROP TABLE IF EXISTS cities CASCADE;
CREATE TABLE cities (
   city_id int,
   name varchar,
   state char(2),
   region varchar,
   population int,
   latitude double precision,
   longitude double precision
);

-- load cities data
\COPY cities FROM './data/cities.csv' DELIMITER ',' CSV HEADER;

-- add geometry column
SELECT AddGeometryColumn ('cities','geom',4326,'POINT',2);
UPDATE cities SET geom = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326);

-- create projects table
DROP TABLE IF EXISTS projects CASCADE;
CREATE TABLE projects (
   project_id int,
   govex_service varchar,
   city_id int,
   focus_area varchar,
   start_date date,
   end_date date
);

-- load projects data
\COPY projects FROM './data/projects.csv' DELIMITER ',' CSV HEADER;

-- 2. Return all cities in the “Northeast” region sorted by state then name
SELECT name
FROM cities
WHERE region = 'Northeast'
ORDER BY name;

-- 3. Return all cities where GovEx has also worked on a project in the last year, sorted by the number of projects in each city

--    Sort by number of projects
SELECT a.name,
       COUNT(b.project_id) as num_proj
FROM cities a
LEFT JOIN projects b ON a.city_id = b.city_id
WHERE b.start_date > (SELECT CURRENT_DATE - INTERVAL '1 year')
GROUP BY a.name
ORDER BY num_proj DESC;

-- 4. Create a new column in the projects table numbering them by city based on the start date, so that the first project in each city is 1, the second is 2, etc.
ALTER TABLE projects ADD COLUMN city_count int;
UPDATE projects
SET city_count = r.rank
FROM (
     SELECT city_id,
            project_id,
            start_date,
            RANK() OVER (PARTITION BY city_id ORDER BY start_date ASC) as rank
     FROM projects
     ) r
WHERE projects.project_id = r.project_id
;

-- 5. Calculate the difference in days between the longest project and the shortest project for each govex_service.
SELECT govex_service,
       MAX(end_date - start_date) - MIN(end_date - start_date) as diff
FROM projects
GROUP BY govex_service;

-- 6. Create a view that shows the most frequently occurring project focus_area by population quartile

DROP VIEW IF EXISTS v_focuspop;
CREATE VIEW v_focuspop AS (
   WITH quarts AS (
   SELECT b.quartile,
          a.focus_area,
          RANK() OVER (PARTITION BY b.quartile ORDER BY COUNT(a.focus_area) DESC) as rnk 
   FROM projects a
   LEFT JOIN (SELECT city_id,
                     population,
                     NTILE(4) OVER (ORDER BY population) AS quartile
              FROM cities
              ) b ON a.city_id = b.city_id
   GROUP BY b.quartile, a.focus_area
   ORDER BY b.quartile, a.focus_area
   )
   SELECT * FROM quarts WHERE rnk = 1
);

-- 7. Calculate which city has the most other cities within 100 miles.
WITH sorted AS (
SELECT a.name,
       COUNT(b.name),
       RANK() OVER (ORDER BY COUNT(b.name) desc) as rnk
FROM cities a,
     (SELECT * FROM cities) b
WHERE ST_Within(ST_Transform(b.geom, 2163), ST_Buffer(ST_Transform(a.geom, 2163), 100 * 1609.34))
GROUP BY a.name
)
SELECT name, count FROM sorted WHERE rnk = 1;


