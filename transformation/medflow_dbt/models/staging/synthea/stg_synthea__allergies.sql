{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'clinical_event']
  )
}}

with source as (
    select * from {{ source('synthea', 'allergies') }}
),

renamed as (
    select
        patient::varchar         as patient_id,
        encounter::varchar       as encounter_id,
        code::varchar            as allergy_code,
        system::varchar          as code_system,
        description::varchar     as allergy_description,
        type::varchar            as allergy_type,
        category::varchar        as allergy_category,

        start::date              as allergy_start_date,

        -- Reactions (up to 2 per allergy)
        reaction1::varchar       as reaction_1,
        description1::varchar    as reaction_1_description,
        severity1::varchar       as reaction_1_severity,
        reaction2::varchar       as reaction_2,
        description2::varchar    as reaction_2_description,
        severity2::varchar       as reaction_2_severity,

        _dlt_load_id::varchar    as _dlt_load_id,
        _dlt_id::varchar         as _dlt_record_id

    from source
)

select * from renamed