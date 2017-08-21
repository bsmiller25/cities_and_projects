# cities_and_projects

Sample code for psql + postgis loading and querying

Queries in load_analyze.sql

1. Create tables and import both csv files into a database;

2. Return all cities in the “Northeast” region sorted by state then name;

3. Return all cities where GovEx has also worked on a project in the last year, sorted by
the number of projects in each city;

4. Create a new column in the projects table numbering them by city based on the start
date, so that the first project in each city is 1, the second is 2, etc.

5. Calculate the difference in days between the longest project and the shortest project
for each govex_service.

6. Create a view that shows the most frequently occurring project focus_area by
population quartile.

7. Calculate which city has the most other cities within 100 miles.
