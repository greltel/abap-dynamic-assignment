CLASS lhc_variants DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_last_counter,
             progname    TYPE zda_variants-progname,
             parameterid TYPE zda_variants-parameterid,
             counter     TYPE zda_variants-counter,
           END OF ty_last_counter.

    TYPES ty_last_counters TYPE SORTED TABLE OF ty_last_counter
                                WITH UNIQUE KEY progname parameterid.

    TYPES: BEGIN OF ty_element_check,
             element TYPE zda_variants-data_element,
             is_map  TYPE abap_boolean,
           END OF ty_element_check.

    TYPES ty_element_checks TYPE STANDARD TABLE OF ty_element_check WITH EMPTY KEY.

    TYPES: BEGIN OF ty_value_check,
             value   TYPE zda_variants-value,
             element TYPE zda_variants-data_element,
             target  TYPE string,
           END OF ty_value_check.

    TYPES ty_value_checks TYPE STANDARD TABLE OF ty_value_check WITH EMPTY KEY.

    CONSTANTS activity_create TYPE c LENGTH 2 VALUE '01' ##NO_TEXT.
    CONSTANTS activity_change TYPE c LENGTH 2 VALUE '02' ##NO_TEXT.
    CONSTANTS activity_delete TYPE c LENGTH 2 VALUE '06' ##NO_TEXT.

    CONSTANTS option_between     TYPE zde_da_opt  VALUE 'BT' ##NO_TEXT.
    CONSTANTS option_not_between TYPE zde_da_opt  VALUE 'NB' ##NO_TEXT.
    CONSTANTS option_equal       TYPE zde_da_opt  VALUE 'EQ' ##NO_TEXT.
    CONSTANTS sign_include       TYPE zde_da_sign VALUE 'I'  ##NO_TEXT.

    CONSTANTS state_area_elements TYPE string VALUE `VALIDATE_DATA_ELEMENTS` ##NO_TEXT.
    CONSTANTS state_area_range    TYPE string VALUE `VALIDATE_RANGE`         ##NO_TEXT.
    CONSTANTS state_area_values   TYPE string VALUE `VALIDATE_VALUE_TYPES`   ##NO_TEXT.

    CONSTANTS element_value   TYPE string VALUE `VALUE`        ##NO_TEXT.
    CONSTANTS element_high    TYPE string VALUE `HIGHVALUE`    ##NO_TEXT.
    CONSTANTS element_mapping TYPE string VALUE `MAPPINGVALUE` ##NO_TEXT.

    "! Highest counter the NUMC(5) key can hold.
    CONSTANTS max_counter TYPE zda_variants-counter VALUE '99999' ##NO_TEXT.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR variants RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR variants RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE variants.

    METHODS setdefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR variants~setdefaults.

    METHODS checkdataelements FOR VALIDATE ON SAVE
      IMPORTING keys FOR variants~checkdataelements.

    METHODS checkrangeconsistency FOR VALIDATE ON SAVE
      IMPORTING keys FOR variants~checkrangeconsistency.

    METHODS checkvaluetypes FOR VALIDATE ON SAVE
      IMPORTING keys FOR variants~checkvaluetypes.

ENDCLASS.


