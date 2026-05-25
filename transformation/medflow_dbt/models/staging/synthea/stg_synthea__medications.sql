{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'clinical_event']
  )
}}

with source as (
    select * from {{ source('synthea', 'medications') }}
),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        payer::varchar           as payer_id,
        code::varchar            as medication_code,
        description::varchar     as medication_description,
        reasoncode::varchar      as reason_code,
        reasondescription::varchar as reason_description,

        start::timestamp         as medication_start_at,
        stop::timestamp          as medication_end_at,

        base_cost::double            as base_cost,
        payer_coverage::double       as payer_coverage,
        dispenses::integer           as dispense_count,
        totalcost::double            as total_cost,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed