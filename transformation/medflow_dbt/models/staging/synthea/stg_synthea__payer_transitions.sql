{{ config(materialized='view', tags=['staging', 'synthea', 'reference']) }}

with source as (select * from {{ source('synthea', 'payer_transitions') }}),

renamed as (
    select
        patient::varchar         as patient_id,
        memberid::varchar        as member_id,
        start_date::date         as coverage_start_date,
        end_date::date           as coverage_end_date,
        payer::varchar           as payer_id,
        secondary_payer::varchar as secondary_payer_id,
        plan_ownership::varchar  as plan_ownership,
        owner_name::varchar      as owner_name,
        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id
    from source
)

select * from renamed