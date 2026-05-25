{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'reference']
  )
}}

with source as (
    select * from {{ source('synthea', 'organizations') }}
),

renamed as (
    select
        id::varchar              as organization_id,
        name::varchar            as organization_name,
        address::varchar         as street_address,
        city::varchar            as city,
        state::varchar           as state,
        zip::varchar             as zip_code,
        lat::double              as latitude,
        lon::double              as longitude,
        phone::varchar           as phone,
        revenue::double          as revenue,
        utilization::double      as utilization,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed