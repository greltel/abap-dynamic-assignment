"! <p class="shorttext synchronized" lang="EN">Type checks on configured values</p>
"! Production implementation of {@link ZIF_DA_VALUE_CHECK}, built on RTTS.
CLASS zcl_da_value_check DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_da_value_check.

  PRIVATE SECTION.

    TYPES ty_month_lengths TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    CONSTANTS digits      TYPE string VALUE `0123456789` ##NO_TEXT.
    CONSTANTS date_length TYPE i VALUE 8.
    CONSTANTS time_length TYPE i VALUE 6.
    CONSTANTS february    TYPE i VALUE 2.
    CONSTANTS leap_day    TYPE i VALUE 29.
    CONSTANTS max_year    TYPE i VALUE 9999.
    CONSTANTS max_month   TYPE i VALUE 12.
    CONSTANTS max_hour    TYPE i VALUE 23.
    CONSTANTS max_minute  TYPE i VALUE 59.
    CONSTANTS max_second  TYPE i VALUE 59.

    "! Rejects a value that a character like type would truncate or filter.
    "! @parameter value           | Value to convert
    "! @parameter data_element    | Configured data element, named in the message
    "! @parameter element         | Resolved type of the data element
    "! @raising   zcx_da_variants | The value does not survive the round trip
    METHODS check_round_trip
      IMPORTING value        TYPE zif_da_variants=>ty_value
                data_element TYPE zif_da_variants=>ty_data_el
                element      TYPE REF TO cl_abap_elemdescr
      RAISING   zcx_da_variants.

    "! Rejects a value that is not a day the calendar knows.
    "! @parameter value           | Value to check, expected as YYYYMMDD
    "! @parameter data_element    | Configured data element, named in the message
    "! @raising   zcx_da_variants | The value is no valid date
    METHODS check_date
      IMPORTING value        TYPE zif_da_variants=>ty_value
                data_element TYPE zif_da_variants=>ty_data_el
      RAISING   zcx_da_variants.

    "! Rejects a value that is not a time of day.
    "! @parameter value           | Value to check, expected as HHMMSS
    "! @parameter data_element    | Configured data element, named in the message
    "! @raising   zcx_da_variants | The value is no valid time
    METHODS check_time
      IMPORTING value        TYPE zif_da_variants=>ty_value
                data_element TYPE zif_da_variants=>ty_data_el
      RAISING   zcx_da_variants.

    "! Strips what a type adds by itself, so that only real losses remain visible.
    "! @parameter value     | Value to normalise
    "! @parameter type_kind | Type kind of the target, drives the leading zero rule
    "! @parameter result    | Comparable form of the value
    METHODS normalized
      IMPORTING value         TYPE zif_da_variants=>ty_value
                type_kind     TYPE abap_typekind
      RETURNING VALUE(result) TYPE string.

    "! Returns the last day the given month has in the given year.
    "! @parameter year   | Calendar year, drives the leap year rule
    "! @parameter month  | Calendar month between 1 and 12
    "! @parameter result | Last day of that month
    METHODS last_day_of_month
      IMPORTING year          TYPE i
                month         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! Answers whether February has 29 days in the given year.
    "! @parameter year   | Calendar year
    "! @parameter result | <em>abap_true</em> for a leap year
    METHODS is_leap_year
      IMPORTING year          TYPE i
      RETURNING VALUE(result) TYPE abap_boolean.

ENDCLASS.



