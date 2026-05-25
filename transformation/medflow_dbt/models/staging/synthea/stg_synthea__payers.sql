{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'reference']
  )
}}

with source as (
    select * from {{ source('synthea', 'payers') }}
),

renamed as (
    select
        id::varchar                      as payer_id,
        name::varchar                    as payer_name,
        ownership::varchar               as ownership_type,

        amount_covered::double           as total_amount_covered,
        amount_uncovered::double         as total_amount_uncovered,
        revenue::double                  as revenue,

        covered_encounters::integer      as covered_encounter_count,
        uncovered_encounters::integer    as uncovered_encounter_count,
        covered_medications::integer     as covered_medication_count,
        uncovered_medications::integer   as uncovered_medication_count,
        covered_procedures::integer      as covered_procedure_count,
        uncovered_procedures::integer    as uncovered_procedure_count,
        covered_immunizations::integer   as covered_immunization_count,
        uncovered_immunizations::integer as uncovered_immunization_count,

        unique_customers::integer        as unique_customer_count,
        qols_avg::double                 as quality_of_life_score_avg,
        member_months::integer           as member_months,

        _dlt_load_id::varchar            as _dlt_load_id,
        _dlt_id::varchar                 as _dlt_record_id

    from source
)

select * from renamed