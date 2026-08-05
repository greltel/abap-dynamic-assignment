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

    CONSTANTS activity_create TYPE c LENGTH 2 VALUE '01' ##NO_TEXT.
    CONSTANTS activity_change TYPE c LENGTH 2 VALUE '02' ##NO_TEXT.
    CONSTANTS activity_delete TYPE c LENGTH 2 VALUE '06' ##NO_TEXT.

    CONSTANTS option_between     TYPE zde_da_opt  VALUE 'BT' ##NO_TEXT.
    CONSTANTS option_not_between TYPE zde_da_opt  VALUE 'NB' ##NO_TEXT.
    CONSTANTS option_equal       TYPE zde_da_opt  VALUE 'EQ' ##NO_TEXT.
    CONSTANTS sign_include       TYPE zde_da_sign VALUE 'I'  ##NO_TEXT.

    CONSTANTS state_area_elements TYPE string VALUE `VALIDATE_DATA_ELEMENTS` ##NO_TEXT.
    CONSTANTS state_area_range    TYPE string VALUE `VALIDATE_RANGE`         ##NO_TEXT.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Variants RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Variants RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Variants RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Variants.

    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Variants~setDefaults.

    METHODS checkDataElements FOR VALIDATE ON SAVE
      IMPORTING keys FOR Variants~checkDataElements.

    METHODS checkRangeConsistency FOR VALIDATE ON SAVE
      IMPORTING keys FOR Variants~checkRangeConsistency.

    "! Checks whether a name refers to an existing elementary DDIC type.
    METHODS data_element_exists
      IMPORTING data_element  TYPE zda_variants-data_element
      RETURNING VALUE(result) TYPE abap_boolean.

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
      ENTITY Variants FIELDS ( Progname ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      AUTHORITY-CHECK OBJECT 'ZDA_VAR'
        ID 'ACTVT'    FIELD activity_change
        ID 'ZDA_PROG' FIELD variant-Progname.
      DATA(change_allowed) = COND #( WHEN sy-subrc = 0
                                     THEN if_abap_behv=>auth-allowed
                                     ELSE if_abap_behv=>auth-unauthorized ).

      AUTHORITY-CHECK OBJECT 'ZDA_VAR'
        ID 'ACTVT'    FIELD activity_delete
        ID 'ZDA_PROG' FIELD variant-Progname.
      DATA(delete_allowed) = COND #( WHEN sy-subrc = 0
                                     THEN if_abap_behv=>auth-allowed
                                     ELSE if_abap_behv=>auth-unauthorized ).

      APPEND VALUE #( %tky    = variant-%tky
                      %update = change_allowed
                      %delete = delete_allowed ) TO result.

    ENDLOOP.

  ENDMETHOD.


  METHOD get_instance_features.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY Variants FIELDS ( Opt ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    result = VALUE #( FOR variant IN variants
                      ( %tky             = variant-%tky
                        %field-HighValue = COND #(
                            WHEN variant-Opt = option_between
                              OR variant-Opt = option_not_between
                            THEN if_abap_behv=>fc-f-unrestricted
                            ELSE if_abap_behv=>fc-f-read_only ) ) ).

  ENDMETHOD.


  METHOD earlynumbering_create.

    DATA last_counters TYPE ty_last_counters.

    LOOP AT entities INTO DATA(entity).

      ASSIGN last_counters[ progname    = entity-Progname
                            parameterid = entity-Parameterid ] TO FIELD-SYMBOL(<last_counter>).

      IF sy-subrc <> 0.
        " read once per distinct key, then keep counting inside the buffer so that
        " several entities of one request never share a counter
        SELECT FROM zda_variants
          FIELDS MAX( counter ) AS counter
          WHERE progname    = @entity-Progname
            AND parameterid = @entity-Parameterid
          INTO @DATA(active_counter).

        SELECT FROM zda_variants_d
          FIELDS MAX( counter ) AS counter
          WHERE progname    = @entity-Progname
            AND parameterid = @entity-Parameterid
          INTO @DATA(draft_counter).

        INSERT VALUE #( progname    = entity-Progname
                        parameterid = entity-Parameterid
                        counter     = nmax( val1 = active_counter
                                            val2 = draft_counter ) ) INTO TABLE last_counters
                                                                     ASSIGNING <last_counter>.
      ENDIF.

      <last_counter>-counter += 1.

      APPEND VALUE #( %cid        = entity-%cid
                      %is_draft   = entity-%is_draft
                      Progname    = entity-Progname
                      Parameterid = entity-Parameterid
                      Counter     = <last_counter>-counter ) TO mapped-variants.

    ENDLOOP.

  ENDMETHOD.


  METHOD setDefaults.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY Variants FIELDS ( IsActive Sign Opt ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    DATA defaults TYPE TABLE FOR UPDATE zi_da_variants\\Variants.

    defaults = VALUE #(
        FOR variant IN variants
        WHERE ( IsActive IS INITIAL OR Sign IS INITIAL OR Opt IS INITIAL )
        ( %tky     = variant-%tky
          IsActive = COND #( WHEN variant-IsActive IS INITIAL
                             THEN abap_true ELSE variant-IsActive )
          Sign     = COND #( WHEN variant-Sign IS INITIAL
                             THEN sign_include ELSE variant-Sign )
          Opt      = COND #( WHEN variant-Opt IS INITIAL
                             THEN option_equal ELSE variant-Opt ) ) ).

    IF defaults IS INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY Variants
      UPDATE FIELDS ( IsActive Sign Opt )
      WITH defaults
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.


  METHOD checkDataElements.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY Variants FIELDS ( DataElement MappingDataElement MappingValue )
      WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      " reset the messages of the previous run for this instance
      APPEND VALUE #( %tky        = variant-%tky
                      %state_area = state_area_elements ) TO reported-variants.

      DATA(checks) = VALUE ty_element_checks(
          ( element = variant-DataElement        is_map = abap_false )
          ( element = variant-MappingDataElement is_map = abap_true ) ).

      LOOP AT checks INTO DATA(check) WHERE element IS NOT INITIAL.

        IF data_element_exists( check-element ) = abap_true.
          CONTINUE.
        ENDIF.

        APPEND VALUE #( %tky = variant-%tky ) TO failed-variants.

        APPEND VALUE #( %tky        = variant-%tky
                        %state_area = state_area_elements
                        %element-DataElement        = COND #( WHEN check-is_map = abap_false
                                                              THEN if_abap_behv=>mk-on )
                        %element-MappingDataElement = COND #( WHEN check-is_map = abap_true
                                                              THEN if_abap_behv=>mk-on )
                        %msg        = new_message_with_text(
                                          severity = if_abap_behv_message=>severity-error
                                          text     = |{ TEXT-003 } { check-element }| )
                      ) TO reported-variants.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD checkRangeConsistency.

    READ ENTITIES OF zi_da_variants IN LOCAL MODE
      ENTITY Variants FIELDS ( Sign Opt Value HighValue ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      APPEND VALUE #( %tky        = variant-%tky
                      %state_area = state_area_range ) TO reported-variants.

      DATA(needs_high_value) = xsdbool( variant-Opt = option_between
                                     OR variant-Opt = option_not_between ).

      IF needs_high_value = abap_true AND variant-HighValue IS INITIAL.
        APPEND VALUE #( %tky = variant-%tky ) TO failed-variants.
        APPEND VALUE #( %tky               = variant-%tky
                        %state_area        = state_area_range
                        %element-HighValue = if_abap_behv=>mk-on
                        %msg               = new_message_with_text(
                                                 severity = if_abap_behv_message=>severity-error
                                                 text     = |{ TEXT-001 } { variant-Opt }| )
                      ) TO reported-variants.
        CONTINUE.
      ENDIF.

      IF needs_high_value = abap_false AND variant-HighValue IS NOT INITIAL.
        APPEND VALUE #( %tky = variant-%tky ) TO failed-variants.
        APPEND VALUE #( %tky               = variant-%tky
                        %state_area        = state_area_range
                        %element-HighValue = if_abap_behv=>mk-on
                        %msg               = new_message_with_text(
                                                 severity = if_abap_behv_message=>severity-error
                                                 text     = |{ TEXT-002 } { variant-Opt }| )
                      ) TO reported-variants.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD data_element_exists.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = data_element
                                         RECEIVING  p_descr_ref    = DATA(type)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    result = xsdbool( type->kind = cl_abap_typedescr=>kind_elem ).

  ENDMETHOD.


ENDCLASS.
