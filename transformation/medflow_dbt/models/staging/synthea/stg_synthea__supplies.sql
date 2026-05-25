{{ config(materialized='view', tags=['staging', 'synthea', 'clinical_event']) }}

with source as (select * from {{ source('synthea', 'supplies') }}),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        date::timestamp          as supply_date,
        code::varchar            as supply_code,
        description::varchar     as supply_description,
        quantity::integer        as quantity,
        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id
    from source
)

select * from renamed