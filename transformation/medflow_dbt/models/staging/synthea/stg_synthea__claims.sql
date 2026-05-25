{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'financial']
  )
}}

with source as (
    select * from {{ source('synthea', 'claims') }}
),

renamed as (
    select
        id::varchar                              as claim_id,
        patientid::varchar                       as patient_id,
        providerid::varchar                      as provider_id,
        supervisingproviderid::varchar           as supervising_provider_id,

        primarypatientinsuranceid::varchar       as primary_insurance_id,
        secondarypatientinsuranceid::varchar     as secondary_insurance_id,

        departmentid::varchar                    as department_id,
        patientdepartmentid::varchar             as patient_department_id,
        appointmentid::varchar                   as appointment_id,

        -- Diagnoses (cast to varchar; sources mix BIGINT/DOUBLE)
        diagnosis1::varchar                      as diagnosis_1,
        diagnosis2::varchar                      as diagnosis_2,
        diagnosis3::varchar                      as diagnosis_3,
        diagnosis4::varchar                      as diagnosis_4,
        diagnosis5::varchar                      as diagnosis_5,
        diagnosis6::varchar                      as diagnosis_6,
        diagnosis7::varchar                      as diagnosis_7,
        diagnosis8::varchar                      as diagnosis_8,

        -- Dates
        currentillnessdate::timestamp            as current_illness_date,
        servicedate::timestamp                   as service_date,

        -- Status / billing tracking (primary, secondary, patient)
        status1::varchar                         as primary_status,
        status2::varchar                         as secondary_status,
        statusp::varchar                         as patient_status,
        outstanding1::double                     as primary_outstanding,
        outstanding2::double                     as secondary_outstanding,
        outstandingp::double                     as patient_outstanding,
        lastbilleddate1::timestamp               as last_billed_date_primary,
        lastbilleddate2::timestamp               as last_billed_date_secondary,
        lastbilleddatep::timestamp               as last_billed_date_patient,
        healthcareclaimtypeid1::varchar          as claim_type_id_primary,
        healthcareclaimtypeid2::varchar          as claim_type_id_secondary,

        _dlt_load_id::varchar                    as _dlt_load_id,
        _dlt_id::varchar                         as _dlt_record_id

    from source
)

select * from renamed