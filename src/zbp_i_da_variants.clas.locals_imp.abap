CLASS lhc_Variants DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Variants RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Variants RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Variants.

ENDCLASS.

CLASS lhc_Variants IMPLEMENTATION.

  METHOD get_global_authorizations.
    IF requested_authorizations-%create EQ if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%update EQ if_abap_behv=>mk-on.
      result-%update = if_abap_behv=>auth-allowed.
    ENDIF.
    IF requested_authorizations-%delete EQ if_abap_behv=>mk-on.
      result-%delete = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance_authorizations.
    LOOP AT keys INTO DATA(ls_key).
      APPEND VALUE #( %tky = ls_key-%tky
                      %update = if_abap_behv=>auth-allowed
                      %delete = if_abap_behv=>auth-allowed ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA lv_max_counter TYPE n LENGTH 5.

    LOOP AT entities INTO DATA(ls_entity).

      SELECT SINGLE FROM zda_variants
        FIELDS MAX( counter )
        WHERE progname    = @ls_entity-Progname
          AND parameterid = @ls_entity-Parameterid
        INTO @lv_max_counter.

      lv_max_counter += 1.

      APPEND VALUE #( %cid        = ls_entity-%cid
                      %is_draft   = ls_entity-%is_draft
                      Progname    = ls_entity-Progname
                      Parameterid = ls_entity-Parameterid
                      Counter     = lv_max_counter ) TO mapped-variants.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
