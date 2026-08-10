*"* use this source file for your ABAP unit test classes

"! Covers {@link ZCL_DA_SIGN_VH}, the query provider behind the sign value help.
"! <p>The RAP query interfaces are replaced by test doubles, so no test needs a
"! running OData request. The private methods are reached through LOCAL FRIENDS,
"! which keeps the production class free of members that exist only for testing.</p>
"! <p>The paging test is a regression: a provider that does not acknowledge paging
"! and sorting makes the framework answer 501 Not Implemented, even for a result
"! set of two rows.</p>
CLASS ltc_sign_vh DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    DATA cut      TYPE REF TO zcl_da_sign_vh.
    DATA request  TYPE REF TO if_rap_query_request.
    DATA response TYPE REF TO if_rap_query_response.
    DATA filter   TYPE REF TO if_rap_query_filter.

    CONSTANTS include_sign  TYPE zde_da_sign VALUE 'I'       ##NO_TEXT.
    CONSTANTS other_element  TYPE string     VALUE `PROGNAME` ##NO_TEXT.
    CONSTANTS domain_values TYPE i           VALUE 2.

    METHODS setup.

    " ----- the fixed values of the domain -----------------------------------
    "! Every fixed value of ZDO_DA_SIGN must reach the value help.
    METHODS given_domain_then_all_values  FOR TESTING RAISING cx_static_check.
    "! Every entry must carry the description of its fixed value.
    METHODS given_domain_then_description FOR TESTING RAISING cx_static_check.

    " ----- the type ahead filter of the dialog ------------------------------
    "! Without a filter the provider must serve everything.
    METHODS given_no_filter_then_empty    FOR TESTING.
    "! A filter on the sign element must become a range.
    METHODS given_filter_then_range       FOR TESTING.
    "! A filter on another element must not narrow the signs.
    METHODS given_other_element_then_none FOR TESTING.

    " ----- the request contract ---------------------------------------------
    "! Regression: paging and sorting must be read, or the framework answers 501.
    METHODS given_select_then_paging_read FOR TESTING RAISING cx_static_check.
    "! The data is only set when the request asks for it.
    METHODS given_data_wanted_then_set    FOR TESTING RAISING cx_static_check.
    "! Without a data request nothing must be written to the response.
    METHODS given_no_data_then_not_set    FOR TESTING RAISING cx_static_check.

    " ----- helpers ----------------------------------------------------------
    "! Lets get_filter( ) answer with the filter double instead of a null reference.
    METHODS expect_filter_call.

ENDCLASS.


CLASS zcl_da_sign_vh DEFINITION LOCAL FRIENDS ltc_sign_vh.


CLASS ltc_sign_vh IMPLEMENTATION.

  METHOD setup.
    cut      = NEW zcl_da_sign_vh( ).
    request  = CAST #( cl_abap_testdouble=>create( 'IF_RAP_QUERY_REQUEST' ) ).
    response = CAST #( cl_abap_testdouble=>create( 'IF_RAP_QUERY_RESPONSE' ) ).
    filter   = CAST #( cl_abap_testdouble=>create( 'IF_RAP_QUERY_FILTER' ) ).
  ENDMETHOD.


  METHOD given_domain_then_all_values.

    " when
    DATA(signs) = cut->read_fixed_values( ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = domain_values
        act = lines( signs )
        msg = 'Every fixed value of ZDO_DA_SIGN must reach the value help' ).

  ENDMETHOD.


  METHOD given_domain_then_description.

    " when
    DATA(signs) = cut->read_fixed_values( ).

    " then
    cl_abap_unit_assert=>assert_not_initial(
        act = VALUE #( signs[ sign = include_sign ]-sign_descr OPTIONAL )
        msg = 'A fixed value without its description is useless in a dialog' ).

  ENDMETHOD.


  METHOD given_no_filter_then_empty.

    " given - the request always answers with a filter object, it is just empty
    expect_filter_call( ).

    " when - the dialog was opened without anything typed into it
    DATA(range) = cut->filter_from_request( request ).

    " then
    cl_abap_unit_assert=>assert_initial(
        act = range
        msg = 'Without a filter the provider must serve every sign' ).

  ENDMETHOD.


  METHOD given_filter_then_range.

    " given - the type of the range table is taken from the interface itself
    DATA(ranges) = filter->get_as_ranges( ).

    ranges = VALUE #( ( name  = zcl_da_sign_vh=>element_sign
                        range = VALUE #( ( sign = 'I' option = 'EQ' low = include_sign ) ) ) ).

    cl_abap_testdouble=>configure_call( filter )->returning( ranges ).
    filter->get_as_ranges( ).

    expect_filter_call( ).

    " when
    DATA(range) = cut->filter_from_request( request ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = include_sign
        act = VALUE #( range[ 1 ]-low OPTIONAL )
        msg = 'A filter on the sign element must become a range line' ).

  ENDMETHOD.


  METHOD given_other_element_then_none.

    " given - the dialog filters on a field this provider does not serve
    DATA(ranges) = filter->get_as_ranges( ).

    ranges = VALUE #( ( name  = other_element
                        range = VALUE #( ( sign = 'I' option = 'EQ' low = include_sign ) ) ) ).

    cl_abap_testdouble=>configure_call( filter )->returning( ranges ).
    filter->get_as_ranges( ).

    expect_filter_call( ).

    " when
    DATA(range) = cut->filter_from_request( request ).

    " then
    cl_abap_unit_assert=>assert_initial(
        act = range
        msg = 'A filter on another element must not narrow the signs' ).

  ENDMETHOD.


  METHOD given_select_then_paging_read.

    " given
    expect_filter_call( ).

    cl_abap_testdouble=>configure_call( request )->and_expect( )->is_called_times( 1 ).
    request->get_paging( ).

    cl_abap_testdouble=>configure_call( request )->and_expect( )->is_called_times( 1 ).
    request->get_sort_elements( ).

    " when
    cut->if_rap_query_provider~select( io_request  = request
                                       io_response = response ).

    " then - not reading these two makes the framework answer 501
    cl_abap_testdouble=>verify_expectations( request ).

  ENDMETHOD.


  METHOD given_data_wanted_then_set.

    " given
    expect_filter_call( ).

    cl_abap_testdouble=>configure_call( request )->returning( abap_true ).
    request->is_data_requested( ).

    cl_abap_testdouble=>configure_call( response )->and_expect( )->is_called_times( 1 ).
    response->set_data( cut->read_fixed_values( ) ).

    " when
    cut->if_rap_query_provider~select( io_request  = request
                                       io_response = response ).

    " then
    cl_abap_testdouble=>verify_expectations( response ).

  ENDMETHOD.


  METHOD given_no_data_then_not_set.

    " given - the client only asked for metadata
    expect_filter_call( ).

    cl_abap_testdouble=>configure_call( response )->and_expect( )->is_never_called( ).
    response->set_data( VALUE zcl_da_sign_vh=>ty_signs( ) ).

    " when
    cut->if_rap_query_provider~select( io_request  = request
                                       io_response = response ).

    " then
    cl_abap_testdouble=>verify_expectations( response ).

  ENDMETHOD.


  METHOD expect_filter_call.

    " an unconfigured get_filter( ) would answer with a null reference
    cl_abap_testdouble=>configure_call( request )->returning( filter ).
    request->get_filter( ).

  ENDMETHOD.

ENDCLASS.
