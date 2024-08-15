{{ 
    config(
        materialized='table'
        ) 
}}

select 
      external_ref
    , status
    , source
    , ref
    , cast(date_time as timestamp) as date_time
    , state
    , cvv_provided
    , amount
    , country
    , currency
    , rates
from {{ ref('source_globepay_acceptance_report') }}