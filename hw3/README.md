# HW 3: Data Warehouse

For this HW, I first modified and run the `load_yellow_taxi_data.py` script to download the required data in Parquet format and upload the files to Google Cloud Storage (GCS).

Next, I wrote the following queries to set up BigQuery for data analysis.

#### 1. Create an external table using the Yellow Taxi Trip Records.

Reference: https://cloud.google.com/bigquery/docs/external-data-cloud-storage

```sql
CREATE OR REPLACE EXTERNAL TABLE `dezoomcamp-hw3.nytaxi.yellow_trip_2024`
  OPTIONS (
    format ="PARQUET",
    uris = ['gs://dezoomcamp-hw3-4ee0a1f24d7a/yellow_tripdata_2024-*.parquet']
  );
```

Thoughts on this step (why to create an external table?):
- **Query Cost Savings:** External tables allow you to query the data without physically moving it into BigQuery, reducing storage costs.
- **Separation of Storage and Compute:** You keep the raw data in GCS while still being able to analyze it in BigQuery.
- **Automatic Updates:** If the dataset updates frequently, you don’t need to reload it into BigQuery; the external table automatically reflects the changes in GCS.

#### 2. Create a (regular/materialized) table in BQ using the Yellow Taxi Trip Records (do not partition or cluster this table).

For this step, I chose to create a regular table. The query is shown below:

```sql
CREATE OR REPLACE TABLE `dezoomcamp-hw3.nytaxi.yellow_trip_2024_bq`
AS SELECT * FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024`;
```

Thoughts on this step (Why move from an external table to a regular/materialized table?):
- **Performance Gains:** Queries on external tables can be slower because BigQuery has to read the data from GCS each time.
- **Full SQL Features:** External tables have limitations (e.g., no partitioning, clustering, or indexing).
- **Avoid GCS Access Costs:** Frequent queries on external tables incur GCS read costs, whereas storing the data in BigQuery reduces long-term expenses.

With the data set up in BigQuery, we are ready to analyze and answer questions using SQL queries.


## Question 1

>  What is count of records for the 2024 Yellow Taxi Data?

The query is shown below:

```sql
SELECT COUNT(*)
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024`;
```

which returns 20332093.

## Question 2

> Write a query to count the distinct number of PULocationIDs for the entire dataset on both the tables.
> What is the estimated amount of data that will be read when this query is executed on the External Table and the Table?

To check the estimated data read before running a query, open the BigQuery Console and paste the query into the Query Editor. After highlighting the query we would like to estimate, we can check the bottom-right corner of the editor to see the estimated bytes processed.

Query Used:

```sql
-- External Table
SELECT COUNT(DISTINCT PULocationID)
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024`;
```

```sql
-- Regular/Materialized Table
SELECT COUNT(DISTINCT PULocationID)
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024_bq`;
```

BigQuery estimated 0 MB for the External Table and 155.12 MB for the Materialized Table.

Some thoughts:
- For external table, BigQuery likely used metadata instead of scanning the entire dataset.
- For regular table, the data is stored in BigQuery. Thus, retrieving the results required reading the column `PULocationID`.

## Question 3

> Write a query to retrieve the `PULocationID` from the table (not the external table) in BigQuery.
> Now write a query to retrieve the `PULocationID` and `DOLocationID` on the same table. Why are the estimated number of Bytes different?

Query to retrieve `PULocationID` from the table in BigQuery:
```sql
SELECT PULocationID
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024_bq`;
```
Estimated bytes processed: 155.12MB

Query to retrieve `PULocationID` and `DOLocationID` from the table in BigQuery:
```sql
SELECT PULocationID, DOLocationID
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024_bq`;
```
Estimated bytes processed: 310.24MB. 

Since BigQuery is a columnar database, it scans only the requested columns. So when selecting both `PULocationID` and `DOLocationID`, we observed that the estimated bytes processed is double that of selecting only `PULocationID`, as BigQuery reads twice the amount of columnar data.

## Question 4

> How many records have a fare_amount of 0?

```SQL
SELECT count(*)
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024_bq`
WHERE fare_amount = 0;
```

which output 8333.

## Question 5

> What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy).

The best strategy is to partition by `tpep_dropoff_datetime` and cluster on `VendorID`.

Reasons:
- Since queries will filter on `tpep_dropoff_datetime`, partitioning helps by reducing the amount of data scanned.
- Since queries will order by `VendorID`, clustering makes sorting and filtering on `VendorID` more efficient without needing a full scan.

The query to create such an optimized table is shown below:

```sql
CREATE OR REPLACE TABLE `dezoomcamp-hw3.nytaxi.yellow_trip_2024_optimized`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID
AS SELECT * FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024_bq`;
```


## Question 6

> Write a query to retrieve the distinct VendorIDs between tpep_dropoff_datetime 2024-03-01 and 2024-03-15 (inclusive).
> Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values?

Query to retrieve distinct `VendorID` between `tpep_dropoff_datetime` `2024-03-01` and `2024-03-15` in the regular table (not optimized) I created earlier:
```sql
-- Count the distinct VendorID between 2024-03-01 and 2024-03-15 in not optimized table
SELECT count(distinct VendorID)
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024_bq`
WHERE DATE(tpep_dropoff_datetime) >= '2024-03-01'
AND
DATE(tpep_dropoff_datetime) <= '2024-03-15';
```

Estimated bytes: 310.24MB.

Query on the partitioned and clustered table:
```sql
-- Count the distinct VendorID between 2024-03-01 and 2024-03-15 in optimized table
SELECT count(distinct VendorID)
FROM `dezoomcamp-hw3.nytaxi.yellow_trip_2024_optimized`
WHERE DATE(tpep_dropoff_datetime) >= '2024-03-01'
AND
DATE(tpep_dropoff_datetime) <= '2024-03-15';
```

Estimated bytes: 26.84MB.


## Question 7

> Where is the data stored in the External Table you created?

The data in the External Table is stored in: GCP Bucket.

The external data in BigQuery references data stored externally. Queries on an external table read data directly from Google Cloud Storage (GCP Bucket) without importing it into BigQuery.

## Question 8

> True or False: It is best practice in Big Query to always cluster your data.

While clustering can improve query performance in BigQuery, it is not always the best practice. Whether or not to use clustering depends on factors such as query patterns, table size, and partitioning strategy.

## Question 9

> Write a SELECT count(*) query FROM the materialized table you created. How many bytes does it estimate will be read? Why?

The estimated bytes is zero.

Explanation: BigQuery automatically precomputes and caches metadata which includes the total number of rows in the dataset. Therefore, when running SELECT count(*) query from the regular/materialized table, **BigQuery retrieves the precomputed row count instead of scanning the entire table**. In this way, BigQuery efficiently prevents unnecessary data scans, resulting in 0 bytes processed.