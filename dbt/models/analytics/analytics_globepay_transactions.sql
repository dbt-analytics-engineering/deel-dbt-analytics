{{ 
    config(
        materialized='table'
        ) 
}}

select 
      date_trunc(date_time, month) as transaction_month
    , country
    , sum(case when state = 'ACCEPTED' then usd_amount else 0 end) as accepted_amount
    , sum(case when state = 'DECLINED' then usd_amount else 0 end) as declined_amount
    , count(case when state = 'ACCEPTED' then ref else null end) as accepted_transactions
    , count(case when state = 'DECLINED' then ref else null end) as declined_transactions
    , count(case when chargeback then ref else null end) as chargeback_count
    , count(case when not chargeback then ref else null end) as no_chargeback_count
    , sum(usd_amount) as usd_amount
    , sum(gbp_amount) as gbp_amount
    , count(*) as total_transactions
from {{ ref('base_globepay_transactions') }}
group by transaction_month, country