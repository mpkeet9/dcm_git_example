DEFINE WAREHOUSE {{ warehouse_name }}
  WITH
    warehouse_size = '{{ warehouse_size }}'
    auto_suspend = 60
    auto_resume = TRUE;

DEFINE DATABASE {{ data_db }};

DEFINE SCHEMA {{ data_db }}.{{ data_schema }};
DEFINE SCHEMA {{ data_db }}.{{ analytics_schema }};
