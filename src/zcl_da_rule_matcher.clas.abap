"! <p class="shorttext synchronized" lang="EN">Evaluation of one variant rule</p>
"! Production implementation of {@link ZIF_DA_RULE_MATCHER}. Converts the bounds
"! through {@link ZIF_DA_VALUE_CHECK} and compares in the configured type.
CLASS zcl_da_rule_matcher DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_da_rule_matcher.

    "! Creates the matcher on the given value check, or on the production one.
    "! @parameter value_check | Converter for input and bounds
    METHODS constructor
      IMPORTING value_check TYPE REF TO zif_da_value_check OPTIONAL.

  PRIVATE SECTION.


    DATA value_check TYPE REF TO zif_da_value_check.

    "! Compares input and lower bound in the configured type.
    "! @parameter variant         | Rule to evaluate
    "! @parameter input           | Value to classify
    "! @parameter element         | Type the comparison runs in
    "! @parameter result          | <em>abap_true</em> when the rule answers
    "! @raising   zcx_da_variants | A bound or the input does not convert
    METHODS accepts_typed
      IMPORTING variant       TYPE zif_da_variants=>ty_variant
                input         TYPE zif_da_variants=>ty_value
                element       TYPE REF TO cl_abap_elemdescr
      RETURNING VALUE(result) TYPE abap_boolean
      RAISING   zcx_da_variants.

    "! Evaluates the two sided operators BT and NB in the configured type.
    "! @parameter variant         | Rule to evaluate, must carry both bounds
    "! @parameter input           | Value to classify
    "! @parameter element         | Type the comparison runs in
    "! @parameter result          | <em>abap_true</em> when the rule answers
    "! @raising   zcx_da_variants | A bound or the input does not convert
    METHODS accepts_bounds
      IMPORTING variant       TYPE zif_da_variants=>ty_variant
                input         TYPE zif_da_variants=>ty_value
                element       TYPE REF TO cl_abap_elemdescr
      RETURNING VALUE(result) TYPE abap_boolean
      RAISING   zcx_da_variants.

ENDCLASS.



CLASS zcl_da_rule_matcher IMPLEMENTATION.


  METHOD constructor.

    me->value_check = COND #( WHEN value_check IS BOUND
                              THEN value_check
                              ELSE NEW zcl_da_value_check( ) ).

  ENDMETHOD.


  METHOD zif_da_rule_matcher~accepts.

    " a pattern is character matching and stays on the stored strings
    IF variant-opt = zif_da_variants=>opt_cp.
      result = xsdbool( input CP variant-value ).
      RETURN.
    ENDIF.

    IF variant-opt = zif_da_variants=>opt_np.
      result = xsdbool( input NP variant-value ).
      RETURN.
    ENDIF.

    result = accepts_typed( variant = variant
                            input   = input
                            element = element ).

  ENDMETHOD.


  METHOD accepts_typed.

    IF variant-opt = zif_da_variants=>opt_bt OR variant-opt = zif_da_variants=>opt_nb.
      result = accepts_bounds( variant = variant
                               input   = input
                               element = element ).
      RETURN.
    ENDIF.

    DATA(typed_input) = value_check->convert( value        = input
                                              data_element = variant-data_element
                                              element      = element ).

    DATA(typed_low)   = value_check->convert( value        = variant-value
                                              data_element = variant-data_element
                                              element      = element ).

    ASSIGN typed_input->* TO FIELD-SYMBOL(<input>).
    ASSIGN typed_low->*   TO FIELD-SYMBOL(<low>).

    CASE variant-opt.
      WHEN zif_da_variants=>opt_eq.
        result = xsdbool( <input> =  <low> ).
      WHEN zif_da_variants=>opt_ne.
        result = xsdbool( <input> <> <low> ).
      WHEN zif_da_variants=>opt_lt.
        result = xsdbool( <input> <  <low> ).
      WHEN zif_da_variants=>opt_le.
        result = xsdbool( <input> <= <low> ).
      WHEN zif_da_variants=>opt_gt.
        result = xsdbool( <input> >  <low> ).
      WHEN zif_da_variants=>opt_ge.
        result = xsdbool( <input> >= <low> ).
      WHEN OTHERS.
        result = abap_false.
    ENDCASE.

  ENDMETHOD.


  METHOD accepts_bounds.

    DATA(typed_input) = value_check->convert( value        = input
                                              data_element = variant-data_element
                                              element      = element ).

    DATA(typed_low)   = value_check->convert( value        = variant-value
                                              data_element = variant-data_element
                                              element      = element ).

    DATA(typed_high)  = value_check->convert( value        = variant-high_value
                                              data_element = variant-data_element
                                              element      = element ).

    ASSIGN typed_input->* TO FIELD-SYMBOL(<input>).
    ASSIGN typed_low->*   TO FIELD-SYMBOL(<low>).
    ASSIGN typed_high->*  TO FIELD-SYMBOL(<high>).

    DATA(inside) = xsdbool( <input> >= <low> AND <input> <= <high> ).

    result = COND #( WHEN variant-opt = zif_da_variants=>opt_nb
                     THEN xsdbool( inside = abap_false )
                     ELSE inside ).

  ENDMETHOD.


ENDCLASS.
