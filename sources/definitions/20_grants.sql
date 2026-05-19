GRANT SELECT ON TABLE {{ data_db }}.{{ data_schema }}.CUSTOMERS TO ROLE {{ reader_role }};
GRANT SELECT ON TABLE {{ data_db }}.{{ data_schema }}.ORDERS TO ROLE {{ reader_role }};
GRANT SELECT ON VIEW {{ data_db }}.{{ analytics_schema }}.DAILY_ORDER_SUMMARY TO ROLE {{ reader_role }};

GRANT USAGE ON SCHEMA {{ data_db }}.{{ analytics_schema }} TO ROLE {{ reader_role }};

-- The deployer role remains the managing role for DCM-owned objects in this sample.
GRANT OWNERSHIP ON TABLE {{ data_db }}.{{ data_schema }}.CUSTOMERS TO ROLE {{ deployer_role }} COPY CURRENT GRANTS;
GRANT OWNERSHIP ON TABLE {{ data_db }}.{{ data_schema }}.ORDERS TO ROLE {{ deployer_role }} COPY CURRENT GRANTS;
GRANT OWNERSHIP ON VIEW {{ data_db }}.{{ analytics_schema }}.DAILY_ORDER_SUMMARY TO ROLE {{ deployer_role }} COPY CURRENT GRANTS;
