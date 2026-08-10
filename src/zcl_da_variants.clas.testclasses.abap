*"* use this source file for your ABAP unit test classes

"! Covers {@link ZCL_DA_VARIANTS} through its public interface.
"! <p>The configuration table is replaced by an Open SQL test double, so no test
"! touches real data and no test depends on what happens to exist in the system.</p>
CLASS ltc_variants DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.
    DATA       cut             TYPE REF TO zif_da_variants.

    CONSTANTS test_program   TYPE zif_da_variants=>ty_progname     VALUE 'TEST_PROG'    ##NO_TEXT.
    CONSTANTS test_parameter TYPE zif_da_variants=>ty_parameterid  VALUE 'UNIT_TEST'    ##NO_TEXT.
    CONSTANTS global_program TYPE zif_da_variants=>ty_progname     VALUE 'GLOBAL'       ##NO_TEXT.
    CONSTANTS elementary_el  TYPE zif_da_variants=>ty_data_el      VALUE 'ZDE_DA_SIGN'  ##NO_TEXT.
    CONSTANTS structured_el  TYPE zif_da_variants=>ty_data_el      VALUE 'ZDA_VARIANTS' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup RAISING cx_static_check.

    " ----- get_variant, range target --------------------------------------
    "! The stored value must arrive in LOW of the caller's range.
    METHODS given_bt_then_range_low       FOR TESTING RAISING cx_static_check.
    "! Regression: the character-like bulk move used to drop HIGH.
    METHODS given_bt_then_range_high      FOR TESTING RAISING cx_static_check.
    "! Regression: HIGH must survive a caller range narrower than the stored type.
    METHODS given_narrow_range_then_high  FOR TESTING RAISING cx_static_check.
    "! Sign and option must reach the caller unchanged.
    METHODS given_bt_then_sign_and_option FOR TESTING RAISING cx_static_check.
    "! An EQ variant must leave HIGH untouched.
    METHODS given_eq_then_high_empty      FOR TESTING RAISING cx_static_check.
    "! Range lines follow the counter, not the insertion order.
    METHODS given_two_rows_then_ordered   FOR TESTING RAISING cx_static_check.

    " ----- get_variant, scalar and table targets --------------------------
    "! FIELD_VALUE carries the value of the first active variant.
    METHODS given_rows_then_field_value   FOR TESTING RAISING cx_static_check.
    "! MAPPING_FIELD_VALUE carries the mapping value of the first variant.
    METHODS given_rows_then_map_value     FOR TESTING RAISING cx_static_check.
    "! Every active row produces one line in the value table.
    METHODS given_two_rows_then_two_vals  FOR TESTING RAISING cx_static_check.

    " ----- get_variant, mapping table -------------------------------------
    "! Regression for MAPPING_DATA_EL never being read.
    METHODS given_map_el_then_typed       FOR TESTING RAISING cx_static_check.
    "! The value column takes the type of the configured DATA_ELEMENT.
    METHODS given_data_el_then_typed      FOR TESTING RAISING cx_static_check.
    "! Rows without a mapping value are not part of the mapping table.
    METHODS given_no_map_value_then_skip  FOR TESTING RAISING cx_static_check.

    " ----- get_variant, normalisation and error paths ---------------------
    "! Parameter and program are matched case insensitively.
    METHODS given_lower_case_then_found   FOR TESTING RAISING cx_static_check.
    "! An omitted program name falls back to GLOBAL.
    METHODS given_no_program_then_global  FOR TESTING RAISING cx_static_check.
    "! Inactive rows must stay invisible.
    METHODS given_inactive_then_error     FOR TESTING.
    "! An unknown parameter must raise instead of returning empty.
    METHODS given_no_row_then_error       FOR TESTING.
    "! Mixed data elements inside one parameter must be rejected.
    METHODS given_mixed_types_then_error  FOR TESTING.
    "! A stored data element that no longer exists must be reported.
    METHODS given_stored_bad_el_then_err  FOR TESTING.

    " ----- set_variant, happy paths ---------------------------------------
    "! The first row of a parameter gets counter 00001.
    METHODS given_empty_then_counter_one  FOR TESTING RAISING cx_static_check.
    "! Numbering continues after the highest stored counter.
    METHODS given_stored_then_next_ctr    FOR TESTING RAISING cx_static_check.
    "! Writing an existing counter replaces the row instead of appending.
    METHODS given_counter_then_replace    FOR TESTING RAISING cx_static_check.
    "! Replacing a row keeps its original creator.
    METHODS given_replace_then_creator    FOR TESTING RAISING cx_static_check.
    "! An omitted description is generated.
    METHODS given_no_descr_then_generated FOR TESTING RAISING cx_static_check.
    "! A supplied description is stored unchanged.
    METHODS given_descr_then_kept         FOR TESTING RAISING cx_static_check.
    "! An omitted sign defaults to include.
    METHODS given_no_sign_then_include    FOR TESTING RAISING cx_static_check.
    "! An omitted option defaults to equal.
    METHODS given_no_option_then_eq       FOR TESTING RAISING cx_static_check.
    "! Program, parameter and data element are stored in upper case.
    METHODS given_lower_case_then_upper   FOR TESTING RAISING cx_static_check.
    "! A row written as inactive is not returned by get_variant.
    METHODS given_inactive_then_not_read  FOR TESTING.

    " ----- set_variant, validation ----------------------------------------
    "! An unknown data element must be rejected.
    METHODS given_bad_element_then_error  FOR TESTING.
    "! A data element that is not elementary must be rejected.
    METHODS given_struct_element_then_err FOR TESTING.
    "! An unknown mapping data element must be rejected.
    METHODS given_bad_map_el_then_error   FOR TESTING.
    "! BT without an upper bound must be rejected.
    METHODS given_bt_no_high_then_error   FOR TESTING.
    "! NB without an upper bound must be rejected.
    METHODS given_nb_no_high_then_error   FOR TESTING.

    " ----- conversion and tolerance paths ---------------------------------
    "! A value that does not fit the configured numeric type must be reported.
    METHODS given_text_in_numeric_then_err FOR TESTING.
    "! A caller target that cannot hold the value must be reported.
    METHODS given_int_target_then_error    FOR TESTING.
    "! A stored structured type must be reported, not dumped.
    METHODS given_stored_struct_then_err   FOR TESTING.
    "! A caller table without OPTION and HIGH must still be filled.
    METHODS given_partial_line_then_filled FOR TESTING RAISING cx_static_check.

    " ----- constructor ----------------------------------------------------
    "! An unknown configuration table must be rejected.
    METHODS given_bad_table_then_error    FOR TESTING.
    "! A table outside the allowed packages must be rejected.
    METHODS given_foreign_pack_then_error FOR TESTING.

    " ----- helpers --------------------------------------------------------
    METHODS insert_variant
      IMPORTING value           TYPE zif_da_variants=>ty_value       OPTIONAL
                high_value      TYPE zif_da_variants=>ty_value       OPTIONAL
                option          TYPE zde_da_opt                      DEFAULT 'EQ'
                sign            TYPE zde_da_sign                     DEFAULT 'I'
                counter         TYPE zif_da_variants=>ty_counter     DEFAULT '00001'
                data_element    TYPE zif_da_variants=>ty_data_el     OPTIONAL
                mapping_value   TYPE zif_da_variants=>ty_value       OPTIONAL
                mapping_data_el TYPE zif_da_variants=>ty_data_el     OPTIONAL
                program_name    TYPE zif_da_variants=>ty_progname    DEFAULT test_program
                parameter_id    TYPE zif_da_variants=>ty_parameterid DEFAULT test_parameter
                created_by      TYPE zda_variants-created_by         OPTIONAL
                is_active       TYPE abap_boolean                    DEFAULT abap_true.

    METHODS read_row
      IMPORTING counter       TYPE zif_da_variants=>ty_counter DEFAULT '00001'
      RETURNING VALUE(result) TYPE zda_variants.

    METHODS mapping_column_length
      IMPORTING mapping_values TYPE REF TO data
                column         TYPE string
      RETURNING VALUE(result)  TYPE i.

