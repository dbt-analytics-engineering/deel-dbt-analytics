{{ 
    config(
        materialized='table'
        ) 
}}

select 
      external_ref
    , status
    , source
    , chargeback
from {{ ref('source_globepay_chargeback_report') }}