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

[conn_engine.ipynb](hw1/conn_engine.ipynb)

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

> Which of the following sequences, respectively, describes the workflow for:
> 1. Downloading the provider plugins and setting up backend,
> 2. Generating proposed changes and auto-executing the plan
> 3. Remove all resources managed by terraform

Answer: terraform init, terraform apply -auto-approve, terraform destroy

Explanation: The standard workflow we learned should be `terraform init`, `terraform plan`, `terraform apply` and `terraform destroy`. To check which step allows the auto-execution of the plan, we can use the command `-help`:

```shell
$ terraform apply -help
```

which gives the output:

```
Usage: terraform [global options] apply [options] [PLAN]

  Creates or updates infrastructure according to Terraform configuration
  files in the current directory.

  By default, Terraform will generate a new plan and present it for your
  approval before taking any action. You can optionally provide a plan
  file created by a previous call to "terraform plan", in which case
  Terraform will take the actions described in that plan without any
  confirmation prompt.

Options:

  -auto-approve          Skip interactive approval of plan before applying.

  ...
```

# Reflection on Solution

For question 1, the version of pip can be quickly checked through `docker run python:3.12.8 pip --version`.

For question 2, there is a way in pgadmin to check which hostname can connect us to the postgres database:
1. Spin tha`docker-compose.yml` with `docker compose up -d`
2. Log into pgadmin container with: docker exec -it pgadmin bash
3. Test connectivity with ping

```shell
554604249e08:/pgadmin4$ ping db
PING db (172.22.0.2): 56 data bytes
64 bytes from 172.22.0.2: seq=0 ttl=42 time=0.191 ms
64 bytes from 172.22.0.2: seq=1 ttl=42 time=0.370 ms
64 bytes from 172.22.0.2: seq=2 ttl=42 time=0.140 ms

554604249e08:/pgadmin4$ ping postgres
PING postgres (172.22.0.2): 56 data bytes
64 bytes from 172.22.0.2: seq=0 ttl=42 time=0.277 ms
64 bytes from 172.22.0.2: seq=1 ttl=42 time=0.408 ms
64 bytes from 172.22.0.2: seq=2 ttl=42 time=0.193 ms
```

For question 3, the solution used GROUP BY with column alias defined in SELECT clause. This works in Postgres, Snowflake and BigQuery. However, in strict SQL standards (like MySQL and some versions of SQL Server), this may not work. Also, it's important to note that **aliases in SELECT still cannot be used in WHERE or JOIN—use a subquery instead.**