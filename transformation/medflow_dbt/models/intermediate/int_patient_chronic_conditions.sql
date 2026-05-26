{{
  config(
    materialized='ephemeral',
    tags=['intermediate', 'clinical']
  )
}}

/*
  Identifies patients with major chronic conditions, used by:
  - dim_patient enrichment
  - mart_chronic_disease_panel
  - mart_30day_readmission_rates (chronic patients are higher-risk)

  Source: SNOMED-CT codes from synthea.conditions
*/

with conditions as (

    select * from {{ ref('stg_synthea__conditions') }}

),

chronic_flags as (

    select
        patient_id,

        -- Diabetes (SNOMED includes 44054006 Type 2, 73211009 Diabetes mellitus)
        max(case when condition_description ilike '%diabetes%'
                 then 1 else 0 end) = 1                       as has_diabetes,

        -- Hypertension
        max(case when condition_description ilike '%hypertension%'
                 then 1 else 0 end) = 1                       as has_hypertension,

        -- Heart disease / CHF
        max(case when condition_description ilike '%heart failure%'
                  or condition_description ilike '%coronary%'
                  or condition_description ilike '%cardiac arrest%'
                 then 1 else 0 end) = 1                       as has_heart_disease,

        -- COPD / chronic respiratory
        max(case when condition_description ilike '%copd%'
                  or condition_description ilike '%chronic obstructive%'
                  or condition_description ilike '%emphysema%'
                 then 1 else 0 end) = 1                       as has_copd,

        -- Cancer (any active malignancy)
        max(case when (condition_description ilike '%cancer%'
                  or condition_description ilike '%malignant%'
                  or condition_description ilike '%carcinoma%'
                  or condition_description ilike '%neoplasm%')
                  and is_active = true
                 then 1 else 0 end) = 1                       as has_active_cancer,

        -- Chronic kidney disease
        max(case when condition_description ilike '%chronic kidney%'
                  or condition_description ilike '%renal failure%'
                 then 1 else 0 end) = 1                       as has_chronic_kidney_disease,

        -- Mental health
        max(case when condition_description ilike '%depression%'
                  or condition_description ilike '%anxiety%'
                  or condition_description ilike '%bipolar%'
                 then 1 else 0 end) = 1                       as has_mental_health_condition,

        count(distinct condition_code)                        as distinct_condition_count

    from conditions
    group by patient_id

),

final as (

    select
        patient_id,
        has_diabetes,
        has_hypertension,
        has_heart_disease,
        has_copd,
        has_active_cancer,
        has_chronic_kidney_disease,
        has_mental_health_condition,
        distinct_condition_count,

        -- Composite: any chronic condition
        (has_diabetes or has_hypertension or has_heart_disease
         or has_copd or has_active_cancer or has_chronic_kidney_disease) as has_any_chronic_condition,

        -- Multimorbidity count
        cast(has_diabetes as integer) + cast(has_hypertension as integer)
            + cast(has_heart_disease as integer) + cast(has_copd as integer)
            + cast(has_active_cancer as integer) + cast(has_chronic_kidney_disease as integer)
            + cast(has_mental_health_condition as integer)              as chronic_condition_count

    from chronic_flags

)

select * from final