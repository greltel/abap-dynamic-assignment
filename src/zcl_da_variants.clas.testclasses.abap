*"* use this source file for your ABAP unit test classes

CLASS ltc_variants DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.
    DATA       cut             TYPE REF TO zif_da_variants.

    CONSTANTS test_program   TYPE zif_da_variants=>ty_progname    VALUE 'TEST_PROG' ##NO_TEXT.
    CONSTANTS test_parameter TYPE zif_da_variants=>ty_parameterid VALUE 'UNIT_TEST' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup RAISING cx_static_check.

    "! A stored BT variant must expose its lower bound in the caller's range.
    METHODS given_bt_when_get_then_low       FOR TESTING RAISING cx_static_check.
    "! Regression for the character-like bulk move that dropped HIGH.
    METHODS given_narrow_range_then_high     FOR TESTING RAISING cx_static_check.
    "! Sign and option must reach the caller's range unchanged.
    METHODS given_bt_then_sign_and_option  FOR TESTING RAISING cx_static_check.
    "! Every active row must produce one line in the value table.
    METHODS given_two_rows_then_two_values   FOR TESTING RAISING cx_static_check.
    "! Regression for MAPPING_DATA_EL never being read.
    METHODS given_map_el_then_typed FOR TESTING RAISING cx_static_check.
    "! Inactive rows must stay invisible.
    METHODS given_inactive_then_error FOR TESTING.
    "! An unknown parameter must raise instead of returning empty.
    METHODS given_no_row_then_error   FOR TESTING.
    "! Mixed data elements inside one parameter must be rejected.
    METHODS given_mixed_types_then_error     FOR TESTING.
    "! set_variant must reject an unknown data element.
    METHODS given_bad_element_then_error FOR TESTING.
    "! BT without an upper bound must be rejected.
    METHODS given_bt_no_high_then_error FOR TESTING.
    "! Writing twice with the same counter must replace, not append.
    METHODS given_counter_then_replace FOR TESTING RAISING cx_static_check.

    METHODS insert_variant
      IMPORTING value        TYPE zif_da_variants=>ty_value
                high_value   TYPE zif_da_variants=>ty_value   OPTIONAL
                option       TYPE zde_da_opt                 DEFAULT 'EQ'
                counter      TYPE zif_da_variants=>ty_counter DEFAULT '00001'
                data_element TYPE zif_da_variants=>ty_data_el OPTIONAL
                is_active    TYPE abap_boolean               DEFAULT abap_true.

ENDCLASS.


