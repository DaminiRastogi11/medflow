{{ config(materialized='view', tags=['staging', 'synthea', 'clinical_event']) }}

with source as (select * from {{ source('synthea', 'imaging_studies') }}),

renamed as (
    select
        id::varchar              as imaging_study_id,
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        date::timestamp          as study_date,
        series_uid::varchar      as series_uid,
        bodysite_code::varchar   as bodysite_code,
        bodysite_description::varchar as bodysite_description,
        modality_code::varchar   as modality_code,
        modality_description::varchar as modality_description,
        instance_uid::varchar    as instance_uid,
        sop_code::varchar        as sop_code,
        sop_description::varchar as sop_description,
        procedure_code::varchar  as procedure_code,
        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id
    from source
)

select * from renamed