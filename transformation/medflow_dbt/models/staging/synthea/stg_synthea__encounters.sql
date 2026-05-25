{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'core_entity']
  )
}}

with source as (
    select * from {{ source('synthea', 'encounters') }}
),

renamed as (
    select
        id::varchar              as encounter_id,
        patient::varchar         as patient_id,
        organization::varchar    as organization_id,
        provider::varchar        as provider_id,
        payer::varchar           as payer_id,
        encounterclass::varchar  as encounter_class,
        code::varchar            as encounter_code,
        description::varchar     as encounter_description,
        reasoncode::varchar      as reason_code,
        reasondescription::varchar as reason_description,

        start::timestamp         as encounter_start_at,
        stop::timestamp          as encounter_end_at,
        date_diff('minute', start::timestamp, stop::timestamp) as duration_minutes,

        base_encounter_cost::double  as base_encounter_cost,
        total_claim_cost::double     as total_claim_cost,
        payer_coverage::double       as payer_coverage,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed