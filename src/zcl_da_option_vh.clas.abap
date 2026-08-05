"! <p class="shorttext synchronized" lang="EN">Custom Entity Implementation for Options Value Help</p>
"! Serves the fixed values of domain <em>ZDO_DA_OPT</em> to {@link ZI_DA_OPTION_VH}.
CLASS zcl_da_option_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider.

  PRIVATE SECTION.

    TYPES ty_options      TYPE STANDARD TABLE OF zi_da_option_vh WITH EMPTY KEY.
    TYPES ty_option_range TYPE RANGE OF zde_da_opt.

    CONSTANTS element_options TYPE string VALUE `OPTIONS` ##NO_TEXT.

    "! Reads the domain fixed values in the logon language of the current user.
    "! @parameter result                      | One entry per fixed value
    "! @raising   zcx_da_query | The user context could not be read
    METHODS read_fixed_values
      RETURNING VALUE(result) TYPE ty_options
      RAISING   zcx_da_query.

    "! Extracts the type ahead filter of the value help dialog.
    "! @parameter request | Query request of the RAP runtime
    "! @parameter result  | Range over the options element, empty when unfiltered
    METHODS filter_from_request
      IMPORTING request       TYPE REF TO if_rap_query_request
      RETURNING VALUE(result) TYPE ty_option_range.
ENDCLASS.



CLASS zcl_da_option_vh IMPLEMENTATION.


  METHOD if_rap_query_provider~select.

    " the framework answers 501 unless the provider acknowledges paging and
    " sorting, even when the result set is two rows long
    io_request->get_paging( ).
    io_request->get_sort_elements( ).

    DATA(options) = read_fixed_values( ).
    DATA(filter)  = filter_from_request( io_request ).

    IF filter IS NOT INITIAL.
      DELETE options WHERE options NOT IN filter.
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( lines( options ) ).
    ENDIF.

    IF io_request->is_data_requested( ).
      io_response->set_data( options ).
    ENDIF.

  ENDMETHOD.


  METHOD read_fixed_values.

    DATA option TYPE zde_da_opt.

    TRY.
        DATA(fixed_values) = CAST cl_abap_elemdescr(
                                 cl_abap_typedescr=>describe_by_data( option )
                               )->get_ddic_fixed_values(
                                   cl_abap_context_info=>get_user_language_abap_format( ) ).

      CATCH cx_abap_context_info_error INTO DATA(context_error).
        RAISE EXCEPTION NEW zcx_da_query( previous = context_error ).
    ENDTRY.

    result = VALUE #( FOR fixed_value IN fixed_values
                      ( options       = fixed_value-low
                        options_descr = fixed_value-ddtext ) ).

  ENDMETHOD.


  METHOD filter_from_request.

    TRY.

        LOOP AT request->get_filter( )->get_as_ranges( ) INTO DATA(condition)
             WHERE name = element_options.

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
