*"* use this source file for your ABAP unit test classes
CLASS ltc_numbering DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    CONSTANTS test_program   TYPE zda_variants-progname    VALUE 'TEST_PROG' ##NO_TEXT.
    CONSTANTS test_parameter TYPE zda_variants-parameterid VALUE 'UNIT_TEST' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    "! Regression for two entities of one request sharing a counter.
    METHODS given_two_new_then_uniq_ctr FOR TESTING RAISING cx_static_check.
    "! Numbering must continue after the highest stored counter.
    METHODS given_stored_then_next_counter  FOR TESTING RAISING cx_static_check.
    "! A new variant must be active without the user ticking the box.
    METHODS given_new_then_active FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_numbering IMPLEMENTATION.

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
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.


  METHOD given_two_new_then_uniq_ctr.

    " when - two entities for the same key inside one request
    MODIFY ENTITIES OF zi_da_variants
      ENTITY Variants
      CREATE FIELDS ( Progname Parameterid Value )
      WITH VALUE #( ( %cid        = 'C1'
                      Progname    = test_program
                      Parameterid = test_parameter
                      Value       = 'A' )
                    ( %cid        = 'C2'
                      Progname    = test_program
                      Parameterid = test_parameter
                      Value       = 'B' ) )
      MAPPED DATA(mapped)
      FAILED DATA(failed).

    " then
    cl_abap_unit_assert=>assert_initial(
        act = failed
        msg = 'Creating two variants for one key must not fail' ).

    cl_abap_unit_assert=>assert_differs(
        exp = mapped-variants[ %cid = 'C1' ]-Counter
        act = mapped-variants[ %cid = 'C2' ]-Counter
        msg = 'Each entity of one request must get its own counter' ).

  ENDMETHOD.


  METHOD given_stored_then_next_counter.

    " given
    sql_environment->insert_test_data( VALUE zcl_da_variants=>ty_variants(
      ( progname    = test_program
        parameterid = test_parameter
        counter     = '00007'
        is_active   = abap_true
        sign        = 'I'
        opt         = 'EQ'
        value       = 'A' ) ) ).

    " when
    MODIFY ENTITIES OF zi_da_variants
      ENTITY Variants
      CREATE FIELDS ( Progname Parameterid Value )
      WITH VALUE #( ( %cid        = 'C1'
                      Progname    = test_program
                      Parameterid = test_parameter
                      Value       = 'B' ) )
      MAPPED DATA(mapped).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = '00008'
        act = mapped-variants[ %cid = 'C1' ]-Counter
        msg = 'Numbering must continue after the highest stored counter' ).

  ENDMETHOD.


  METHOD given_new_then_active.

    " when
    MODIFY ENTITIES OF zi_da_variants
      ENTITY Variants
      CREATE FIELDS ( Progname Parameterid Value )
      WITH VALUE #( ( %cid        = 'C1'
                      Progname    = test_program
                      Parameterid = test_parameter
                      Value       = 'A' ) )
      MAPPED DATA(mapped).

    READ ENTITIES OF zi_da_variants
      ENTITY Variants FIELDS ( IsActive Sign Opt )
      WITH VALUE #( ( %tky = mapped-variants[ 1 ]-%tky ) )
      RESULT DATA(variants).

    " then
    cl_abap_unit_assert=>assert_equals(
        exp = abap_true
        act = variants[ 1 ]-IsActive
        msg = 'A new variant must be active without user interaction' ).

  ENDMETHOD.

ENDCLASS.
