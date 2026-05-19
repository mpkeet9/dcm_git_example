{% macro obj_name(base_name) -%}
{{ app_name }}_{{ env_code }}_{{ base_name }}
{%- endmacro %}

{% macro qualified_schema() -%}
{{ data_db }}.{{ data_schema }}
{%- endmacro %}
