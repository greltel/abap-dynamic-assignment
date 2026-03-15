*"* use this source file for your ABAP unit test classes

CLASS ltc_da_variants DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    CLASS-DATA mo_sql_env TYPE REF TO if_osql_test_environment.
    DATA mo_cut           TYPE REF TO zcl_da_variants.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    METHODS set_and_get_full_variant FOR TESTING.
    METHODS get_missing_parameter    FOR TESTING.
    METHODS set_invalid_data_element FOR TESTING.
ENDCLASS.

CLASS ltc_da_variants IMPLEMENTATION.

  METHOD class_setup.
    mo_sql_env = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZDA_VARIANTS' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    mo_sql_env->destroy( ).
  ENDMETHOD.

  METHOD setup.
    mo_sql_env->clear_doubles( ).
    mo_cut = NEW zcl_da_variants( ).
  ENDMETHOD.

  METHOD teardown.
  ENDMETHOD.

  METHOD set_and_get_full_variant.
    TRY.
        mo_cut->set_variant(
          im_parameterid = 'UNIT_TEST_RANGE'
          im_progname    = 'TEST_PROG'
          im_sign        = zcl_da_variants=>sign_include
          im_opt         = zcl_da_variants=>opt_bt
          im_fieldvalue  = '1000'
          im_high_value  = '2000'
          im_is_active   = abap_true
          im_commit      = abap_false
        ).

        DATA lv_value        TYPE zcl_da_variants=>ty_value.
        DATA lt_range_table  TYPE RANGE OF zcl_da_variants=>ty_value.
        DATA lt_table_values TYPE STANDARD TABLE OF zcl_da_variants=>ty_value.

        mo_cut->get_variant(
          EXPORTING
            im_parameterid  = 'UNIT_TEST_RANGE'
            im_progname     = 'TEST_PROG'
          IMPORTING
            ex_fieldvalue   = lv_value
            ex_range        = lt_range_table
            ex_table_values = lt_table_values
        ).

        cl_abap_unit_assert=>assert_equals(
          exp = '1000'
          act = lv_value
          msg = 'Single Value (LOW) is incorrect!' ).

        cl_abap_unit_assert=>assert_not_initial(
          act = lt_range_table
          msg = 'Range table should not be empty!' ).

        cl_abap_unit_assert=>assert_equals(
          exp = 1
          act = lines( lt_range_table )
          msg = 'Range table should contain exactly 1 row!' ).

        READ TABLE lt_range_table INTO DATA(ls_range) INDEX 1.

        ASSIGN COMPONENT 'LOW' OF STRUCTURE ls_range TO FIELD-SYMBOL(<low>).
        cl_abap_unit_assert=>assert_equals( exp = '1000' act = <low> msg = 'Range LOW is incorrect!' ).

        ASSIGN COMPONENT 'HIGH' OF STRUCTURE ls_range TO FIELD-SYMBOL(<high>).
        cl_abap_unit_assert=>assert_equals( exp = '2000' act = <high> msg = 'Range HIGH is incorrect!' ).

        ASSIGN COMPONENT 'OPTION' OF STRUCTURE ls_range TO FIELD-SYMBOL(<opt>).
        cl_abap_unit_assert=>assert_equals( exp = 'BT' act = <opt> msg = 'Range OPTION is incorrect!' ).

        ASSIGN COMPONENT 'SIGN' OF STRUCTURE ls_range TO FIELD-SYMBOL(<sign>).
        cl_abap_unit_assert=>assert_equals( exp = 'I' act = <sign> msg = 'Range SIGN is incorrect!' ).

      CATCH zcx_da_variants INTO DATA(lx_error).
        cl_abap_unit_assert=>fail( msg = lx_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_missing_parameter.
    TRY.
        DATA lv_value TYPE zcl_da_variants=>ty_value.
        mo_cut->get_variant(
          EXPORTING im_parameterid = 'NON_EXISTENT_PARAM'
          IMPORTING ex_fieldvalue  = lv_value
        ).

        cl_abap_unit_assert=>fail( msg = 'An exception (ZCX_DA_VARIANTS) should have been raised!' ).

      CATCH zcx_da_variants.
    ENDTRY.
  ENDMETHOD.

  METHOD set_invalid_data_element.
    TRY.
        mo_cut->set_variant(
          im_parameterid  = 'TEST_PARAM'
          im_fieldvalue   = '123'
          im_data_element = 'DOESNT_EXIST'
        ).

        cl_abap_unit_assert=>fail( msg = 'An exception should have been raised due to an invalid Data Element!' ).

      CATCH zcx_da_variants.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
