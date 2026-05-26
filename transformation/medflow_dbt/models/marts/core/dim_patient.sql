{{
  config(
    materialized='table',
    tags=['marts', 'dimension', 'core']
  )
}}

/*
  Patient dimension — one row per patient.

  Note: For a full SCD Type 2 implementation, you would use dbt snapshots
  to track address changes over time. The base Synthea dataset is a point-
  in-time snapshot, so each patient has one current row. The SCD Type 2
  scaffolding (effective dates, current flag, surrogate key) is in place
  for when historical change tracking is added.
*/

with patients as (

    select * from {{ ref('stg_synthea__patients') }}

),

chronic as (

    select * from {{ ref('int_patient_chronic_conditions') }}

),

final as (

    select
        -- Surrogate key (would be a hash for SCD Type 2 with effective dates)
        {{ dbt_utils.generate_surrogate_key(['p.patient_id']) }}    as patient_sk,

        -- Natural key
        p.patient_id,

        -- Identity
        p.first_name,
        p.middle_name,
        p.last_name,
        p.maiden_name,
        coalesce(p.first_name || ' ' || p.last_name, '(unknown)')   as full_name,

        -- Demographics
        p.gender,
        p.race,
        p.ethnicity,
        p.marital_status,

        -- Dates
        p.birth_date,
        p.death_date,
        p.is_deceased,
        p.current_age_or_age_at_death                               as current_age,

        case
            when p.current_age_or_age_at_death < 18 then 'Pediatric (0-17)'
            when p.current_age_or_age_at_death < 35 then 'Young Adult (18-34)'
            when p.current_age_or_age_at_death < 50 then 'Adult (35-49)'
            when p.current_age_or_age_at_death < 65 then 'Middle-Aged (50-64)'
            when p.current_age_or_age_at_death < 80 then 'Senior (65-79)'
            else 'Elderly (80+)'
        end                                                          as age_bracket,

        -- Address
        p.street_address,
        p.city,
        p.state,
        p.county,
        p.zip_code,
        p.latitude,
        p.longitude,

        -- Financials
        p.lifetime_healthcare_expenses,
        p.lifetime_healthcare_coverage,
        coalesce(p.lifetime_healthcare_expenses - p.lifetime_healthcare_coverage, 0)
                                                                     as lifetime_out_of_pocket,
        p.annual_income,

        -- Clinical risk flags (from intermediate)
        coalesce(c.has_diabetes, false)                              as has_diabetes,
        coalesce(c.has_hypertension, false)                          as has_hypertension,
        coalesce(c.has_heart_disease, false)                         as has_heart_disease,
        coalesce(c.has_copd, false)                                  as has_copd,
        coalesce(c.has_active_cancer, false)                         as has_active_cancer,
        coalesce(c.has_chronic_kidney_disease, false)                as has_chronic_kidney_disease,
        coalesce(c.has_mental_health_condition, false)               as has_mental_health_condition,
        coalesce(c.has_any_chronic_condition, false)                 as has_any_chronic_condition,
        coalesce(c.chronic_condition_count, 0)                       as chronic_condition_count,
        coalesce(c.distinct_condition_count, 0)                      as distinct_condition_count,

        -- SCD Type 2 scaffolding
        cast(p.birth_date as timestamp)                              as effective_from,
        cast('9999-12-31' as timestamp)                              as effective_to,
        true                                                          as is_current

    from patients p
    left join chronic c on p.patient_id = c.patient_id

)

select * from final