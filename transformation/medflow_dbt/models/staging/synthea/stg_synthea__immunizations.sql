{{ config(materialized='view', tags=['staging', 'synthea', 'clinical_event']) }}

with source as (select * from {{ source('synthea', 'immunizations') }}),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        date::timestamp          as immunization_date,
        code::varchar            as immunization_code,
        description::varchar     as immunization_description,
        base_cost::double        as base_cost,
        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id
    from source
)

select * from renamed