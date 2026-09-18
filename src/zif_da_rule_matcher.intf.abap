"! <p class="shorttext synchronized" lang="EN">Evaluation of one variant rule</p>
"! Answers whether a configured rule, that is sign, option and bounds of one
"! variant row, accepts an input value.
INTERFACE zif_da_rule_matcher
  PUBLIC.

  "! Answers whether one rule accepts the input value.
  "! <p>Patterns compare on the stored strings; every other operator compares in
  "! the configured DDIC type, which is what keeps 9 below 100.</p>
  "! @parameter variant         | Rule to evaluate, carries sign, option and bounds
  "! @parameter input           | Value to classify
  "! @parameter element         | Type the comparison runs in
  "! @parameter result          | <em>abap_true</em> when the rule answers
  "! @raising   zcx_da_variants | A bound or the input does not convert
  METHODS accepts
    IMPORTING variant       TYPE zif_da_variants=>ty_variant
              input         TYPE zif_da_variants=>ty_value
              element       TYPE REF TO cl_abap_elemdescr
    RETURNING VALUE(result) TYPE abap_boolean
    RAISING   zcx_da_variants.

ENDINTERFACE.
