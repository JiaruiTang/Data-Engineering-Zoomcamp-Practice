# HW 2: Workflow Orchestration

For this HW, I leveraged the backfill functionality in the scheduled flow to backfill the data for the year 2021. In course, I found cloud computing is more powerful. Therefore, for this homework, I choose to use the flow that builds ETL pipelines on GCP.

The `.yml` files for the workflow is in `/flows`. Note, I hide my service account key from `zoomcamp.04_gcp_kv.yml`.

From the Kestra's WebUI, I first executed 04 and 05. Since I didn't implement the data processing for year 2020, I chose backfill executions in the date range from 2020-01-01 to 2021-07-31 for both yellow and green taxi data to implement the 06 script. 


## Question 1

>  Within the execution for Yellow Taxi data for the year `2020` and month `12`: what is the uncompressed file size (i.e. the output file `yellow_tripdata_2020-12.csv` of the extract task)?

Check the output file in Cloud Storage - Buckets for size: 128.3 MB

## Question 2

> What is the rendered value of the variable `file` when the inputs `taxi` is set to `green`, `year` is set to `2020`, and `month` is set to `04` during execution?

From code `file: "{{inputs.taxi}}_tripdata_{{trigger.date | date('yyyy-MM')}}.csv"`, the rendered value of the value of the variable `file` is `green_tripdata_2020-04.csv`.

## Question 3

> How many rows are there for the `Yellow` Taxi data for all CSV files in the year 2020?

There is one column `filename` in table `yellow_tripdata` indicating which CSV file one row is from. So I used the following SQL query in GCP BigQuery to count the total number of records in `yellow_tripdata` whose `filename` contains `2020`.

```SQL
SELECT COUNT(*) AS total_records
FROM `de_zoomcamp.yellow_tripdata`
WHERE filename LIKE '%2020%';
```

The answer is 24,648,499.

Since records from the new tables were merged into the `yellow_tripdata` table only when their `unique_row_id` did not match any existing records, some records in the CSV file may have been excluded from the merge due to duplicate `unique_row_id` values. To verify if this situation occurred, I used the following SQL query:

```SQL
WITH each_table_count AS (
  SELECT 'yellow_tripdata_2020_01_ext' AS table_name, COUNT(*) AS record_count FROM de_zoomcamp.yellow_tripdata_2020_01_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_02_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_02_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_03_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_03_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_04_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_04_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_05_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_05_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_06_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_06_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_07_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_07_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_08_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_08_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_09_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_09_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_10_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_10_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_11_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_11_ext
  UNION ALL
  SELECT 'yellow_tripdata_2020_12_ext', COUNT(*) FROM de_zoomcamp.yellow_tripdata_2020_12_ext
)
SELECT SUM(record_count)
FROM each_table_count;
```

This query returned the same result as the previous one, confirming that the total number of rows across all `Yellow` taxi data CSV files from 2020 is 24,648,499.

## Question 4

> How many rows are there for the `Green` Taxi data for all CSV files in the year 2020?

I used the following query to count the number of rows across all `Green` taxi data CSV files in 2020:

```SQL
SELECT COUNT(*) AS total_records
FROM `de_zoomcamp.green_tripdata`
WHERE filename LIKE '%2020%';
```

which output 1,734,051.

## Question 5

> How many rows are there for the `Yellow` Taxi data for the March 2021 CSV file?

I used the following query to count the number of rows for the `Yellow` taxi data in March 2021 CSV file:

```SQL
SELECT COUNT(*)
FROM `de_zoomcamp.yellow_tripdata_2021_03_ext`;
```

which returned 1,925,152.

## Question 6

> How would you configure the timezone to New York in a Schedule trigger?

From Kestra's documentation ([Kestra Schedule Trigger](https://kestra.io/docs/workflow-components/triggers/schedule-trigger)), there is a parameter `timezone` to configure the timezone, e.g. `timezone: America/New_York`.

