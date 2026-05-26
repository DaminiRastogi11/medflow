{{
  config(
    materialized='ephemeral',
    tags=['intermediate', 'clinical']
  )
}}

/*
  Enriches encounters with derived outcomes:
  - Days until next encounter (per patient)
  - 30-day readmission flag (inpatient class only)
  - Encounter sequence number for the patient

  Source: stg_synthea__encounters
*/

with encounters as (

    select * from {{ ref('stg_synthea__encounters') }}

),

with_lead as (

    select
        encounter_id,
        patient_id,
        provider_id,
        organization_id,
        payer_id,
        encounter_class,
        encounter_code,
        encounter_description,
        encounter_start_at,
        encounter_end_at,
        duration_minutes,
        base_encounter_cost,
        total_claim_cost,
        payer_coverage,

        -- Sequence number per patient
        row_number() over (
            partition by patient_id
            order by encounter_start_at
        ) as encounter_sequence_num,

        -- Next encounter start date for this patient
        lead(encounter_start_at) over (
            partition by patient_id
            order by encounter_start_at
        ) as next_encounter_start_at,

        -- Previous inpatient encounter (used for readmission detection)
        lag(encounter_start_at) over (
            partition by patient_id, encounter_class
            order by encounter_start_at
        ) as previous_same_class_encounter_at

    from encounters

),

with_derived as (

    select
        *,

        -- Days until next encounter (any class)
        case
            when next_encounter_start_at is not null
            then date_diff('day', encounter_start_at, next_encounter_start_at)
            else null
        end as days_until_next_encounter,

        -- Days since previous same-class encounter
        case
            when previous_same_class_encounter_at is not null
            then date_diff('day', previous_same_class_encounter_at, encounter_start_at)
            else null
        end as days_since_previous_same_class,

        -- 30-day readmission flag: inpatient encounter occurring within 30 days
        -- of a previous inpatient encounter for the same patient
        case
            when encounter_class = 'inpatient'
                 and previous_same_class_encounter_at is not null
                 and date_diff('day', previous_same_class_encounter_at, encounter_start_at) <= 30
            then true
            else false
        end as is_30day_readmission

    from with_lead

)

select * from with_derived