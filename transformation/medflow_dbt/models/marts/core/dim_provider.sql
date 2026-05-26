{{
  config(
    materialized='table',
    tags=['marts', 'dimension', 'core']
  )
}}

with providers as (

    select * from {{ ref('stg_synthea__providers') }}

),

organizations as (

    select * from {{ ref('stg_synthea__organizations') }}

),

final as (

    select
        {{ dbt_utils.generate_surrogate_key(['p.provider_id']) }}    as provider_sk,
        p.provider_id,
        p.provider_name,
        p.gender                                                      as provider_gender,
        p.specialty,

        -- Organization context
        p.organization_id,
        o.organization_name,

        -- Location (provider)
        p.street_address                                              as provider_street_address,
        p.city                                                        as provider_city,
        p.state                                                       as provider_state,
        p.zip_code                                                    as provider_zip_code,
        p.latitude                                                    as provider_latitude,
        p.longitude                                                   as provider_longitude,

        -- Volume metrics
        p.encounter_count,
        p.procedure_count

    from providers p
    left join organizations o on p.organization_id = o.organization_id

)

select * from final