CLASS ltc_variants IMPLEMENTATION.

  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create(
                          i_dependency_list = VALUE #( ( 'ZDA_VARIANTS' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    cut = NEW zcl_da_variants( ).
  ENDMETHOD.


  METHOD given_bt_when_get_then_low.

    " given
    insert_variant( value = '1000' high_value = '2000' option = 'BT' ).

    " when
    DATA range TYPE RANGE OF zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = range ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = '1000'
        act = range[ 1 ]-low
        msg = 'LOW of the range must carry the stored value' ).

  ENDMETHOD.


  METHOD given_narrow_range_then_high.

    " given - a BT variant stored with the native 255 character column type
    insert_variant( value = '1000' high_value = '2000' option = 'BT' ).

    " when - the caller uses a narrow range type, exactly as the README shows
    TYPES ty_plant TYPE c LENGTH 4.
    DATA plant_range TYPE RANGE OF ty_plant.

    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = plant_range ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = '2000'
        act = plant_range[ 1 ]-high
        msg = 'HIGH must survive a caller range type narrower than the stored type' ).

  ENDMETHOD.


  METHOD given_bt_then_sign_and_option.

    " given
    insert_variant( value = '1000' high_value = '2000' option = 'BT' ).

    " when
    DATA range TYPE RANGE OF zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = range ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'IBT'
        act = |{ range[ 1 ]-sign }{ range[ 1 ]-option }|
        msg = 'SIGN and OPTION must reach the caller unchanged' ).

  ENDMETHOD.


  METHOD given_two_rows_then_two_values.

    " given
    insert_variant( value = '1000' counter = '00001' ).
    insert_variant( value = '2000' counter = '00002' ).

    " when
    DATA values TYPE STANDARD TABLE OF zif_da_variants=>ty_value WITH EMPTY KEY.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING values       = values ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 2
        act = lines( values )
        msg = 'Every active row must produce exactly one value line' ).

  ENDMETHOD.


  METHOD given_map_el_then_typed.

    " given - a variant whose mapping value is typed with a one character element
    sql_environment->insert_test_data( VALUE zcl_da_variants=>ty_variants(
      ( progname        = test_program
        parameterid     = test_parameter
        counter         = '00001'
        is_active       = abap_true
        sign            = 'I'
        opt             = 'EQ'
        value           = 'A'
        mapping_value   = 'I'
        mapping_data_el = 'ZDE_DA_SIGN' ) ) ).

    " when
    DATA mapping_values TYPE REF TO data.
    cut->get_variant( EXPORTING parameter_id   = test_parameter
                                program_name   = test_program
                      IMPORTING mapping_values = mapping_values ).

    " then - MAPPING_VALUE must carry the configured type, not the 255 char fallback
    FIELD-SYMBOLS <pairs> TYPE STANDARD TABLE.
    ASSIGN mapping_values->* TO <pairs>.

    DATA(table_type) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( <pairs> ) ).
    DATA(line_type)  = CAST cl_abap_structdescr( table_type->get_table_line_type( ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = 1
        act = line_type->get_component_type( 'MAPPING_VALUE' )->length
        msg = 'MAPPING_VALUE must use the configured mapping data element' ).

  ENDMETHOD.


  METHOD given_inactive_then_error.

    " given
    insert_variant( value = '1000' is_active = abap_false ).

    " when
    TRY.
        DATA value TYPE zif_da_variants=>ty_value.
        cut->get_variant( EXPORTING parameter_id = test_parameter
                                    program_name = test_program
                          IMPORTING field_value  = value ).

        cl_abap_unit_assert=>fail( msg = 'An inactive variant must not be returned' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_no_row_then_error.

    TRY.
        DATA value TYPE zif_da_variants=>ty_value.
        cut->get_variant( EXPORTING parameter_id = 'DOES_NOT_EXIST'
                          IMPORTING field_value  = value ).

        cl_abap_unit_assert=>fail( msg = 'An unknown parameter must raise ZCX_DA_VARIANTS' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_mixed_types_then_error.

    " given - two rows of one parameter describing two different types
    insert_variant( value = '1000' counter = '00001' data_element = 'ZDE_DA_SIGN' ).
    insert_variant( value = '2000' counter = '00002' data_element = 'ZDE_DA_OPT' ).

    " when
    TRY.
        DATA range TYPE RANGE OF zif_da_variants=>ty_value.
        cut->get_variant( EXPORTING parameter_id = test_parameter
                                    program_name = test_program
                          IMPORTING range        = range ).

        cl_abap_unit_assert=>fail( msg = 'Mixed data elements in one parameter must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_bad_element_then_error.

    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = '123'
                          data_element = 'DOESNT_EXIST' ).

        cl_abap_unit_assert=>fail( msg = 'An unknown data element must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_bt_no_high_then_error.

    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = '1000'
                          option       = zcl_da_variants=>opt_bt ).

        cl_abap_unit_assert=>fail( msg = 'BT without an upper bound must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_counter_then_replace.

    " given
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      counter      = '00001'
                      field_value  = '1000' ).

    " when - the same counter is written again
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      counter      = '00001'
                      field_value  = '2000' ).

    " then - one row, carrying the second value
    DATA values TYPE STANDARD TABLE OF zif_da_variants=>ty_value WITH EMPTY KEY.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING values       = values ).

    cl_abap_unit_assert=>assert_equals(
        exp = 1
        act = lines( values )
        msg = 'Writing an existing counter must replace the row, not append one' ).

    cl_abap_unit_assert=>assert_equals(
        exp = '2000'
        act = values[ 1 ]
        msg = 'The replaced row must carry the new value' ).

  ENDMETHOD.


  METHOD insert_variant.

    sql_environment->insert_test_data( VALUE zcl_da_variants=>ty_variants(
      ( progname     = test_program
        parameterid  = test_parameter
        counter      = counter
        is_active    = is_active
        sign         = 'I'
        opt          = option
        value        = value
        high_value   = high_value
        data_element = data_element ) ) ).

  ENDMETHOD.

ENDCLASS.


CLASS ltc_exception DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    "! Regression for get_text( ) returning a blank generic message.
    METHODS given_text_then_text_returned FOR TESTING.
    METHODS given_previous_then_chained     FOR TESTING.

ENDCLASS.


CLASS ltc_exception IMPLEMENTATION.

  METHOD given_text_then_text_returned.

    " given
    DATA(error) = NEW zcx_da_variants( text = `configuration table not allowed` ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = `configuration table not allowed`
        act = error->get_text( )
        msg = 'get_text( ) must return the dynamic message text' ).

  ENDMETHOD.


  METHOD given_previous_then_chained.

    " given
    DATA(cause) = NEW zcx_da_variants( text = `root cause` ).
    DATA(error) = NEW zcx_da_variants( text = `wrapper` previous = cause ).

    " then
    cl_abap_unit_assert=>assert_bound(
        act = error->previous
        msg = 'The exception chain must be preserved' ).

  ENDMETHOD.

ENDCLASS.