CLASS zcl_da_value_check IMPLEMENTATION.


  METHOD zif_da_value_check~data_element_exists.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = data_element
                                         RECEIVING  p_descr_ref    = DATA(type)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    result = xsdbool( type->kind = cl_abap_typedescr=>kind_elem ).

  ENDMETHOD.


  METHOD zif_da_value_check~resolve_element_type.

    IF data_element IS INITIAL.
      result = CAST #( cl_abap_elemdescr=>describe_by_data( sample_value ) ).
      RETURN.
    ENDIF.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = data_element
                                         RECEIVING  p_descr_ref    = DATA(type)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_data_element
                                           msgv1  = data_element ).
    ENDIF.

    TRY.
        result = CAST #( type ).

      CATCH cx_sy_move_cast_error INTO DATA(cast_error).
        RAISE EXCEPTION NEW zcx_da_variants( textid   = zcx_da_variants=>invalid_data_element
                                             msgv1    = data_element
                                             previous = cast_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_da_value_check~convert.

    TRY.
        CREATE DATA result TYPE HANDLE element.
        ASSIGN result->* TO FIELD-SYMBOL(<target>).

        <target> = value.

      CATCH cx_sy_conversion_error cx_sy_create_data_error INTO DATA(conversion_error).
        RAISE EXCEPTION NEW zcx_da_variants( textid   = zcx_da_variants=>value_not_convertible
                                             msgv1    = data_element
                                             previous = conversion_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_da_value_check~check_value.

    " the native 255 character column holds anything, and nothing is lost from nothing
    IF value IS INITIAL OR data_element IS INITIAL.
      RETURN.
    ENDIF.

    DATA(element) = zif_da_value_check~resolve_element_type( data_element = data_element
                                                              sample_value = value ).

    CASE element->type_kind.

      WHEN cl_abap_typedescr=>typekind_date.
        check_date( value        = value
                    data_element = data_element ).

      WHEN cl_abap_typedescr=>typekind_time.
        check_time( value        = value
                    data_element = data_element ).

      WHEN cl_abap_typedescr=>typekind_char
        OR cl_abap_typedescr=>typekind_num
        OR cl_abap_typedescr=>typekind_string.
        " character like targets truncate and filter without raising anything
        check_round_trip( value        = value
                          data_element = data_element
                          element      = element ).

      WHEN OTHERS.
        " every other type reports on its own that the value does not fit
        zif_da_value_check~convert( value        = value
                                    data_element = data_element
                                    element      = element ).

    ENDCASE.

  ENDMETHOD.


  METHOD check_round_trip.

    DATA stored TYPE zif_da_variants=>ty_value.

    DATA(target) = zif_da_value_check~convert( value        = value
                                               data_element = data_element
                                               element      = element ).

    ASSIGN target->* TO FIELD-SYMBOL(<target>).

    " read the value back the way get_variant( ) would see it
    stored = <target>.

    IF normalized( value = stored type_kind = element->type_kind )
       <> normalized( value = value type_kind = element->type_kind ).
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>value_does_not_fit
                                           msgv1  = data_element ).
    ENDIF.

  ENDMETHOD.


  METHOD normalized.

    result = condense( CONV string( value ) ).

    " NUMC pads with leading zeros, which adds nothing and loses nothing
    IF type_kind = cl_abap_typedescr=>typekind_num.
      SHIFT result LEFT DELETING LEADING '0'.
    ENDIF.

  ENDMETHOD.


  METHOD check_date.

    " a date field is character like, so an impossible day is copied straight in
    DATA(text) = condense( CONV string( value ) ).

    IF strlen( text ) <> date_length OR text CN digits.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_date
                                           msgv1  = data_element ).
    ENDIF.

    DATA(year)  = CONV i( substring( val = text off = 0 len = 4 ) ).
    DATA(month) = CONV i( substring( val = text off = 4 len = 2 ) ).
    DATA(day)   = CONV i( substring( val = text off = 6 len = 2 ) ).

    IF year < 1 OR year > max_year OR month < 1 OR month > max_month.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_date
                                           msgv1  = data_element ).
    ENDIF.

    DATA(last_day) = last_day_of_month( year = year month = month ).

    IF day < 1 OR day > last_day.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_date
                                           msgv1  = data_element ).
    ENDIF.

  ENDMETHOD.


  METHOD check_time.

    DATA(text) = condense( CONV string( value ) ).

    IF strlen( text ) <> time_length OR text CN digits.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_time
                                           msgv1  = data_element ).
    ENDIF.

    DATA(hours)   = CONV i( substring( val = text off = 0 len = 2 ) ).
    DATA(minutes) = CONV i( substring( val = text off = 2 len = 2 ) ).
    DATA(seconds) = CONV i( substring( val = text off = 4 len = 2 ) ).

    IF hours > max_hour OR minutes > max_minute OR seconds > max_second.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_time
                                           msgv1  = data_element ).
    ENDIF.

  ENDMETHOD.


  METHOD last_day_of_month.

    DATA(lengths) = VALUE ty_month_lengths( ( 31 ) ( 28 ) ( 31 ) ( 30 ) ( 31 ) ( 30 )
                                            ( 31 ) ( 31 ) ( 30 ) ( 31 ) ( 30 ) ( 31 ) ).

    result = VALUE #( lengths[ month ] OPTIONAL ).

    IF month = february AND is_leap_year( year ) = abap_true.
      result = leap_day.
    ENDIF.

  ENDMETHOD.


  METHOD is_leap_year.

    result = xsdbool( ( year MOD 4 = 0 AND year MOD 100 <> 0 ) OR year MOD 400 = 0 ).

  ENDMETHOD.


ENDCLASS.
