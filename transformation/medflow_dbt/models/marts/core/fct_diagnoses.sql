{{
  config(
    materialized='table',
    tags=['marts', 'fact', 'core']
  )
}}

/*
  Diagnosis fact — one row per patient diagnosis.
  Grain: patient_id + condition_code + condition_start_date
*/

with conditions as (

    select * from {{ ref('stg_synthea__conditions') }}

),

dim_patient as (

    select patient_sk, patient_id from {{ ref('dim_patient') }}

),

final as (

    select
        -- Surrogate key for the diagnosis row
        {{ dbt_utils.generate_surrogate_key([
            'c.patient_id',
            'c.condition_code',
            'c.condition_start_date',
            'c.encounter_id'
        ]) }}                                                          as diagnosis_sk,

        -- FK to dimensions
        p.patient_sk,

        -- FK to date dimension
        cast(strftime(c.condition_start_date, '%Y%m%d') as integer)    as condition_start_date_key,
        case when c.condition_end_date is not null
             then cast(strftime(c.condition_end_date, '%Y%m%d') as integer)
             else null end                                              as condition_end_date_key,

        -- Natural keys / degenerate dims
        c.patient_id,
        c.encounter_id,
        c.condition_code,
        c.code_system,
        c.condition_description,

        -- Dates
        c.condition_start_date,
        c.condition_end_date,

        -- Measures
        c.duration_days,
        c.is_active

    from conditions c
    left join dim_patient p on c.patient_id = p.patient_id

)

select * from final