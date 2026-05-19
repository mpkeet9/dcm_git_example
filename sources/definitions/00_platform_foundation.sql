CREATE ROLE IF NOT EXISTS {{ deployer_role }};
CREATE ROLE IF NOT EXISTS {{ reader_role }};
CREATE ROLE IF NOT EXISTS {{ monitor_role }};

CREATE WAREHOUSE IF NOT EXISTS {{ warehouse_name }}
  WAREHOUSE_SIZE = '{{ warehouse_size }}'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

CREATE DATABASE IF NOT EXISTS {{ data_db }};

CREATE SCHEMA IF NOT EXISTS {{ data_db }}.{{ data_schema }};
CREATE SCHEMA IF NOT EXISTS {{ data_db }}.{{ analytics_schema }};

GRANT USAGE ON WAREHOUSE {{ warehouse_name }} TO ROLE {{ deployer_role }};
GRANT USAGE ON WAREHOUSE {{ warehouse_name }} TO ROLE {{ reader_role }};

GRANT USAGE ON DATABASE {{ data_db }} TO ROLE {{ deployer_role }};
GRANT USAGE ON DATABASE {{ data_db }} TO ROLE {{ reader_role }};

GRANT USAGE ON SCHEMA {{ data_db }}.{{ data_schema }} TO ROLE {{ deployer_role }};
GRANT USAGE ON SCHEMA {{ data_db }}.{{ data_schema }} TO ROLE {{ reader_role }};
