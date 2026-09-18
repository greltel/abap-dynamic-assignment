"! ZBP_R_DA_VARIANTS - Local Types
"! Composition root of the behavior pool. The framework instantiates the
"! handler without arguments, so the handler asks this factory for its
"! collaborators; a test swaps them through the inject_* hooks.
CLASS lcl_variants_factory DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    "! Authorization check the handlers consult.
    "! @parameter result | Injected double, or the production check on ZDA_VAR
    CLASS-METHODS authorization
      RETURNING VALUE(result) TYPE REF TO zif_da_authorization.

    "! Test hook. Pass an unbound reference to restore the production default.
    "! @parameter authorization | Double to serve from now on
    CLASS-METHODS inject_authorization
      IMPORTING authorization TYPE REF TO zif_da_authorization.

  PRIVATE SECTION.

    CLASS-DATA authorization_override TYPE REF TO zif_da_authorization.

ENDCLASS.


CLASS lcl_variants_factory IMPLEMENTATION.

  METHOD authorization.
    result = COND #( WHEN authorization_override IS BOUND
                     THEN authorization_override
                     ELSE NEW zcl_da_authorization( ) ).
  ENDMETHOD.

  METHOD inject_authorization.
    authorization_override = authorization.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_variants DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    TYPES: BEGIN OF ty_last_counter,
             progname    TYPE ztda_variants-progname,
             parameterid TYPE ztda_variants-parameterid,
             counter     TYPE ztda_variants-counter,
           END OF ty_last_counter.

    TYPES ty_last_counters TYPE SORTED TABLE OF ty_last_counter
                                WITH UNIQUE KEY progname parameterid.
    "! Keys as they arrive in a request, duplicates included.
    TYPES ty_counter_keys  TYPE STANDARD TABLE OF ty_last_counter WITH EMPTY KEY.

    TYPES ty_program_range   TYPE RANGE OF ztda_variants-progname.
    TYPES ty_parameter_range TYPE RANGE OF ztda_variants-parameterid.

    TYPES: BEGIN OF ty_element_check,
             element TYPE ztda_variants-data_element,
             is_map  TYPE abap_boolean,
           END OF ty_element_check.

    TYPES ty_element_checks TYPE STANDARD TABLE OF ty_element_check WITH EMPTY KEY.

    TYPES: BEGIN OF ty_value_check,
             value   TYPE ztda_variants-value,
             element TYPE ztda_variants-data_element,
             target  TYPE string,
           END OF ty_value_check.

    TYPES ty_value_checks TYPE STANDARD TABLE OF ty_value_check WITH EMPTY KEY.

    CONSTANTS option_between     TYPE zde_da_opt  VALUE 'BT' ##NO_TEXT.
    CONSTANTS option_not_between TYPE zde_da_opt  VALUE 'NB' ##NO_TEXT.
    CONSTANTS option_equal       TYPE zde_da_opt  VALUE 'EQ' ##NO_TEXT.
    CONSTANTS sign_include       TYPE zde_da_sign VALUE 'I'  ##NO_TEXT.

    CONSTANTS range_include TYPE c LENGTH 1 VALUE 'I'  ##NO_TEXT.
    CONSTANTS range_equal   TYPE c LENGTH 2 VALUE 'EQ' ##NO_TEXT.

    CONSTANTS state_area_elements TYPE string VALUE `VALIDATE_DATA_ELEMENTS` ##NO_TEXT.
    CONSTANTS state_area_range    TYPE string VALUE `VALIDATE_RANGE`         ##NO_TEXT.
    CONSTANTS state_area_values   TYPE string VALUE `VALIDATE_VALUE_TYPES`   ##NO_TEXT.

    CONSTANTS element_value   TYPE string VALUE `VALUE`        ##NO_TEXT.
    CONSTANTS element_high    TYPE string VALUE `HIGHVALUE`    ##NO_TEXT.
    CONSTANTS element_mapping TYPE string VALUE `MAPPINGVALUE` ##NO_TEXT.

    "! Highest counter the NUMC(5) key can hold.
    CONSTANTS max_counter TYPE ztda_variants-counter VALUE '99999' ##NO_TEXT.

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

    "! Reads the highest counter in use for every key of the request in one round trip.
    "! <p>Active rows and pending drafts both block a counter. The numbering handler
    "! needs the maximum across all instances of a key, which EML cannot answer, so
    "! this is the one place in the pool that reads the tables directly.</p>
    "! @parameter keys   | Program and parameter of every entity, duplicates allowed
    "! @parameter result | Highest counter per program and parameter
    METHODS read_last_counters
      IMPORTING keys          TYPE ty_counter_keys
      RETURNING VALUE(result) TYPE ty_last_counters.

    "! Keeps the higher of a stored counter and the one already known for its key.
    "! @parameter counter  | Counter read from one of the tables
    "! @parameter counters | Highest counter per key, updated in place
    METHODS merge_counter
      IMPORTING counter  TYPE ty_last_counter
      CHANGING  counters TYPE ty_last_counters.

