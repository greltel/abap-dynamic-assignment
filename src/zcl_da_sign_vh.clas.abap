"! <p class="shorttext synchronized" lang="EN">Custom Entity Implementation for Sign Value Help</p>
"! Serves the fixed values of domain <em>ZDO_DA_SIGN</em> to {@link ZI_DA_SIGN_VH}.
CLASS zcl_da_sign_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider.

  PRIVATE SECTION.

    TYPES ty_signs      TYPE STANDARD TABLE OF zi_da_sign_vh WITH EMPTY KEY.
    TYPES ty_sign_range TYPE RANGE OF zde_da_sign.

    CONSTANTS element_sign TYPE string VALUE `SIGN` ##NO_TEXT.

    "! Reads the domain fixed values in the logon language of the current user.
    "! @parameter result                    | One entry per fixed value
    METHODS read_fixed_values
      RETURNING VALUE(result) TYPE ty_signs
       RAISING   cx_rap_query_provider.

    "! Extracts the type ahead filter of the value help dialog.
    "! @parameter request | Query request of the RAP runtime
    "! @parameter result  | Range over the sign element, empty when unfiltered
    METHODS filter_from_request
      IMPORTING request       TYPE REF TO if_rap_query_request
      RETURNING VALUE(result) TYPE ty_sign_range.

ENDCLASS.



CLASS ZCL_DA_SIGN_VH IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    DATA(signs)  = read_fixed_values( ).
    DATA(filter) = filter_from_request( io_request ).

    IF filter IS NOT INITIAL.
      DELETE signs WHERE sign NOT IN filter.
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( signs ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( signs ).
    ENDIF.

  ENDMETHOD.


  METHOD read_fixed_values.

    DATA sign TYPE zde_da_sign.

    TRY.
        DATA(fixed_values) = CAST cl_abap_elemdescr(
                                 cl_abap_typedescr=>describe_by_data( sign )
                               )->get_ddic_fixed_values(
                                   cl_abap_context_info=>get_user_language_abap_format( ) ).

      CATCH cx_abap_context_info_error INTO DATA(context_error).
             RAISE EXCEPTION NEW zcx_da_query( previous = context_error ).
    ENDTRY.

    result = VALUE #( FOR fixed_value IN fixed_values
                      ( sign       = fixed_value-low
                        sign_descr = fixed_value-ddtext ) ).

  ENDMETHOD.


  METHOD filter_from_request.

    TRY.
        LOOP AT request->get_filter( )->get_as_ranges( ) INTO DATA(condition)
             WHERE name = element_sign.

          result = VALUE #( BASE result
                            FOR filter_range IN condition-range
                            ( sign   = filter_range-sign
                              option = filter_range-option
                              low    = filter_range-low
                              high   = filter_range-high ) ).

        ENDLOOP.
      CATCH cx_rap_query_filter_no_range.
    ENDTRY.

  ENDMETHOD.
ENDCLASS.
