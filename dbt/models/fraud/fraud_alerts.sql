{{
    config(
        materialized='table'
        )
}}

select
    date_trunc(date_time, day) as alert_date
    , country
    , risk_level
    , count(*) as transaction_count
    , sum(usd_amount) as total_usd_amount
    , sum(case when state = 'ACCEPTED' then 1 else 0 end) as accepted_count
    , sum(case when state = 'ACCEPTED' then usd_amount else 0 end) as accepted_usd_amount
    , sum(case when chargeback then 1 else 0 end) as chargeback_count
    , avg(overall_risk_score) as avg_risk_score
    , max(overall_risk_score) as max_risk_score
    , count(case when not cvv_provided then 1 else null end) as no_cvv_count
    , count(case when transactions_today_by_country > 50 then 1 else null end) as high_volume_count
from {{ ref('fraud_risk_score') }}
group by
    alert_date
    , country
    , risk_level
order by
    alert_date desc
    , country
    , risk_level
