{{
  config(
    materialized='table',
    tags=['marts', 'analytics', 'clinical_quality']
  )
}}

/*
  30-day readmission rate analytics.

  Answers: "What's our 30-day inpatient readmission rate, and how does it
  break down by demographics and chronic conditions?"

  Readmission rates are a CMS quality metric tied directly to reimbursement.
*/

with inpatient_encounters as (

    select
        f.encounter_id,
        f.patient_id,
        f.encounter_start_at,
        f.is_30day_readmission,
        date_trunc('month', f.encounter_start_at)::date    as encounter_month,
        d.age_bracket,
        d.gender,
        d.race,
        d.has_any_chronic_condition,
        d.chronic_condition_count
    from {{ ref('fct_encounters') }}     f
    join {{ ref('dim_patient') }}        d on f.patient_id = d.patient_id
    where f.encounter_class = 'inpatient'

),

by_demographic as (

    select
        age_bracket,
        gender,
        count(*)                                                       as total_inpatient_encounters,
        sum(case when is_30day_readmission then 1 else 0 end)          as readmissions_30d,
        round(
            100.0 * sum(case when is_30day_readmission then 1 else 0 end) / count(*),
            2
        )                                                              as readmission_rate_pct
    from inpatient_encounters
    group by age_bracket, gender

),

by_chronic_status as (

    select
        case when has_any_chronic_condition then 'Chronic' else 'Non-Chronic' end as patient_segment,
        chronic_condition_count,
        count(*)                                                       as total_inpatient_encounters,
        sum(case when is_30day_readmission then 1 else 0 end)          as readmissions_30d,
        round(
            100.0 * sum(case when is_30day_readmission then 1 else 0 end) / count(*),
            2
        )                                                              as readmission_rate_pct
    from inpatient_encounters
    group by has_any_chronic_condition, chronic_condition_count

),

by_month as (

    select
        encounter_month,
        count(*)                                                       as total_inpatient_encounters,
        sum(case when is_30day_readmission then 1 else 0 end)          as readmissions_30d,
        round(
            100.0 * sum(case when is_30day_readmission then 1 else 0 end) / count(*),
            2
        )                                                              as readmission_rate_pct
    from inpatient_encounters
    group by encounter_month

),

unioned as (

    select
        'by_demographic'        as grouping_type,
        age_bracket             as group_value_1,
        gender                  as group_value_2,
        cast(null as integer)   as group_value_3_int,
        cast(null as date)      as group_month,
        total_inpatient_encounters,
        readmissions_30d,
        readmission_rate_pct
    from by_demographic

    union all

    select
        'by_chronic_status',
        patient_segment,
        null,
        chronic_condition_count,
        null,
        total_inpatient_encounters,
        readmissions_30d,
        readmission_rate_pct
    from by_chronic_status

    union all

    select
        'by_month',
        null,
        null,
        null,
        encounter_month,
        total_inpatient_encounters,
        readmissions_30d,
        readmission_rate_pct
    from by_month

)

select * from unioned