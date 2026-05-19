GRANT USAGE ON WAREHOUSE {{ warehouse_name }} TO ROLE {{ reader_role }};

GRANT USAGE ON DATABASE {{ data_db }} TO ROLE {{ reader_role }};
GRANT USAGE ON SCHEMA {{ data_db }}.{{ data_schema }} TO ROLE {{ reader_role }};
GRANT USAGE ON SCHEMA {{ data_db }}.{{ analytics_schema }} TO ROLE {{ reader_role }};

GRANT SELECT ON TABLE {{ data_db }}.{{ data_schema }}.CUSTOMERS TO ROLE {{ reader_role }};
GRANT SELECT ON TABLE {{ data_db }}.{{ data_schema }}.ORDERS TO ROLE {{ reader_role }};
GRANT SELECT ON VIEW {{ data_db }}.{{ analytics_schema }}.DAILY_ORDER_SUMMARY TO ROLE {{ reader_role }};
