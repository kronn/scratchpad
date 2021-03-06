-- version if coming from a datafile
START TRANSACTION;
  -- create a temporary table for the new data (without data)
  CREATE TEMPORARY TABLE temporary_table AS
    SELECT * FROM test WHERE false;

  -- copy new data into temporary table
  COPY temporary_table FROM 'data_file.csv';

  -- lock table to prevent race conditions
  LOCK TABLE test;

  -- update table with newer data (found in both temporary and real table)
  UPDATE test
    SET data=temporary_table.data 
      FROM temporary_table 
      WHERE test.id=temporary_table.id;

  -- delete rows that are already copied
  -- this is a positive index-lookup and therefore rather fast
  DELETE
    FROM temporary_table
    WHERE (id) IN (SELECT id from test) AS a;

  -- insert anything really new
  INSERT INTO test
    SELECT *
    FROM temporary_table;
COMMIT;


-- version for multiple upserts
START TRANSACTION;
  -- create a temporary table for the new data (without data)
  CREATE TEMPORARY TABLE temporary_table AS
    SELECT * FROM test WHERE false;

  -- copy new data into temporary table
  INSERT INTO temporary_table (numericfield, textfield) VALUES
    (1, "text"),
    (2, "something");

  -- lock table to prevent race conditions
  LOCK TABLE test;

  -- update table with newer data (found in both temporary and real table)
  UPDATE test
    SET data=temporary_table.data 
      FROM temporary_table 
      WHERE test.id=temporary_table.id;

  -- delete rows that are already copied
  -- this is a positive index-lookup and therefore rather fast
  DELETE
    FROM temporary_table
    WHERE (id) IN (SELECT id from test) AS a;

  -- insert anything really new
  INSERT INTO test
    SELECT *
    FROM temporary_table;
COMMIT;
