{{ 
    config(
        materialized='table'
        ) 
}}

select 
      a.external_ref
    , a.status
    , a.source
    , a.ref
    , a.date_time
    , a.state
    , a.cvv_provided
    , a.amount
    , a.country
    , a.currency
    , a.rates
    , c.chargeback
    , {{ extract_conversion_rate('a.rates') }} as usd_rate
    , round(a.amount * {{ extract_conversion_rate('a.rates') }}, 2) as usd_amount
    , {{ extract_conversion_rate('a.rates','$.GBP') }} as gbp_rate
    , round(a.amount * {{ extract_conversion_rate('a.rates','$.GBP') }}, 2) as gbp_amount
from {{ ref('stg_globepay_acceptance_report') }} as a
left join {{ ref('stg_globepay_chargeback_report') }} as c 
    on a.external_ref = c.external_ref