"! <p class="shorttext synchronized" lang="EN">Type checks on configured values</p>
"! Knows what a DDIC data element does to a value that is stored as text, and
"! rejects the values a type could not hold unchanged.
INTERFACE zif_da_value_check
  PUBLIC.

  "! Checks whether a name refers to an existing elementary DDIC type.
  "! @parameter data_element | Name to check
  "! @parameter result       | <em>abap_true</em> when an elementary data element exists
  METHODS data_element_exists
    IMPORTING data_element  TYPE zif_da_variants=>ty_data_el
    RETURNING VALUE(result) TYPE abap_boolean.

  "! Resolves the DDIC type of a variant column.
  "! @parameter data_element    | Configured data element, may be initial
  "! @parameter sample_value    | Fallback value used when no data element is configured
  "! @parameter result          | Element description of the resolved type
  "! @raising   zcx_da_variants | The configured data element does not exist
  METHODS resolve_element_type
    IMPORTING data_element  TYPE zif_da_variants=>ty_data_el
              sample_value  TYPE zif_da_variants=>ty_value
    RETURNING VALUE(result) TYPE REF TO cl_abap_elemdescr
    RAISING   zcx_da_variants.

  "! Writes the value into the given type and reports what the type refuses.
  "! @parameter value           | Value to convert
  "! @parameter data_element    | Configured data element, named in the message
  "! @parameter element         | Resolved type of the data element
  "! @parameter result          | Data reference holding the converted value
  "! @raising   zcx_da_variants | The conversion failed or overflowed
  METHODS convert
    IMPORTING value         TYPE zif_da_variants=>ty_value
              data_element  TYPE zif_da_variants=>ty_data_el
              element       TYPE REF TO cl_abap_elemdescr
    RETURNING VALUE(result) TYPE REF TO data
    RAISING   zcx_da_variants.

  "! Rejects a value that its configured data element could not hold unchanged.
  "! <p>Three losses happen without any runtime error and are caught here instead:
  "! <em>NUMC</em> keeps the digits of the source and drops the rest, <em>CHAR</em>
  "! truncates on the right, and a date field is character like, so a day that does
  "! not exist in the calendar is copied straight in.</p>
  "! <p>Leading zeros added by <em>NUMC</em> are not a loss and stay accepted.</p>
  "! @parameter value           | Value as it is stored in the configuration table
  "! @parameter data_element    | Configured type, initial for the native column type
  "! @raising   zcx_da_variants | The value would be truncated, filtered or is no date
  METHODS check_value
    IMPORTING value        TYPE zif_da_variants=>ty_value
              data_element TYPE zif_da_variants=>ty_data_el
    RAISING   zcx_da_variants.

ENDINTERFACE.
