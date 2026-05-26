{#-
    Custom generate_schema_name macro.

    Default dbt behavior: takes profile schema and APPENDS the model-level
    +schema config as a suffix (e.g., 'staging' + 'marts' = 'staging_marts').

    This override: when a custom_schema_name is provided, use it AS-IS
    instead of suffixing. Profile schema is used only when no custom schema
    is declared.

    Pattern reference: https://docs.getdbt.com/docs/build/custom-schemas
-#}

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}