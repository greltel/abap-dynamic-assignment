*"* use this source file for your ABAP unit test classes

"! Covers {@link ZCL_DA_REPOSITORY} on Open SQL test doubles of both tables.
CLASS ltc_repository DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    DATA cut TYPE REF TO zif_da_repository.

    CONSTANTS test_program   TYPE ztda_variants-progname    VALUE 'TEST_PROG' ##NO_TEXT.
    CONSTANTS test_parameter TYPE ztda_variants-parameterid VALUE 'UNIT_TEST' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup RAISING cx_static_check.

    "! Only active rows come back, ordered by counter.
    METHODS given_inactive_then_skipped FOR TESTING RAISING cx_static_check.
    "! A pending draft blocks its counter like an active row.
    METHODS given_draft_then_counted    FOR TESTING RAISING cx_static_check.
    "! One request answers every key it asked for and nothing else.
    METHODS given_two_keys_then_both    FOR TESTING RAISING cx_static_check.
    "! A key that is already taken is answered with false, not with an error.
    METHODS given_taken_key_then_false  FOR TESTING RAISING cx_static_check.
    "! Deleting a whole parameter reports how many rows went.
    METHODS given_delete_all_then_count FOR TESTING RAISING cx_static_check.

    METHODS insert_variant
      IMPORTING counter    TYPE ztda_variants-counter
                is_active  TYPE abap_boolean              DEFAULT abap_true
                !parameter TYPE ztda_variants-parameterid DEFAULT test_parameter.

    METHODS row
      IMPORTING counter       TYPE ztda_variants-counter
      RETURNING VALUE(result) TYPE zif_da_variants=>ty_variant.

ENDCLASS.


CLASS ltc_repository IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZTDA_VARIANTS' )
                                                                                     ( 'ZTDA_VARIANTS_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    cut = NEW zcl_da_repository( ).
  ENDMETHOD.

  METHOD given_inactive_then_skipped.
    " given
    insert_variant( counter = '00002' ).
    insert_variant( counter   = '00001'
                    is_active = abap_false ).
    insert_variant( counter = '00003' ).

    " when
    DATA(variants) = cut->read_active_variants( program_name = test_program
                                                parameter_id = test_parameter ).

    " then
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( variants )
                                        msg = `Only active rows may be read` ).

    cl_abap_unit_assert=>assert_equals( exp = '00002'
                                        act = variants[ 1 ]-counter
                                        msg = `Rows must come back ordered by counter` ).
  ENDMETHOD.

  METHOD given_draft_then_counted.
    " given - active row 00001, pending draft 00005
    insert_variant( counter = '00001' ).

    DATA drafts TYPE STANDARD TABLE OF ztda_variants_d WITH EMPTY KEY.
    drafts = VALUE #( ( progname = test_program parameterid = test_parameter counter = '00005' ) ).
    sql_environment->insert_test_data( drafts ).

    " when
    DATA(counters) = cut->read_last_counters( VALUE #( ( progname    = test_program
                                                         parameterid = test_parameter ) ) ).

    " then
    cl_abap_unit_assert=>assert_equals( exp = '00005'
                                        act = counters[ 1 ]-counter
                                        msg = `A pending draft must block its counter` ).
  ENDMETHOD.

  METHOD given_two_keys_then_both.
    " given
    insert_variant( counter = '00003' ).
    insert_variant( counter   = '00007'
                    parameter = 'OTHER' ).
    insert_variant( counter   = '00009'
                    parameter = 'UNASKED' ).

    " when - the same key twice, as a request with two entities would send it
    DATA(counters) = cut->read_last_counters( VALUE #( progname = test_program
                                                       ( parameterid = test_parameter )
                                                       ( parameterid = test_parameter )
                                                       ( parameterid = 'OTHER' ) ) ).

    " then
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( counters )
                                        msg = `Every asked key is answered once, unasked keys stay out` ).

    cl_abap_unit_assert=>assert_equals( exp = '00007'
                                        act = counters[ progname    = test_program
                                                        parameterid = 'OTHER' ]-counter
                                        msg = `Each key must carry its own highest counter` ).
  ENDMETHOD.

  METHOD given_taken_key_then_false.
    " given
    insert_variant( counter = '00001' ).

    " when
    DATA(inserted) = cut->insert_row( row( '00001' ) ).

    " then
    cl_abap_unit_assert=>assert_false( act = inserted
                                       msg = `A taken key is a signal for the caller, not an error` ).
  ENDMETHOD.

  METHOD given_delete_all_then_count.
    " given
    insert_variant( counter = '00001' ).
    insert_variant( counter = '00002' ).
    insert_variant( counter   = '00001'
                    parameter = 'OTHER' ).

    " when
    DATA(removed) = cut->delete_rows( program_name = test_program
                                      parameter_id = test_parameter ).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = 2
        act = removed
        msg = `Deleting a parameter must report the rows it removed and spare the others` ).
  ENDMETHOD.

  METHOD insert_variant.
    sql_environment->insert_test_data( VALUE zcl_da_variants=>ty_variants( ( progname    = test_program
                                                                             parameterid = parameter
                                                                             counter     = counter
                                                                             is_active   = is_active
                                                                             sign        = 'I'
                                                                             opt         = 'EQ'
                                                                             value       = 'X' ) ) ).
  ENDMETHOD.

  METHOD row.
    result = VALUE #( progname    = test_program
                      parameterid = test_parameter
                      counter     = counter
                      is_active   = abap_true
                      sign        = 'I'
                      opt         = 'EQ'
                      value       = 'Y' ).
  ENDMETHOD.
ENDCLASS.
