DEFINE WAREHOUSE {{ warehouse_name }}
  WITH
    warehouse_size = '{{ warehouse_size }}'
    auto_suspend = 60
    auto_resume = TRUE
    initially_suspended = TRUE;

DEFINE DATABASE {{ data_db }};

DEFINE SCHEMA {{ data_db }}.{{ data_schema }};
DEFINE SCHEMA {{ data_db }}.{{ analytics_schema }};

GRANT USAGE ON WAREHOUSE {{ warehouse_name }} TO ROLE {{ deployer_role }};
GRANT USAGE ON WAREHOUSE {{ warehouse_name }} TO ROLE {{ reader_role }};

GRANT USAGE ON DATABASE {{ data_db }} TO ROLE {{ deployer_role }};
GRANT USAGE ON DATABASE {{ data_db }} TO ROLE {{ reader_role }};

GRANT USAGE ON SCHEMA {{ data_db }}.{{ data_schema }} TO ROLE {{ deployer_role }};
GRANT USAGE ON SCHEMA {{ data_db }}.{{ data_schema }} TO ROLE {{ reader_role }};
