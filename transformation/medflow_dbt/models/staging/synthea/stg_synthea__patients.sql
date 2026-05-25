{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'core_entity']
  )
}}

with source as (

    select * from {{ source('synthea', 'patients') }}

),

renamed as (

    select
        -- Identifiers
        id::varchar              as patient_id,
        ssn::varchar             as social_security_number,
        drivers::varchar         as drivers_license_number,
        passport::varchar        as passport_number,

        -- Name
        prefix::varchar          as name_prefix,
        first::varchar           as first_name,
        middle::varchar          as middle_name,
        last::varchar            as last_name,
        suffix::varchar          as name_suffix,
        maiden::varchar          as maiden_name,

        -- Demographics
        marital::varchar         as marital_status,
        race::varchar            as race,
        ethnicity::varchar       as ethnicity,
        gender::varchar          as gender,
        birthplace::varchar      as birthplace,

        -- Address
        address::varchar         as street_address,
        city::varchar            as city,
        state::varchar           as state,
        county::varchar          as county,
        zip::varchar             as zip_code,
        lat::double              as latitude,
        lon::double              as longitude,

        -- Lifecycle
        birthdate::date          as birth_date,
        deathdate::date          as death_date,
        case when deathdate is not null then true else false end as is_deceased,

        -- Financials
        healthcare_expenses::double as lifetime_healthcare_expenses,
        healthcare_coverage::double as lifetime_healthcare_coverage,
        income::double              as annual_income,

        -- Calculated columns
        case
            when deathdate is not null
                then date_diff('year', birthdate::date, deathdate::date)
            else date_diff('year', birthdate::date, current_date)
        end                       as current_age_or_age_at_death,

        -- Audit
        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source

)

select * from renamed