*"* use this source file for your ABAP unit test classes

"! Covers {@link ZCL_DA_RULE_MATCHER} on its own: no database, the real
"! value check, one rule at a time.
CLASS ltc_rule_matcher DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.

    DATA cut         TYPE REF TO zif_da_rule_matcher.
    DATA value_check TYPE REF TO zif_da_value_check.

    CONSTANTS numeric_element TYPE zif_da_variants=>ty_data_el VALUE 'ZDE_DA_COUNTER' ##NO_TEXT.

    METHODS setup.

    "! EQ compares in the DDIC type, so 9 and 00009 are the same NUMC value.
    METHODS given_eq_numc_then_typed      FOR TESTING RAISING cx_static_check.
    "! GE compares numerically, so 9 stays below 100.
    METHODS given_ge_numc_then_numeric    FOR TESTING RAISING cx_static_check.
    "! CP compares on the stored strings, wildcards included.
    METHODS given_cp_then_pattern         FOR TESTING RAISING cx_static_check.
    "! NB is the complement of BT.
    METHODS given_nb_inside_then_rejected FOR TESTING RAISING cx_static_check.
    "! An unknown operator answers false instead of dumping.
    METHODS given_unknown_opt_then_false  FOR TESTING RAISING cx_static_check.
    "! An input the type cannot hold is reported, not silently compared.
    METHODS given_bad_input_then_error    FOR TESTING RAISING cx_static_check.

    METHODS rule
      IMPORTING option        TYPE zif_da_variants=>ty_base_opt
                low           TYPE zif_da_variants=>ty_value
                high          TYPE zif_da_variants=>ty_value    OPTIONAL
                data_element  TYPE zif_da_variants=>ty_data_el OPTIONAL
      RETURNING VALUE(result) TYPE zif_da_variants=>ty_variant.

    METHODS element_of
      IMPORTING variant       TYPE zif_da_variants=>ty_variant
      RETURNING VALUE(result) TYPE REF TO cl_abap_elemdescr
      RAISING   zcx_da_variants.

ENDCLASS.


CLASS ltc_rule_matcher IMPLEMENTATION.

  METHOD setup.
    value_check = NEW zcl_da_value_check( ).
    cut         = NEW zcl_da_rule_matcher( value_check ).
  ENDMETHOD.


  METHOD given_eq_numc_then_typed.

    DATA(variant) = rule( option = 'EQ' low = '9' data_element = numeric_element ).

    cl_abap_unit_assert=>assert_true(
        act = cut->accepts( variant = variant input = '00009' element = element_of( variant ) )
        msg = `EQ must compare in the DDIC type, where 9 and 00009 are equal` ).

  ENDMETHOD.


  METHOD given_ge_numc_then_numeric.

    DATA(variant) = rule( option = 'GE' low = '100' data_element = numeric_element ).

    cl_abap_unit_assert=>assert_false(
        act = cut->accepts( variant = variant input = '9' element = element_of( variant ) )
        msg = `GE must compare numerically, 9 is below 100` ).

  ENDMETHOD.


  METHOD given_cp_then_pattern.

    DATA(variant) = rule( option = 'CP' low = 'CUST*' ).

    cl_abap_unit_assert=>assert_true(
        act = cut->accepts( variant = variant input = 'CUSTOMER' element = element_of( variant ) )
        msg = `CP must match the stored pattern character wise` ).

  ENDMETHOD.


  METHOD given_nb_inside_then_rejected.

    DATA(variant) = rule( option = 'NB' low = '10' high = '20' data_element = numeric_element ).

    cl_abap_unit_assert=>assert_false(
        act = cut->accepts( variant = variant input = '15' element = element_of( variant ) )
        msg = `NB must reject a value inside the bounds` ).

  ENDMETHOD.


  METHOD given_unknown_opt_then_false.

    DATA(variant) = rule( option = 'XX' low = 'A' ).

    cl_abap_unit_assert=>assert_false(
        act = cut->accepts( variant = variant input = 'A' element = element_of( variant ) )
        msg = `An operator the matcher does not know must not accept anything` ).

  ENDMETHOD.


  METHOD given_bad_input_then_error.

    DATA(variant) = rule( option = 'EQ' low = '1' data_element = 'ZDE_DA_SIGN' ).

    TRY.
        cut->accepts( variant = variant input = 'TOO LONG FOR A SIGN' element = element_of( variant ) ).

        cl_abap_unit_assert=>fail( msg = `An input that overflows its type must be reported` ).

      CATCH zcx_da_variants.
        " then - expected
    ENDTRY.

  ENDMETHOD.


  METHOD rule.

    result = VALUE #( progname     = 'TEST_PROG'
                      parameterid  = 'UNIT_TEST'
                      counter      = '00001'
                      is_active    = abap_true
                      sign         = 'I'
                      opt          = option
                      value        = low
                      high_value   = high
                      data_element = data_element ).

  ENDMETHOD.


  METHOD element_of.

    result = value_check->resolve_element_type( data_element = variant-data_element
                                                sample_value = variant-value ).

  ENDMETHOD.

ENDCLASS.
