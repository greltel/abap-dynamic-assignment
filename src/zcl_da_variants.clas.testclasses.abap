*"* use this source file for your ABAP unit test classes

CLASS ltc_da_variants DEFINITION FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    CLASS-DATA mo_sql_env TYPE REF TO if_osql_test_environment.
    DATA mo_cut           TYPE REF TO zcl_da_variants.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    METHODS set_and_get_single_value FOR TESTING.
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

  METHOD set_and_get_single_value.
    TRY.
        mo_cut->set_variant(
          im_parameterid = 'UNIT_TEST_PARAM'
          im_progname    = 'TEST_PROG'
          im_fieldvalue  = 'HELLO_WORLD'
          im_commit      = abap_false
        ).

        DATA lv_value TYPE zcl_da_variants=>ty_value.
        DATA lv_mapping_value TYPE zcl_da_variants=>ty_value.
        mo_cut->get_variant(
          EXPORTING
            im_parameterid = 'UNIT_TEST_PARAM'
            im_progname    = 'TEST_PROG'
          IMPORTING
            ex_fieldvalue         = lv_value
            ex_mapping_fieldvalue = lv_mapping_value
        ).

        cl_abap_unit_assert=>assert_equals(
          exp = 'HELLO_WORLD'
          act = lv_value
          msg = 'The read value does not match the written value!' ).

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
