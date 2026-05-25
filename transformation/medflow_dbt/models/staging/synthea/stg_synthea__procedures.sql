{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'clinical_event']
  )
}}

with source as (
    select * from {{ source('synthea', 'procedures') }}
),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        system::varchar          as code_system,
        code::varchar            as procedure_code,
        description::varchar     as procedure_description,
        reasoncode::varchar      as reason_code,
        reasondescription::varchar as reason_description,

        start::timestamp         as procedure_start_at,
        stop::timestamp          as procedure_end_at,
        base_cost::double            as base_cost,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed