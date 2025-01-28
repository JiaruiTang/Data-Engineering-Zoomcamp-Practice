# HW 1: Docker & SQL

## Question 1. Understanding docker first run

> Run docker with the python:3.12.8 image in an interactive mode, use the entrypoint bash. What's the version of pip in the image?

Run the container:

```bash
docker run -it --entrypoint bash python:3.12.8
```

Inside the container, check the pip version:

```bash
pip --version
```
which returns 

```bash
pip 24.3.1 from /usr/local/lib/python3.12/site-packages/pip (python 3.12)
```

## Question 2. Understanding Docker networking and docker-compose

> Given the following docker-compose.yaml, what is the hostname and port that pgadmin should use to connect to the postgres database?


```yaml
services:
db:
    container_name: postgres
    image: postgres:17-alpine
    environment:
    POSTGRES_USER: 'postgres'
    POSTGRES_PASSWORD: 'postgres'
    POSTGRES_DB: 'ny_taxi'
    ports:
    - '5433:5432'
    volumes:
    - vol-pgdata:/var/lib/postgresql/data

pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    environment:
    PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
    PGADMIN_DEFAULT_PASSWORD: "pgadmin"
    ports:
    - "8080:80"
    volumes:
    - vol-pgadmin_data:/var/lib/pgadmin  

volumes:
vol-pgdata:
    name: vol-pgdata
vol-pgadmin_data:
    name: vol-pgadmin_data
```

`hostname`: db 

`port`: 5432

In Docker Compose, services talk to each other using the service name as the hostname, which is `db` in this yaml file. They connect through the internal port of the Postgres container, which is `5432`.


## Question 3. Trip Segmentation Count

> During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, respectively, happened:
> 1. Up to 1 mile
> 2. In between 1 (exclusive) and 3 miles (inclusive),
> 3. In between 3 (exclusive) and 7 miles (inclusive),
> 4. In between 7 (exclusive) and 10 miles (inclusive),
> 5. Over 10 miles

Run Postgres with Docker:

```bash
docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql/data \
  -p 5436:5432 \
  postgres:13
```

Then, connect to Postgres and upload data in Jupyter notebook:

conn_engine.ipynb

SQL Query to retrieve the number of trips up to 1 mile:

```postgres
SELECT count(*) FROM green_taxi_data 
WHERE 
    lpep_pickup_datetime >= '2019-10-01' AND 
    lpep_dropoff_datetime < '2019-11-01' AND
    trip_distance <= 1
```

## Question 4. Longest trip for each day

> Which was the pick up day with the longest trip distance? Use the pick up time for your calculations. Tip: For every day, we only care about one single trip with the longest distance.

SQL Query:

```postgres
SELECT pickup_date
FROM (
    SELECT pickup_date, row_number() over (order by trip_distance DESC) as distance_rank
    FROM (
        SELECT 
            DATE(lpep_pickup_datetime) as pickup_date, 
            row_number() over (partition by DATE(lpep_pickup_datetime) order by trip_distance DESC) AS daily_rank,
            trip_distance
        FROM green_taxi_data
    ) t1
    WHERE daily_rank = 1
) t2
WHERE distance_rank = 1
```

## Question 5. Three biggest pickup zones

> Which were the top pickup locations with over 13,000 in total_amount (across all trips) for 2019-10-18? Consider only lpep_pickup_datetime when filtering by date.

SQL Query:

```postgres
WITH filtered_grouped_trips AS (
    SELECT "PULocationID", SUM(total_amount) as total_amount
    FROM green_taxi_data
    WHERE DATE(lpep_pickup_datetime) = '2019-10-18'
    GROUP BY "PULocationID"
    HAVING SUM(total_amount) > 13000
)
SELECT "PULocationID", "Zone", total_amount
FROM filtered_grouped_trips a
LEFT JOIN taxi_zone b
ON a."PULocationID" = b."LocationID"
```

## Question 6. Largest tip

> For the passengers picked up in October 2019 in the zone named "East Harlem North" which was the drop off zone that had the largest tip? Note: it's tip , not trip. We need the name of the zone, not the ID.

SQL Query:

```postgres
SELECT "Zone"
FROM green_taxi_data a
LEFT JOIN taxi_zone b
on a."DOLocationID" = b."LocationID"
WHERE 
    lpep_pickup_datetime >= '2019-10-01' AND
    lpep_pickup_datetime < '2019-11-01' AND
    "PULocationID" = (
        SELECT "LocationID"
        FROM taxi_zone
        WHERE "Zone" = 'East Harlem North'
    )
ORDER BY tip_amount DESC
LIMIT 1
```

## Question 7. Terraform Workflow


