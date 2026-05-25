{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'clinical_event']
  )
}}

with source as (
    select * from {{ source('synthea', 'conditions') }}
),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        system::varchar          as code_system,
        code::varchar            as condition_code,
        description::varchar     as condition_description,

        start::date              as condition_start_date,
        stop::date               as condition_end_date,
        case
            when stop is null then true
            else false
        end                       as is_active,
        date_diff('day', start::date, coalesce(stop::date, current_date)) as duration_days,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed
