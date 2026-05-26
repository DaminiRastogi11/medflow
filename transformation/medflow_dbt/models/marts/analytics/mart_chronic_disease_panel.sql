{{
  config(
    materialized='table',
    tags=['marts', 'analytics', 'population_health']
  )
}}

/*
  Chronic disease prevalence by demographic segment.

  Answers: "What's the prevalence of each major chronic condition in our
  patient population, broken down by age, gender, and race?"
*/

with patients as (

    select * from {{ ref('dim_patient') }}

),

by_age_gender as (

    select
        age_bracket,
        gender,
        count(*)                                                       as patient_count,

        sum(case when has_diabetes then 1 else 0 end)                  as diabetes_count,
        sum(case when has_hypertension then 1 else 0 end)              as hypertension_count,
        sum(case when has_heart_disease then 1 else 0 end)             as heart_disease_count,
        sum(case when has_copd then 1 else 0 end)                      as copd_count,
        sum(case when has_active_cancer then 1 else 0 end)             as cancer_count,
        sum(case when has_chronic_kidney_disease then 1 else 0 end)    as ckd_count,
        sum(case when has_mental_health_condition then 1 else 0 end)   as mental_health_count,

        round(100.0 * sum(case when has_diabetes then 1 else 0 end) / count(*), 2)              as diabetes_prevalence_pct,
        round(100.0 * sum(case when has_hypertension then 1 else 0 end) / count(*), 2)          as hypertension_prevalence_pct,
        round(100.0 * sum(case when has_heart_disease then 1 else 0 end) / count(*), 2)         as heart_disease_prevalence_pct,
        round(100.0 * sum(case when has_copd then 1 else 0 end) / count(*), 2)                  as copd_prevalence_pct,
        round(100.0 * sum(case when has_active_cancer then 1 else 0 end) / count(*), 2)         as cancer_prevalence_pct,
        round(100.0 * sum(case when has_chronic_kidney_disease then 1 else 0 end) / count(*), 2) as ckd_prevalence_pct,
        round(100.0 * sum(case when has_mental_health_condition then 1 else 0 end) / count(*), 2) as mental_health_prevalence_pct,

        round(avg(chronic_condition_count), 2)                         as avg_chronic_conditions_per_patient,
        round(avg(lifetime_healthcare_expenses), 0)                    as avg_lifetime_expenses

    from patients
    group by age_bracket, gender

)

select * from by_age_gender