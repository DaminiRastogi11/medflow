{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'reference']
  )
}}

with source as (
    select * from {{ source('synthea', 'providers') }}
),

renamed as (
    select
        id::varchar              as provider_id,
        organization::varchar    as organization_id,
        name::varchar            as provider_name,
        gender::varchar          as gender,
        speciality::varchar      as specialty,

        address::varchar         as street_address,
        city::varchar            as city,
        state::varchar           as state,
        zip::varchar             as zip_code,
        lat::double              as latitude,
        lon::double              as longitude,

        encounters::integer      as encounter_count,
        procedures::integer      as procedure_count,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed