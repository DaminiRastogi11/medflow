{{
  config(
    materialized='table',
    tags=['marts', 'dimension', 'core']
  )
}}

with date_spine as (

    -- Generate ~75 years of dates: 1950-01-01 through 2025-12-31
    -- Synthea data ranges across this period
    select
        cast(range as date) as date_day
    from range(date '1950-01-01', date '2026-01-01', interval 1 day)

),

calendar as (

    select
        -- Surrogate key (YYYYMMDD as int — classic data warehouse pattern)
        cast(strftime(date_day, '%Y%m%d') as integer)         as date_key,
        date_day                                              as full_date,

        -- Year
        extract(year from date_day)::integer                  as year_number,
        cast(strftime(date_day, '%Y') as integer)             as calendar_year,

        -- Quarter
        extract(quarter from date_day)::integer               as quarter_number,
        'Q' || extract(quarter from date_day)::varchar        as quarter_name,

        -- Month
        extract(month from date_day)::integer                 as month_number,
        strftime(date_day, '%B')                              as month_name,
        strftime(date_day, '%b')                              as month_short_name,

        -- Week
        extract(week from date_day)::integer                  as week_of_year,

        -- Day
        extract(day from date_day)::integer                   as day_of_month,
        extract(dayofyear from date_day)::integer             as day_of_year,
        extract(dayofweek from date_day)::integer             as day_of_week_number,
        strftime(date_day, '%A')                              as day_name,
        strftime(date_day, '%a')                              as day_short_name,

        -- Boolean flags
        case when extract(dayofweek from date_day) in (0, 6)
             then true else false end                         as is_weekend,
        case when extract(dayofweek from date_day) in (1, 2, 3, 4, 5)
             then true else false end                         as is_weekday,

        -- US Federal Holidays (simplified — just the major fixed ones)
        case
            when strftime(date_day, '%m-%d') = '01-01' then 'New Year''s Day'
            when strftime(date_day, '%m-%d') = '07-04' then 'Independence Day'
            when strftime(date_day, '%m-%d') = '12-25' then 'Christmas Day'
            when strftime(date_day, '%m-%d') = '11-11' then 'Veterans Day'
            else null
        end                                                   as us_federal_holiday,
        case
            when strftime(date_day, '%m-%d') in ('01-01', '07-04', '12-25', '11-11')
            then true else false
        end                                                   as is_us_federal_holiday,

        -- Fiscal year (assume Oct 1 fiscal start — common US federal pattern)
        case
            when extract(month from date_day) >= 10
            then extract(year from date_day) + 1
            else extract(year from date_day)
        end                                                   as fiscal_year,

        -- Relative date flags (useful for filtering in BI)
        case when date_day = current_date then true else false end  as is_today,
        case when date_day = current_date - 1 then true else false end as is_yesterday,
        case when extract(year from date_day) = extract(year from current_date)
             then true else false end                         as is_current_year

    from date_spine

)

select * from calendar