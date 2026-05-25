{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'clinical_event', 'high_volume']
  )
}}

with source as (
    select * from {{ source('synthea', 'observations') }}
),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        category::varchar        as observation_category,
        code::varchar            as observation_code,
        description::varchar     as observation_description,
        type::varchar            as value_type,

        date::timestamp          as observed_at,
        value::varchar           as observation_value,
        units::varchar           as units,

        -- Cast numeric observations to a number column (null if non-numeric)
        try_cast(value as double) as observation_value_numeric,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed