{{ config(materialized='view', tags=['staging', 'synthea', 'clinical_event']) }}

with source as (select * from {{ source('synthea', 'careplans') }}),

renamed as (
    select
        id::varchar              as careplan_id,
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        code::varchar            as careplan_code,
        description::varchar     as careplan_description,
        reasoncode::varchar      as reason_code,
        reasondescription::varchar as reason_description,
        start::date              as careplan_start_date,
        stop::date               as careplan_end_date,
        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id
    from source
)

select * from renamed