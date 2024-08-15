{% macro extract_conversion_rate(json_column, json_path="$.USD") %}
  cast(json_extract_scalar({{ json_column }}, '{{ json_path }}') as numeric)
{% endmacro %}