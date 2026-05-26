{{
  config(
    materialized='table',
    tags=['marts', 'analytics', 'operations']
  )
}}

/*
  Provider performance scorecard — encounters, outcomes, and revenue per provider.

  Answers: "Which providers handle the most volume? Best readmission rates?
  Highest revenue? Are any outliers worth investigating?"
*/

with encounters as (

    select * from {{ ref('fct_encounters') }}

),

providers as (

    select * from {{ ref('dim_provider') }}

),

provider_aggregates as (

    select
        p.provider_sk,
        p.provider_id,
        p.provider_name,
        p.specialty,
        p.organization_name,

        -- Volume
        count(distinct e.encounter_id)                                 as total_encounters,
        count(distinct e.patient_id)                                   as unique_patients_seen,
        count(distinct case when e.encounter_class = 'inpatient'
                            then e.encounter_id end)                   as inpatient_encounters,
        count(distinct case when e.encounter_class = 'emergency'
                            then e.encounter_id end)                   as emergency_encounters,
        count(distinct case when e.encounter_class = 'ambulatory'
                            then e.encounter_id end)                   as ambulatory_encounters,

        -- Quality
        sum(case when e.is_30day_readmission then 1 else 0 end)        as readmissions_caused,
        round(
            100.0 * sum(case when e.is_30day_readmission then 1 else 0 end)
                  / nullif(count(distinct case when e.encounter_class = 'inpatient'
                                               then e.encounter_id end), 0),
            2
        )                                                              as readmission_rate_pct,

        -- Financials
        round(sum(e.total_claim_cost), 2)                              as total_billed,
        round(sum(e.payer_coverage), 2)                                as total_payer_coverage,
        round(sum(e.patient_responsibility), 2)                        as total_patient_responsibility,
        round(avg(e.total_claim_cost), 2)                              as avg_claim_cost_per_encounter,

        -- Utilization
        round(avg(e.duration_minutes), 1)                              as avg_encounter_duration_minutes

    from providers p
    left join encounters e on p.provider_id = e.provider_id
    group by p.provider_sk, p.provider_id, p.provider_name, p.specialty, p.organization_name

),

final as (

    select
        *,

        -- Rankings (useful for "top 10" dashboards)
        rank() over (order by total_encounters desc)                   as volume_rank,
        rank() over (order by total_billed desc nulls last)            as revenue_rank,
        rank() over (order by readmission_rate_pct asc nulls last)     as quality_rank_low_readmit

    from provider_aggregates
    where total_encounters > 0     -- exclude providers with no encounters

)

select * from final