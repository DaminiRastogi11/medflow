{{
  config(
    materialized='view',
    tags=['staging', 'synthea', 'financial', 'high_volume']
  )
}}

with source as (
    select * from {{ source('synthea', 'claims_transactions') }}
),

renamed as (
    select
        -- Identifiers
        id::varchar                     as transaction_id,
        claimid::varchar                as claim_id,
        chargeid::varchar               as charge_id,
        patientid::varchar              as patient_id,
        appointmentid::varchar          as appointment_id,
        patientinsuranceid::varchar     as patient_insurance_id,
        providerid::varchar             as provider_id,
        supervisingproviderid::varchar  as supervising_provider_id,
        departmentid::varchar           as department_id,
        feescheduleid::varchar          as fee_schedule_id,

        -- Transaction details
        type::varchar                   as transaction_type,
        method::varchar                 as payment_method,
        transfertype::varchar           as transfer_type,
        transferoutid::varchar          as transfer_out_id,
        notes::varchar                  as notes,

        -- Dates
        fromdate::timestamp             as from_date,
        todate::timestamp               as to_date,

        -- Service codes
        placeofservice::varchar         as place_of_service,
        procedurecode::varchar          as procedure_code,
        diagnosisref1::integer          as diagnosis_ref_1,
        diagnosisref2::integer          as diagnosis_ref_2,
        diagnosisref3::integer          as diagnosis_ref_3,
        diagnosisref4::integer          as diagnosis_ref_4,

        -- Financials
        amount::double                  as amount,
        unitamount::double              as unit_amount,
        units::integer                  as units,
        payments::double                as payments,
        adjustments::double             as adjustments,
        transfers::double               as transfers,
        outstanding::double             as outstanding,

        -- Audit
        _dlt_load_id::varchar           as _dlt_load_id,
        _dlt_id::varchar                as _dlt_record_id

    from source
)

select * from renamed