CLASS lhc_variants IMPLEMENTATION.


  METHOD get_global_authorizations.

    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'ZDA_VAR'
        ID 'ACTVT'    FIELD activity_create
        ID 'ZDA_PROG' DUMMY.
      result-%create = COND #( WHEN sy-subrc = 0
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'ZDA_VAR'
        ID 'ACTVT'    FIELD activity_change
        ID 'ZDA_PROG' DUMMY.
      result-%update = COND #( WHEN sy-subrc = 0
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      AUTHORITY-CHECK OBJECT 'ZDA_VAR'
        ID 'ACTVT'    FIELD activity_delete
        ID 'ZDA_PROG' DUMMY.
      result-%delete = COND #( WHEN sy-subrc = 0
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

  ENDMETHOD.


  METHOD get_instance_authorizations.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( progname ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      AUTHORITY-CHECK OBJECT 'ZDA_VAR'
        ID 'ACTVT'    FIELD activity_change
        ID 'ZDA_PROG' FIELD variant-progname.
      DATA(change_allowed) = COND #( WHEN sy-subrc = 0
                                     THEN if_abap_behv=>auth-allowed
                                     ELSE if_abap_behv=>auth-unauthorized ).

      AUTHORITY-CHECK OBJECT 'ZDA_VAR'
        ID 'ACTVT'    FIELD activity_delete
        ID 'ZDA_PROG' FIELD variant-progname.
      DATA(delete_allowed) = COND #( WHEN sy-subrc = 0
                                     THEN if_abap_behv=>auth-allowed
                                     ELSE if_abap_behv=>auth-unauthorized ).

      APPEND VALUE #( %tky    = variant-%tky
                      %update = change_allowed
                      %delete = delete_allowed ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA last_counters TYPE ty_last_counters.

    LOOP AT entities INTO DATA(entity).

      ASSIGN last_counters[ progname    = entity-progname
                            parameterid = entity-parameterid ] TO FIELD-SYMBOL(<last_counter>).

      IF sy-subrc <> 0.
        " read once per distinct key, then keep counting inside the buffer so that
        " several entities of one request never share a counter
        SELECT FROM zda_variants
          FIELDS MAX( counter ) AS counter
          WHERE progname    = @entity-progname
            AND parameterid = @entity-parameterid
          INTO @DATA(active_counter).

        SELECT FROM zda_variants_d
          FIELDS MAX( counter ) AS counter
          WHERE progname    = @entity-progname
            AND parameterid = @entity-parameterid
          INTO @DATA(draft_counter).

        INSERT VALUE #( progname    = entity-progname
                        parameterid = entity-parameterid
                        counter     = nmax( val1 = active_counter
                                            val2 = draft_counter ) ) INTO TABLE last_counters
                                                                     ASSIGNING <last_counter>.
      ENDIF.

      IF <last_counter>-counter >= max_counter.
        " NUMC(5) wraps to 00000 without any error, so the ceiling is checked here
        APPEND VALUE #( %cid      = entity-%cid
                        %is_draft = entity-%is_draft ) TO failed-variants.

        APPEND VALUE #( %cid      = entity-%cid
                        %is_draft = entity-%is_draft
                        %msg      = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = |{ TEXT-004 } { entity-parameterid }| )
                      ) TO reported-variants.
        CONTINUE.
      ENDIF.

      <last_counter>-counter += 1.

      APPEND VALUE #( %cid        = entity-%cid
                      %is_draft   = entity-%is_draft
                      progname    = entity-progname
                      parameterid = entity-parameterid
                      counter     = <last_counter>-counter ) TO mapped-variants.

    ENDLOOP.

  ENDMETHOD.


  METHOD setdefaults.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( isactive sign opt ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    DATA defaults TYPE TABLE FOR UPDATE zi_da_variants\\variants.

    defaults = VALUE #(
        FOR variant IN variants
        WHERE ( isactive IS INITIAL OR sign IS INITIAL OR opt IS INITIAL )
        ( %tky     = variant-%tky
          isactive = COND #( WHEN variant-isactive IS INITIAL
                             THEN abap_true ELSE variant-isactive )
          sign     = COND #( WHEN variant-sign IS INITIAL
                             THEN sign_include ELSE variant-sign )
          opt      = COND #( WHEN variant-opt IS INITIAL
                             THEN option_equal ELSE variant-opt ) ) ).

    IF defaults IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY variants
      UPDATE FIELDS ( isactive sign opt )
      WITH defaults
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.


  METHOD checkdataelements.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( dataelement mappingdataelement mappingvalue )
      WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      " reset the messages of the previous run for this instance
      APPEND VALUE #( %tky        = variant-%tky
                      %state_area = state_area_elements ) TO reported-variants.

      DATA(checks) = VALUE ty_element_checks(
          ( element = variant-dataelement        is_map = abap_false )
          ( element = variant-mappingdataelement is_map = abap_true ) ).

      LOOP AT checks INTO DATA(check) WHERE element IS NOT INITIAL.

        IF zcl_da_variants=>data_element_exists( check-element ) = abap_true.
          CONTINUE.
        ENDIF.

        APPEND VALUE #( %tky = variant-%tky ) TO failed-variants.

        APPEND VALUE #( %tky        = variant-%tky
                        %state_area = state_area_elements
                        %element-dataelement        = COND #( WHEN check-is_map = abap_false
                                                              THEN if_abap_behv=>mk-on )
                        %element-mappingdataelement = COND #( WHEN check-is_map = abap_true
                                                              THEN if_abap_behv=>mk-on )
                        %msg        = new_message_with_text(
                                          severity = if_abap_behv_message=>severity-error
                                          text     = |{ TEXT-003 } { check-element }| )
                      ) TO reported-variants.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD checkrangeconsistency.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( sign opt value highvalue ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      APPEND VALUE #( %tky        = variant-%tky
                      %state_area = state_area_range ) TO reported-variants.

      DATA(needs_high_value) = xsdbool( variant-opt = option_between
                                     OR variant-opt = option_not_between ).

      IF needs_high_value = abap_true AND variant-highvalue IS INITIAL.
        APPEND VALUE #( %tky = variant-%tky ) TO failed-variants.
        APPEND VALUE #( %tky               = variant-%tky
                        %state_area        = state_area_range
                        %element-highvalue = if_abap_behv=>mk-on
                        %msg               = new_message_with_text(
                                                 severity = if_abap_behv_message=>severity-error
                                                 text     = |{ TEXT-001 } { variant-opt }| )
                      ) TO reported-variants.
        CONTINUE.
      ENDIF.

      IF needs_high_value = abap_false AND variant-highvalue IS NOT INITIAL.
        APPEND VALUE #( %tky = variant-%tky ) TO failed-variants.
        APPEND VALUE #( %tky               = variant-%tky
                        %state_area        = state_area_range
                        %element-highvalue = if_abap_behv=>mk-on
                        %msg               = new_message_with_text(
                                                 severity = if_abap_behv_message=>severity-error
                                                 text     = |{ TEXT-002 } { variant-opt }| )
                      ) TO reported-variants.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD checkvaluetypes.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( value highvalue dataelement mappingvalue mappingdataelement )
      WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      " reset the messages of the previous run for this instance
      APPEND VALUE #( %tky        = variant-%tky
                      %state_area = state_area_values ) TO reported-variants.

      " both bounds live in the same column and therefore in the same type
      DATA(checks) = VALUE ty_value_checks(
          ( value   = variant-value
            element = variant-dataelement
            target  = element_value )
          ( value   = variant-highvalue
            element = variant-dataelement
            target  = element_high )
          ( value   = variant-mappingvalue
            element = variant-mappingdataelement
            target  = element_mapping ) ).

      LOOP AT checks INTO DATA(check) WHERE value IS NOT INITIAL AND element IS NOT INITIAL.

        TRY.
            " one implementation for both doors into the configuration table
            zcl_da_variants=>check_value( value        = check-value
                                          data_element = check-element ).

          CATCH zcx_da_variants INTO DATA(type_error).

            APPEND VALUE #( %tky = variant-%tky ) TO failed-variants.

            APPEND VALUE #( %tky        = variant-%tky
                            %state_area = state_area_values
                            %element-value        = COND #( WHEN check-target = element_value
                                                            THEN if_abap_behv=>mk-on )
                            %element-highvalue    = COND #( WHEN check-target = element_high
                                                            THEN if_abap_behv=>mk-on )
                            %element-mappingvalue = COND #( WHEN check-target = element_mapping
                                                            THEN if_abap_behv=>mk-on )
                            %msg        = new_message_with_text(
                                              severity = if_abap_behv_message=>severity-error
                                              text     = type_error->get_text( ) )
                          ) TO reported-variants.
        ENDTRY.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
