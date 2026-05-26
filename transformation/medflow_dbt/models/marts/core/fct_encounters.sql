{{
  config(
    materialized='table',
    tags=['marts', 'fact', 'core']
  )
}}

/*
  Encounter fact — one row per clinical encounter.
  Grain: encounter_id (unique)
*/

with encounters_enriched as (

    select * from {{ ref('int_encounter_outcomes') }}

),

dim_patient as (

    select patient_sk, patient_id from {{ ref('dim_patient') }}

),

dim_provider as (

    select provider_sk, provider_id from {{ ref('dim_provider') }}

),

final as (

    select
        -- Degenerate dimension (natural key as a fact column)
        e.encounter_id,

        -- FK to dimensions (surrogate keys)
        p.patient_sk,
        pr.provider_sk,

        -- FK to date dimension
        cast(strftime(e.encounter_start_at, '%Y%m%d') as integer)    as encounter_start_date_key,
        cast(strftime(e.encounter_end_at,   '%Y%m%d') as integer)    as encounter_end_date_key,

        -- Natural keys preserved for joining/filtering
        e.patient_id,
        e.provider_id,
        e.organization_id,
        e.payer_id,

        -- Descriptive attributes
        e.encounter_class,
        e.encounter_code,
        e.encounter_description,

        -- Timestamps
        e.encounter_start_at,
        e.encounter_end_at,

        -- Measures
        e.duration_minutes,
        e.base_encounter_cost,
        e.total_claim_cost,
        e.payer_coverage,
        coalesce(e.total_claim_cost - e.payer_coverage, 0)            as patient_responsibility,

        -- Derived clinical outcomes (from intermediate)
        e.encounter_sequence_num,
        e.days_until_next_encounter,
        e.days_since_previous_same_class,
        e.is_30day_readmission

    from encounters_enriched e
    left join dim_patient  p  on e.patient_id  = p.patient_id
    left join dim_provider pr on e.provider_id = pr.provider_id

)

select * from final