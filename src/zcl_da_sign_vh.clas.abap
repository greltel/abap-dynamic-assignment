CLASS zcl_da_sign_vh DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_da_sign_vh IMPLEMENTATION.
  METHOD if_rap_query_provider~select.
    io_request->get_sort_elements( ).
    io_request->get_paging( ).
    DATA lt_values TYPE STANDARD TABLE OF zi_da_sign_vh WITH EMPTY KEY.
    DATA lv_sign   TYPE zde_da_sign.

    DATA(lt_domain_values) = CAST cl_abap_elemdescr( cl_abap_typedescr=>describe_by_data( lv_sign ) )->get_ddic_fixed_values(
                                                                                                        syst-langu ).
    LOOP AT lt_domain_values ASSIGNING FIELD-SYMBOL(<fs_domain_value>).
      APPEND VALUE #( sign       = <fs_domain_value>-low
                      sign_descr = <fs_domain_value>-ddtext ) TO lt_values.
    ENDLOOP.

    DATA(ld_all_entries) = lines( lt_values ).

    IF io_request->is_data_requested( ).
      io_response->set_data( lt_values ).
    ENDIF.

    IF io_request->is_total_numb_of_rec_requested( ).
      io_response->set_total_number_of_records( CONV #( ld_all_entries ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
