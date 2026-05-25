{{ config(materialized='view', tags=['staging', 'synthea', 'clinical_event']) }}

with source as (select * from {{ source('synthea', 'devices') }}),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        code::varchar            as device_code,
        description::varchar     as device_description,
        udi::varchar             as udi,
        start::timestamp         as device_start_at,
        stop::timestamp          as device_end_at,
        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id
    from source
)

select * from renamed