ENDCLASS.


CLASS ltc_variants IMPLEMENTATION.

  METHOD class_setup.
    " the draft table is doubled as well, get_last_counter( ) reads it
    sql_environment = cl_osql_test_environment=>create(
                          i_dependency_list = VALUE #( ( 'ZDA_VARIANTS' )
                                                       ( 'ZDA_VARIANTS_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    cut = NEW zcl_da_variants( ).
  ENDMETHOD.


  METHOD given_bt_then_range_low.

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


  METHOD given_bt_then_range_high.

    " given
    insert_variant( value = '1000' high_value = '2000' option = 'BT' ).

    " when
    DATA range TYPE RANGE OF zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = range ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = '2000'
        act = range[ 1 ]-high
        msg = 'HIGH of the range must carry the stored upper bound' ).

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
    insert_variant( value = '1000' high_value = '2000' option = 'BT' sign = 'E' ).

    " when
    DATA range TYPE RANGE OF zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = range ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'EBT'
        act = |{ range[ 1 ]-sign }{ range[ 1 ]-option }|
        msg = 'SIGN and OPTION must reach the caller unchanged' ).

  ENDMETHOD.


  METHOD given_eq_then_high_empty.

    " given
    insert_variant( value = '1000' option = 'EQ' ).

    " when
    DATA range TYPE RANGE OF zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = range ).

    " then
    cl_abap_unit_assert=>assert_initial(
        act = range[ 1 ]-high
        msg = 'HIGH must stay empty for an EQ variant' ).

  ENDMETHOD.


  METHOD given_two_rows_then_ordered.

    " given - inserted in reverse order on purpose
    insert_variant( value = 'SECOND' counter = '00002' ).
    insert_variant( value = 'FIRST'  counter = '00001' ).

    " when
    DATA range TYPE RANGE OF zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = range ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'FIRST'
        act = range[ 1 ]-low
        msg = 'Range lines must be ordered by counter, not by insertion order' ).

  ENDMETHOD.


  METHOD given_rows_then_field_value.

    " given
    insert_variant( value = 'FIRST'  counter = '00001' ).
    insert_variant( value = 'SECOND' counter = '00002' ).

    " when
    DATA value TYPE zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING field_value  = value ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'FIRST'
        act = value
        msg = 'FIELD_VALUE must carry the value of the first active variant' ).

  ENDMETHOD.


  METHOD given_rows_then_map_value.

    " given
    insert_variant( value = 'A' mapping_value = 'MAPPED_A' ).

    " when
    DATA mapping TYPE zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id        = test_parameter
                                program_name        = test_program
                      IMPORTING mapping_field_value = mapping ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'MAPPED_A'
        act = mapping
        msg = 'MAPPING_FIELD_VALUE must carry the mapping of the first variant' ).

  ENDMETHOD.


  METHOD given_two_rows_then_two_vals.

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

    " given - a mapping value typed with a one character data element
    insert_variant( value           = 'A'
                    mapping_value   = 'I'
                    mapping_data_el = elementary_el ).

    " when
    DATA mapping_values TYPE REF TO data.
    cut->get_variant( EXPORTING parameter_id   = test_parameter
                                program_name   = test_program
                      IMPORTING mapping_values = mapping_values ).

    " then - the column must use the configured element, not the 255 char fallback
    DATA reference TYPE zde_da_sign.

    cl_abap_unit_assert=>assert_equals(
        exp = cl_abap_typedescr=>describe_by_data( reference )->length
        act = mapping_column_length( mapping_values = mapping_values
                                     column         = `MAPPING_VALUE` )
        msg = 'MAPPING_VALUE must use the configured mapping data element' ).

  ENDMETHOD.


  METHOD given_data_el_then_typed.

    " given
    insert_variant( value         = 'I'
                    data_element  = elementary_el
                    mapping_value = 'MAPPED' ).

    " when
    DATA mapping_values TYPE REF TO data.
    cut->get_variant( EXPORTING parameter_id   = test_parameter
                                program_name   = test_program
                      IMPORTING mapping_values = mapping_values ).

    " then
    DATA reference TYPE zde_da_sign.

    cl_abap_unit_assert=>assert_equals(
        exp = cl_abap_typedescr=>describe_by_data( reference )->length
        act = mapping_column_length( mapping_values = mapping_values
                                     column         = `VALUE` )
        msg = 'VALUE must use the configured data element' ).

  ENDMETHOD.


  METHOD given_no_map_value_then_skip.

    " given - only the second row carries a mapping value
    insert_variant( value = 'A' counter = '00001' ).
    insert_variant( value = 'B' counter = '00002' mapping_value = 'MAPPED_B' ).

    " when
    DATA mapping_values TYPE REF TO data.
    cut->get_variant( EXPORTING parameter_id   = test_parameter
                                program_name   = test_program
                      IMPORTING mapping_values = mapping_values ).

    " then
    FIELD-SYMBOLS <pairs> TYPE STANDARD TABLE.
    ASSIGN mapping_values->* TO <pairs>.

    cl_abap_unit_assert=>assert_equals(
        exp = 1
        act = lines( <pairs> )
        msg = 'Rows without a mapping value must not appear in the mapping table' ).

  ENDMETHOD.


  METHOD given_lower_case_then_found.

    " given
    insert_variant( value = '1000' ).

    " when - the caller uses lower case
    DATA value TYPE zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = CONV #( to_lower( test_parameter ) )
                                program_name = CONV #( to_lower( test_program ) )
                      IMPORTING field_value  = value ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = '1000'
        act = value
        msg = 'Parameter and program must be matched case insensitively' ).

  ENDMETHOD.


  METHOD given_no_program_then_global.

    " given - a variant stored for the default program
    insert_variant( value = '1000' program_name = global_program ).

    " when - the caller omits the program name
    DATA value TYPE zif_da_variants=>ty_value.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                      IMPORTING field_value  = value ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = '1000'
        act = value
        msg = 'An omitted program name must fall back to GLOBAL' ).

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
    insert_variant( value = 'A' counter = '00001' data_element = 'ZDE_DA_SIGN' ).
    insert_variant( value = 'B' counter = '00002' data_element = 'ZDE_DA_OPT' ).

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


  METHOD given_stored_bad_el_then_err.

    " given - a data element that was valid when written but is gone now
    insert_variant( value         = 'A'
                    data_element  = 'ZDE_DOES_NOT_EXIST'
                    mapping_value = 'MAPPED' ).

    " when
    TRY.
        DATA mapping_values TYPE REF TO data.
        cut->get_variant( EXPORTING parameter_id   = test_parameter
                                    program_name   = test_program
                          IMPORTING mapping_values = mapping_values ).

        cl_abap_unit_assert=>fail( msg = 'An unresolvable stored data element must be reported' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_empty_then_counter_one.

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      field_value  = '1000' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = '00001'
        act = read_row( )-counter
        msg = 'The first row of a parameter must get counter 00001' ).

  ENDMETHOD.


  METHOD given_stored_then_next_ctr.

    " given
    insert_variant( value = 'A' counter = '00007' ).

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      field_value  = 'B' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'B'
        act = read_row( '00008' )-value
        msg = 'Numbering must continue after the highest stored counter' ).

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

    " then
    DATA values TYPE STANDARD TABLE OF zif_da_variants=>ty_value WITH EMPTY KEY.
    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING values       = values ).

    cl_abap_unit_assert=>assert_equals(
        exp = 1
        act = lines( values )
        msg = 'Writing an existing counter must replace the row, not append one' ).

  ENDMETHOD.


  METHOD given_replace_then_creator.

    " given - a row created by somebody else
    insert_variant( value = 'A' created_by = 'ORIGINAL' ).

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      counter      = '00001'
                      field_value  = 'B' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'ORIGINAL'
        act = read_row( )-created_by
        msg = 'Replacing a row must not rewrite its original creator' ).

  ENDMETHOD.


  METHOD given_no_descr_then_generated.

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      field_value  = '1000' ).

    " then
    cl_abap_unit_assert=>assert_not_initial(
        act = read_row( )-description
        msg = 'An omitted description must be generated' ).

  ENDMETHOD.


  METHOD given_descr_then_kept.

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      field_value  = '1000'
                      description  = 'Plant for operations' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'Plant for operations'
        act = read_row( )-description
        msg = 'A supplied description must be stored unchanged' ).

  ENDMETHOD.


  METHOD given_no_sign_then_include.

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      field_value  = '1000' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'I'
        act = read_row( )-sign
        msg = 'An omitted sign must default to include' ).

  ENDMETHOD.


  METHOD given_no_option_then_eq.

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      field_value  = '1000' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'EQ'
        act = read_row( )-opt
        msg = 'An omitted option must default to equal' ).

  ENDMETHOD.


  METHOD given_lower_case_then_upper.

    " when
    cut->set_variant( parameter_id = CONV #( to_lower( test_parameter ) )
                      program_name = CONV #( to_lower( test_program ) )
                      field_value  = '1000'
                      data_element = CONV #( to_lower( elementary_el ) ) ).

    " then
    DATA(row) = read_row( ).

    cl_abap_unit_assert=>assert_equals(
        exp = |{ test_program }{ test_parameter }{ elementary_el }|
        act = |{ row-progname }{ row-parameterid }{ row-data_element }|
        msg = 'Program, parameter and data element must be stored in upper case' ).

  ENDMETHOD.


  METHOD given_inactive_then_not_read.

    " given
    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = '1000'
                          is_active    = abap_false ).

      CATCH zcx_da_variants INTO DATA(write_error).
        cl_abap_unit_assert=>fail( msg = write_error->get_text( ) ).
    ENDTRY.

    " when
    TRY.
        DATA value TYPE zif_da_variants=>ty_value.
        cut->get_variant( EXPORTING parameter_id = test_parameter
                                    program_name = test_program
                          IMPORTING field_value  = value ).

        cl_abap_unit_assert=>fail( msg = 'A row written as inactive must not be returned' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_bad_element_then_error.

    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = '123'
                          data_element = 'ZDE_DOES_NOT_EXIST' ).

        cl_abap_unit_assert=>fail( msg = 'An unknown data element must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_struct_element_then_err.

    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = '123'
                          data_element = structured_el ).

        cl_abap_unit_assert=>fail( msg = 'A structured type must not be accepted as data element' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_bad_map_el_then_error.

    TRY.
        cut->set_variant( parameter_id         = test_parameter
                          program_name         = test_program
                          field_value          = '123'
                          mapping_field_value  = 'X'
                          mapping_data_element = 'ZDE_DOES_NOT_EXIST' ).

        cl_abap_unit_assert=>fail( msg = 'An unknown mapping data element must be rejected' ).

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


  METHOD given_nb_no_high_then_error.

    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = '1000'
                          option       = zcl_da_variants=>opt_nb ).

        cl_abap_unit_assert=>fail( msg = 'NB without an upper bound must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_text_in_numeric_then_err.

    CONSTANTS numeric_el     TYPE zif_da_variants=>ty_data_el      VALUE 'INT4'.

    " given - a text value configured with a numeric data element
    insert_variant( value         = 'ABC'
                    data_element  = numeric_el
                    mapping_value = 'MAPPED' ).

    " when
    TRY.
        DATA mapping_values TYPE REF TO data.
        cut->get_variant( EXPORTING parameter_id   = test_parameter
                                    program_name   = test_program
                          IMPORTING mapping_values = mapping_values ).

        cl_abap_unit_assert=>fail( msg = 'A value that does not fit its type must be reported' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_int_target_then_error.

    " given
    insert_variant( value = 'ABC' ).

    " when - the caller asks for an integer
    TRY.
        DATA number TYPE i.
        cut->get_variant( EXPORTING parameter_id = test_parameter
                                    program_name = test_program
                          IMPORTING field_value  = number ).

        cl_abap_unit_assert=>fail( msg = 'A target that cannot hold the value must be reported' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_stored_struct_then_err.

    " given - a structured type reached the table, bypassing set_variant
    insert_variant( value         = 'A'
                    data_element  = structured_el
                    mapping_value = 'MAPPED' ).

    " when
    TRY.
        DATA mapping_values TYPE REF TO data.
        cut->get_variant( EXPORTING parameter_id   = test_parameter
                                    program_name   = test_program
                          IMPORTING mapping_values = mapping_values ).

        cl_abap_unit_assert=>fail( msg = 'A structured stored type must be reported, not dumped' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_partial_line_then_filled.

    " given
    insert_variant( value = '1000' high_value = '2000' option = 'BT' ).

    " when - the caller's line type only knows SIGN and LOW
    TYPES: BEGIN OF ty_partial,
             sign TYPE c LENGTH 1,
             low  TYPE c LENGTH 10,
           END OF ty_partial.
    DATA partial TYPE STANDARD TABLE OF ty_partial WITH EMPTY KEY.

    cut->get_variant( EXPORTING parameter_id = test_parameter
                                program_name = test_program
                      IMPORTING range        = partial ).

    " then - the known components are filled, the missing ones are skipped
    cl_abap_unit_assert=>assert_equals(
        exp = 'I1000'
        act = |{ partial[ 1 ]-sign }{ partial[ 1 ]-low }|
        msg = 'Components that the caller does not have must be skipped silently' ).

  ENDMETHOD.


  METHOD given_bad_table_then_error.

    TRY.
        DATA(unknown_table) = NEW zcl_da_variants( table_name = 'ZDA_NOT_A_TABLE' ) ##NEEDED.

        cl_abap_unit_assert=>fail( msg = 'An unknown configuration table must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_foreign_pack_then_error.

    TRY.
        DATA(foreign) = NEW zcl_da_variants( table_name = 'ZDA_VARIANTS'
                                             packages   = 'ZDA_NOT_MY_PACKAGE' ) ##NEEDED.

        cl_abap_unit_assert=>fail( msg = 'A table outside the allowed packages must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD insert_variant.

    sql_environment->insert_test_data( VALUE zcl_da_variants=>ty_variants(
      ( progname        = program_name
        parameterid     = parameter_id
        counter         = counter
        is_active       = is_active
        sign            = sign
        opt             = option
        value           = value
        high_value      = high_value
        data_element    = data_element
        mapping_value   = mapping_value
        mapping_data_el = mapping_data_el
        created_by      = created_by ) ) ).

  ENDMETHOD.


  METHOD read_row.

    SELECT SINGLE FROM zda_variants
      FIELDS progname, parameterid, counter, is_active, sign, opt,
             value, high_value, data_element, mapping_value, mapping_data_el,
             description, created_by, created_at
      WHERE progname    = @test_program
        AND parameterid = @test_parameter
        AND counter     = @counter
      INTO CORRESPONDING FIELDS OF @result.

  ENDMETHOD.


  METHOD mapping_column_length.

    FIELD-SYMBOLS <pairs> TYPE STANDARD TABLE.
    ASSIGN mapping_values->* TO <pairs>.

    DATA(table_type) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( <pairs> ) ).
    DATA(line_type)  = CAST cl_abap_structdescr( table_type->get_table_line_type( ) ).

    result = line_type->get_component_type( CONV #( column ) )->length.

  ENDMETHOD.

ENDCLASS.


"! Covers {@link ZCX_DA_VARIANTS}, which carries the free message text.
CLASS ltc_exception DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    "! Regression for get_text( ) returning a blank generic message.
    METHODS given_text_then_text_returned FOR TESTING.
    "! Without a free text the T100 fallback must still answer.
    METHODS given_no_text_then_no_dump    FOR TESTING.
    "! The exception chain must survive.
    METHODS given_previous_then_chained   FOR TESTING.

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


  METHOD given_no_text_then_no_dump.

    " given
    DATA(error) = NEW zcx_da_variants( ).

    " when - the T100 fallback must answer without a short dump
    DATA(fallback) = error->get_text( ) ##NEEDED.

    " then
    cl_abap_unit_assert=>assert_bound(
        act = error
        msg = 'An exception without a free text must still be usable' ).

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


"! Pins the three defects found after the 1.0.0 review of {@link ZCL_DA_VARIANTS}.
"! <p>Every test describes the behaviour the framework must show. They are expected
"! to be <strong>red</strong> until the corrections are delivered:</p>
"! <ul>
"! <li><em>Defect 1</em> - the append path of set_variant( ) writes with MODIFY, so a
"! computed counter that is already taken replaces a stored row instead of being
"! rejected. This is the single threaded, reproducible form of the numbering race.</li>
"! <li><em>Defect 2</em> - fill_range( ) and fill_values( ) run outside a TRY, so a value
"! that does not fit the caller's target ends in a short dump instead of
"! {@link ZCX_DA_VARIANTS}.</li>
"! <li><em>Defect 3</em> - consistency check and type resolution ignore MAPPING_DATA_EL,
"! so mixed mapping types are accepted and the mapping column is typed from a row
"! that carries no mapping value at all.</li>
"! </ul>
"! <p>Unlike {@link ltc_variants} this class also doubles ZDA_VARIANTS_D, so the
"! counter tests no longer depend on what happens to sit in the real draft table.</p>
CLASS ltc_defects DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    TYPES ty_drafts TYPE STANDARD TABLE OF zda_variants_d WITH EMPTY KEY.

    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.
    DATA       cut             TYPE REF TO zif_da_variants.

    CONSTANTS test_program   TYPE zif_da_variants=>ty_progname    VALUE 'TEST_PROG'    ##NO_TEXT.
    CONSTANTS test_parameter TYPE zif_da_variants=>ty_parameterid VALUE 'UNIT_TEST'    ##NO_TEXT.
    CONSTANTS highest_ctr    TYPE zif_da_variants=>ty_counter     VALUE '99999'        ##NO_TEXT.
    CONSTANTS sign_el        TYPE zif_da_variants=>ty_data_el     VALUE 'ZDE_DA_SIGN'  ##NO_TEXT.
    CONSTANTS descr_el       TYPE zif_da_variants=>ty_data_el     VALUE 'ZDE_DA_DESCR' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup RAISING cx_static_check.

    " ----- defect 1, the append path must never overwrite -------------------
    "! An append that cannot be numbered must be rejected, not wrapped around.
    METHODS given_counter_full_then_error  FOR TESTING.
    "! Two appends must never end up on one key, whatever the numbering does.
    METHODS given_two_appends_then_no_loss FOR TESTING.
    "! Guard: a counter parked in the draft table must not be handed out twice.
    METHODS given_draft_counter_then_next  FOR TESTING RAISING cx_static_check.

    " ----- defect 2, conversion errors on read must be reported --------------
    "! A value that does not fit a numeric caller range must raise, not dump.
    METHODS given_int_range_then_error     FOR TESTING.
    "! A value that does not fit a numeric caller table must raise, not dump.
    METHODS given_int_values_then_error    FOR TESTING.
    "! An upper bound that does not fit the caller range must raise, not dump.
    METHODS given_bad_high_then_error      FOR TESTING.

    " ----- defect 3, the mapping type is resolved from the wrong row ---------
    "! Mixed mapping data elements inside one parameter must be rejected.
    METHODS given_mixed_map_els_then_error FOR TESTING.
    "! The mapping column must be typed from the first row that maps anything.
    METHODS given_late_map_el_then_typed   FOR TESTING RAISING cx_static_check.

    " ----- helpers ----------------------------------------------------------
    METHODS insert_variant
      IMPORTING value           TYPE zif_da_variants=>ty_value   OPTIONAL
                high_value      TYPE zif_da_variants=>ty_value   OPTIONAL
                option          TYPE zde_da_opt                  DEFAULT 'EQ'
                sign            TYPE zde_da_sign                 DEFAULT 'I'
                counter         TYPE zif_da_variants=>ty_counter DEFAULT '00001'
                data_element    TYPE zif_da_variants=>ty_data_el OPTIONAL
                mapping_value   TYPE zif_da_variants=>ty_value   OPTIONAL
                mapping_data_el TYPE zif_da_variants=>ty_data_el OPTIONAL.

    METHODS insert_draft
      IMPORTING counter TYPE zif_da_variants=>ty_counter.

    METHODS read_row
      IMPORTING counter       TYPE zif_da_variants=>ty_counter
      RETURNING VALUE(result) TYPE zda_variants.

    METHODS count_rows
      RETURNING VALUE(result) TYPE i.

    METHODS mapping_column_length
      IMPORTING mapping_values TYPE REF TO data
                column         TYPE string
      RETURNING VALUE(result)  TYPE i.

ENDCLASS.


CLASS ltc_defects IMPLEMENTATION.

  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create(
                          i_dependency_list = VALUE #( ( 'ZDA_VARIANTS' )
                                                       ( 'ZDA_VARIANTS_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    cut = NEW zcl_da_variants( ).
  ENDMETHOD.


  METHOD given_counter_full_then_error.

    " given - the last counter of the parameter is already allocated
    insert_variant( value = 'STORED' counter = highest_ctr ).

    " when - the caller appends without a counter, so one has to be computed
    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = 'NEW' ).

        cl_abap_unit_assert=>fail(
            msg = 'An append that cannot be numbered must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD given_two_appends_then_no_loss.

    " given - the last counter of the parameter is already allocated
    insert_variant( value = 'STORED' counter = highest_ctr ).

    " when - two appends in a row, which today both compute the same counter
    TRY.
        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = 'FIRST' ).

        cut->set_variant( parameter_id = test_parameter
                          program_name = test_program
                          field_value  = 'SECOND' ).

      CATCH zcx_da_variants.
        " a rejected append is correct behaviour, nothing was lost
        RETURN.
    ENDTRY.

    " then - two accepted appends must have produced two additional rows
    cl_abap_unit_assert=>assert_equals(
        exp = 3
        act = count_rows( )
        msg = 'An accepted append must never overwrite a row that is already stored' ).

  ENDMETHOD.


  METHOD given_draft_counter_then_next.

    " given - the Fiori application parks a pending counter in the draft table
    insert_draft( '00007' ).

    " when
    cut->set_variant( parameter_id = test_parameter
                      program_name = test_program
                      field_value  = 'A' ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 'A'
        act = read_row( '00008' )-value
        msg = 'A counter parked in the draft table must not be handed out twice' ).

  ENDMETHOD.


  METHOD given_int_range_then_error.

    " given - a stored value that is not a number
    insert_variant( value = 'ABC' ).

    " when - the caller works with a numeric range
    TRY.
        DATA number_range TYPE RANGE OF i.

        cut->get_variant( EXPORTING parameter_id = test_parameter
                                    program_name = test_program
                          IMPORTING range        = number_range ).

        cl_abap_unit_assert=>fail(
            msg = 'A value that does not fit the caller range must be reported' ).

      CATCH zcx_da_variants.
        " then - expected, today the conversion error escapes as a short dump
    ENDTRY.

  ENDMETHOD.


  METHOD given_int_values_then_error.

    " given - a stored value that is not a number
    insert_variant( value = 'ABC' ).

    " when - the caller works with a numeric value table
    TRY.
        DATA numbers TYPE STANDARD TABLE OF i WITH EMPTY KEY.

        cut->get_variant( EXPORTING parameter_id = test_parameter
                                    program_name = test_program
                          IMPORTING values       = numbers ).

        cl_abap_unit_assert=>fail(
            msg = 'A value that does not fit the caller table must be reported' ).

      CATCH zcx_da_variants.
        " then - expected, today the conversion error escapes as a short dump
    ENDTRY.

  ENDMETHOD.


  METHOD given_bad_high_then_error.

    " given - a lower bound that converts and an upper bound that does not
    insert_variant( value      = '1000'
                    high_value = 'ABC'
                    option     = 'BT' ).

    " when
    TRY.
        DATA number_range TYPE RANGE OF i.

        cut->get_variant( EXPORTING parameter_id = test_parameter
                                    program_name = test_program
                          IMPORTING range        = number_range ).

        cl_abap_unit_assert=>fail(
            msg = 'An upper bound that does not fit the caller range must be reported' ).

      CATCH zcx_da_variants.
        " then - expected, today the conversion error escapes as a short dump
    ENDTRY.

  ENDMETHOD.


  METHOD given_mixed_map_els_then_error.

    " given - one parameter, two rows, two different mapping data elements
    insert_variant( counter         = '00001'
                    value           = 'A'
                    mapping_value   = 'I'
                    mapping_data_el = sign_el ).

    insert_variant( counter         = '00002'
                    value           = 'B'
                    mapping_value   = 'DESCRIPTION'
                    mapping_data_el = descr_el ).

    " when
    TRY.
        DATA mapping_values TYPE REF TO data.

        cut->get_variant( EXPORTING parameter_id   = test_parameter
                                    program_name   = test_program
                          IMPORTING mapping_values = mapping_values ).

        cl_abap_unit_assert=>fail(
            msg = 'Mixed mapping data elements in one parameter must be rejected' ).

      CATCH zcx_da_variants.
        " then - expected, today row two is silently truncated to one character
    ENDTRY.

  ENDMETHOD.


  METHOD given_late_map_el_then_typed.

    " given - only the second row maps anything, and it carries the type
    insert_variant( counter = '00001'
                    value   = 'A' ).

    insert_variant( counter         = '00002'
                    value           = 'B'
                    mapping_value   = 'MAPPED'
                    mapping_data_el = descr_el ).

    " when
    DATA mapping_values TYPE REF TO data.

    cut->get_variant( EXPORTING parameter_id   = test_parameter
                                program_name   = test_program
                      IMPORTING mapping_values = mapping_values ).

    " then - the column must use ZDE_DA_DESCR, not the 255 character fallback
    DATA reference TYPE zde_da_descr.

    cl_abap_unit_assert=>assert_equals(
        exp = cl_abap_typedescr=>describe_by_data( reference )->length
        act = mapping_column_length( mapping_values = mapping_values
                                     column         = `MAPPING_VALUE` )
        msg = 'MAPPING_VALUE must be typed from the first row that maps a value' ).

  ENDMETHOD.


  METHOD insert_variant.

    sql_environment->insert_test_data( VALUE zcl_da_variants=>ty_variants(
      ( progname        = test_program
        parameterid     = test_parameter
        counter         = counter
        is_active       = abap_true
        sign            = sign
        opt             = option
        value           = value
        high_value      = high_value
        data_element    = data_element
        mapping_value   = mapping_value
        mapping_data_el = mapping_data_el ) ) ).

  ENDMETHOD.


  METHOD insert_draft.

    sql_environment->insert_test_data( VALUE ty_drafts(
      ( progname    = test_program
        parameterid = test_parameter
        counter     = counter ) ) ).

  ENDMETHOD.


  METHOD read_row.

    SELECT SINGLE FROM zda_variants
      FIELDS progname, parameterid, counter, is_active, sign, opt,
             value, high_value, data_element, mapping_value, mapping_data_el,
             description, created_by, created_at
      WHERE progname    = @test_program
        AND parameterid = @test_parameter
        AND counter     = @counter
      INTO CORRESPONDING FIELDS OF @result.

  ENDMETHOD.


  METHOD count_rows.

    SELECT FROM zda_variants
      FIELDS COUNT( * )
      WHERE progname    = @test_program
        AND parameterid = @test_parameter
      INTO @result.

  ENDMETHOD.


  METHOD mapping_column_length.

    FIELD-SYMBOLS <pairs> TYPE STANDARD TABLE.
    ASSIGN mapping_values->* TO <pairs>.

    DATA(table_type) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( <pairs> ) ).
    DATA(line_type)  = CAST cl_abap_structdescr( table_type->get_table_line_type( ) ).

    result = line_type->get_component_type( CONV #( column ) )->length.

  ENDMETHOD.

ENDCLASS.