ENDCLASS.


CLASS lhc_variants IMPLEMENTATION.


  METHOD get_global_authorizations.

    DATA(authorization) = lcl_variants_factory=>authorization( ).

    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = COND #( WHEN authorization->is_allowed( zif_da_authorization=>activity-create ) = abap_true
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%update = if_abap_behv=>mk-on.
      result-%update = COND #( WHEN authorization->is_allowed( zif_da_authorization=>activity-change ) = abap_true
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
      result-%delete = COND #( WHEN authorization->is_allowed( zif_da_authorization=>activity-delete ) = abap_true
                               THEN if_abap_behv=>auth-allowed
                               ELSE if_abap_behv=>auth-unauthorized ).
    ENDIF.

  ENDMETHOD.


  METHOD get_instance_authorizations.

    READ ENTITIES OF zr_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( progname ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    DATA(authorization) = lcl_variants_factory=>authorization( ).
    DATA instance LIKE LINE OF result.

    LOOP AT variants INTO DATA(variant).

      instance = VALUE #( %tky = variant-%tky ).

      IF requested_authorizations-%update = if_abap_behv=>mk-on.
        instance-%update = COND #( WHEN authorization->is_allowed_for(
                                            activity     = zif_da_authorization=>activity-change
                                            program_name = variant-progname ) = abap_true
                                   THEN if_abap_behv=>auth-allowed
                                   ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      IF requested_authorizations-%delete = if_abap_behv=>mk-on.
        instance-%delete = COND #( WHEN authorization->is_allowed_for(
                                            activity     = zif_da_authorization=>activity-delete
                                            program_name = variant-progname ) = abap_true
                                   THEN if_abap_behv=>auth-allowed
                                   ELSE if_abap_behv=>auth-unauthorized ).
      ENDIF.

      INSERT instance INTO TABLE result.

    ENDLOOP.

  ENDMETHOD.


  METHOD earlynumbering_create.

    DATA(last_counters) = read_last_counters( CORRESPONDING #( entities ) ).

    LOOP AT entities INTO DATA(entity).

      ASSIGN last_counters[ progname    = entity-progname
                            parameterid = entity-parameterid ] TO FIELD-SYMBOL(<last_counter>).

      IF sy-subrc <> 0.
        " nothing stored for this key yet, counting starts inside the request
        INSERT VALUE #( progname    = entity-progname
                        parameterid = entity-parameterid ) INTO TABLE last_counters ASSIGNING <last_counter>.
      ENDIF.

      IF <last_counter>-counter >= max_counter.
        " NUMC(5) wraps to 00000 without any error, so the ceiling is checked here
        INSERT VALUE #( %cid      = entity-%cid
                        %is_draft = entity-%is_draft ) INTO TABLE failed-variants.

        INSERT VALUE #( %cid      = entity-%cid
                        %is_draft = entity-%is_draft
                        %msg      = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text     = |{ TEXT-004 } { entity-parameterid }| )
                      ) INTO TABLE reported-variants.
        CONTINUE.
      ENDIF.

      " several entities of one request for the same key never share a counter
      <last_counter>-counter += 1.

      INSERT VALUE #( %cid        = entity-%cid
                      %is_draft   = entity-%is_draft
                      progname    = entity-progname
                      parameterid = entity-parameterid
                      counter     = <last_counter>-counter ) INTO TABLE mapped-variants.

    ENDLOOP.

  ENDMETHOD.


  METHOD read_last_counters.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    DATA(programs)   = VALUE ty_program_range( FOR GROUPS program OF key IN keys
                                               GROUP BY key-progname
                                               ( sign = range_include option = range_equal low = program ) ).

    DATA(parameters) = VALUE ty_parameter_range( FOR GROUPS parameter OF key IN keys
                                                 GROUP BY key-parameterid
                                                 ( sign = range_include option = range_equal low = parameter ) ).

    SELECT FROM ztda_variants
      FIELDS progname, parameterid, MAX( counter ) AS counter
      WHERE progname    IN @programs
        AND parameterid IN @parameters
      GROUP BY progname, parameterid
      INTO TABLE @DATA(active_counters).

    " the Fiori application parks pending counters in the draft table
    SELECT FROM ztda_variants_d
      FIELDS progname, parameterid, MAX( counter ) AS counter
      WHERE progname    IN @programs
        AND parameterid IN @parameters
      GROUP BY progname, parameterid
      INTO TABLE @DATA(draft_counters).

    LOOP AT active_counters INTO DATA(active_counter).
      merge_counter( EXPORTING counter  = CORRESPONDING #( active_counter )
                     CHANGING  counters = result ).
    ENDLOOP.

    LOOP AT draft_counters INTO DATA(draft_counter).
      merge_counter( EXPORTING counter  = CORRESPONDING #( draft_counter )
                     CHANGING  counters = result ).
    ENDLOOP.

  ENDMETHOD.


  METHOD merge_counter.

    ASSIGN counters[ progname    = counter-progname
                     parameterid = counter-parameterid ] TO FIELD-SYMBOL(<known>).

    IF sy-subrc <> 0.
      INSERT counter INTO TABLE counters.
      RETURN.
    ENDIF.

    <known>-counter = nmax( val1 = <known>-counter val2 = counter-counter ).

  ENDMETHOD.


  METHOD setdefaults.

    READ ENTITIES OF zr_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( isactive sign opt ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    DATA defaults TYPE TABLE FOR UPDATE zr_da_variants\\variants.

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

    MODIFY ENTITIES OF zr_da_variants IN LOCAL MODE
      ENTITY variants
      UPDATE FIELDS ( isactive sign opt )
      WITH defaults
      REPORTED DATA(update_reported).

    reported = CORRESPONDING #( DEEP update_reported ).

  ENDMETHOD.


  METHOD checkdataelements.

    READ ENTITIES OF zr_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( dataelement mappingdataelement mappingvalue )
      WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      " reset the messages of the previous run for this instance
      INSERT VALUE #( %tky        = variant-%tky
                      %state_area = state_area_elements ) INTO TABLE reported-variants.

      DATA(checks) = VALUE ty_element_checks(
          ( element = variant-dataelement        is_map = abap_false )
          ( element = variant-mappingdataelement is_map = abap_true ) ).

      LOOP AT checks INTO DATA(check) WHERE element IS NOT INITIAL.

        IF zcl_da_variants=>data_element_exists( check-element ) = abap_true.
          CONTINUE.
        ENDIF.

        INSERT VALUE #( %tky = variant-%tky ) INTO TABLE failed-variants.

        INSERT VALUE #( %tky        = variant-%tky
                        %state_area = state_area_elements
                        %element-dataelement        = COND #( WHEN check-is_map = abap_false
                                                              THEN if_abap_behv=>mk-on )
                        %element-mappingdataelement = COND #( WHEN check-is_map = abap_true
                                                              THEN if_abap_behv=>mk-on )
                        %msg        = new_message_with_text(
                                          severity = if_abap_behv_message=>severity-error
                                          text     = |{ TEXT-003 } { check-element }| )
                      ) INTO TABLE reported-variants.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD checkrangeconsistency.

    READ ENTITIES OF zr_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( sign opt value highvalue ) WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      INSERT VALUE #( %tky        = variant-%tky
                      %state_area = state_area_range ) INTO TABLE reported-variants.

      DATA(needs_high_value) = xsdbool( variant-opt = option_between
                                     OR variant-opt = option_not_between ).

      IF needs_high_value = abap_true AND variant-highvalue IS INITIAL.
        INSERT VALUE #( %tky = variant-%tky ) INTO TABLE failed-variants.
        INSERT VALUE #( %tky               = variant-%tky
                        %state_area        = state_area_range
                        %element-highvalue = if_abap_behv=>mk-on
                        %msg               = new_message_with_text(
                                                 severity = if_abap_behv_message=>severity-error
                                                 text     = |{ TEXT-001 } { variant-opt }| )
                      ) INTO TABLE reported-variants.
        CONTINUE.
      ENDIF.

      IF needs_high_value = abap_false AND variant-highvalue IS NOT INITIAL.
        INSERT VALUE #( %tky = variant-%tky ) INTO TABLE failed-variants.
        INSERT VALUE #( %tky               = variant-%tky
                        %state_area        = state_area_range
                        %element-highvalue = if_abap_behv=>mk-on
                        %msg               = new_message_with_text(
                                                 severity = if_abap_behv_message=>severity-error
                                                 text     = |{ TEXT-002 } { variant-opt }| )
                      ) INTO TABLE reported-variants.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD checkvaluetypes.

    READ ENTITIES OF zr_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( value highvalue dataelement mappingvalue mappingdataelement )
      WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    LOOP AT variants INTO DATA(variant).

      " reset the messages of the previous run for this instance
      INSERT VALUE #( %tky        = variant-%tky
                      %state_area = state_area_values ) INTO TABLE reported-variants.

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

        " an unknown element is checkDataElements' finding, reporting it twice helps nobody
        IF zcl_da_variants=>data_element_exists( check-element ) = abap_false.
          CONTINUE.
        ENDIF.

        TRY.
            " one implementation for both doors into the configuration table
            zcl_da_variants=>check_value( value        = check-value
                                          data_element = check-element ).

          CATCH zcx_da_variants INTO DATA(type_error).

            INSERT VALUE #( %tky = variant-%tky ) INTO TABLE failed-variants.

            INSERT VALUE #( %tky        = variant-%tky
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
                          ) INTO TABLE reported-variants.
        ENDTRY.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
