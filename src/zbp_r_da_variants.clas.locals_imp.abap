"! Composition root of the behavior pool. The framework instantiates the
"! handler without arguments, so the handler asks this factory for its
"! collaborators; a test swaps them through the inject_* hooks.
CLASS lcl_variants_factory DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.

    "! Authorization check the handlers consult.
    "! @parameter result | Injected double, or the production check on ZDA_VAR
    CLASS-METHODS authorization
      RETURNING VALUE(result) TYPE REF TO zif_da_authorization.

    "! Persistence the numbering handler reads the counters from.
    "! @parameter result | Injected double, or the production repository on ZTDA_VARIANTS
    CLASS-METHODS repository
      RETURNING VALUE(result) TYPE REF TO zif_da_repository.

    "! Type checks the validations run.
    "! @parameter result | Injected double, or the production RTTS based check
    CLASS-METHODS value_check
      RETURNING VALUE(result) TYPE REF TO zif_da_value_check.

    "! Test hook. Pass an unbound reference to restore the production default.
    "! @parameter authorization | Double to serve from now on
    CLASS-METHODS inject_authorization
      IMPORTING authorization TYPE REF TO zif_da_authorization.

    "! Test hook. Pass an unbound reference to restore the production default.
    "! @parameter repository | Double to serve from now on
    CLASS-METHODS inject_repository
      IMPORTING repository TYPE REF TO zif_da_repository.

    "! Test hook. Pass an unbound reference to restore the production default.
    "! @parameter value_check | Double to serve from now on
    CLASS-METHODS inject_value_check
      IMPORTING value_check TYPE REF TO zif_da_value_check.

  PRIVATE SECTION.

    CLASS-DATA authorization_override TYPE REF TO zif_da_authorization.
    CLASS-DATA repository_override    TYPE REF TO zif_da_repository.
    CLASS-DATA value_check_override   TYPE REF TO zif_da_value_check.

ENDCLASS.


CLASS lcl_variants_factory IMPLEMENTATION.

  METHOD authorization.
    result = COND #( WHEN authorization_override IS BOUND
                     THEN authorization_override
                     ELSE NEW zcl_da_authorization( ) ).
  ENDMETHOD.

  METHOD repository.
    IF repository_override IS BOUND.
      result = repository_override.
      RETURN.
    ENDIF.

    TRY.
        result = NEW zcl_da_repository( ).

      CATCH zcx_da_variants.
        " the default table needs no validation, the constructor cannot raise for it
        ASSERT 1 = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD value_check.
    result = COND #( WHEN value_check_override IS BOUND
                     THEN value_check_override
                     ELSE NEW zcl_da_value_check( ) ).
  ENDMETHOD.

  METHOD inject_authorization.
    authorization_override = authorization.
  ENDMETHOD.

  METHOD inject_repository.
    repository_override = repository.
  ENDMETHOD.

  METHOD inject_value_check.
    value_check_override = value_check.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_variants DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

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

    DATA(repository) = lcl_variants_factory=>repository( ).

    TRY.
        DATA(last_counters) = repository->read_last_counters( CORRESPONDING #( entities ) ).

      CATCH zcx_da_variants INTO DATA(read_error).
        " without the stored counters nothing can be numbered, every entity fails
        LOOP AT entities INTO DATA(unnumbered).
          INSERT VALUE #( %cid      = unnumbered-%cid
                          %is_draft = unnumbered-%is_draft ) INTO TABLE failed-variants.
          INSERT VALUE #( %cid      = unnumbered-%cid
                          %is_draft = unnumbered-%is_draft
                          %msg      = read_error ) INTO TABLE reported-variants.
        ENDLOOP.
        RETURN.
    ENDTRY.

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
                        %msg      = NEW zcx_da_variants( textid = zcx_da_variants=>counter_exhausted
                                                         msgv1  = entity-parameterid )
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

    DATA(value_check) = lcl_variants_factory=>value_check( ).

    LOOP AT variants INTO DATA(variant).

      " reset the messages of the previous run for this instance
      INSERT VALUE #( %tky        = variant-%tky
                      %state_area = state_area_elements ) INTO TABLE reported-variants.

      DATA(checks) = VALUE ty_element_checks(
          ( element = variant-dataelement        is_map = abap_false )
          ( element = variant-mappingdataelement is_map = abap_true ) ).

      LOOP AT checks INTO DATA(check) WHERE element IS NOT INITIAL.

        IF value_check->data_element_exists( check-element ) = abap_true.
          CONTINUE.
        ENDIF.

        INSERT VALUE #( %tky = variant-%tky ) INTO TABLE failed-variants.

        INSERT VALUE #( %tky        = variant-%tky
                        %state_area = state_area_elements
                        %element-dataelement        = COND #( WHEN check-is_map = abap_false
                                                              THEN if_abap_behv=>mk-on )
                        %element-mappingdataelement = COND #( WHEN check-is_map = abap_true
                                                              THEN if_abap_behv=>mk-on )
                        %msg        = NEW zcx_da_variants(
                                          textid = COND #( WHEN check-is_map = abap_true
                                                           THEN zcx_da_variants=>invalid_mapping_element
                                                           ELSE zcx_da_variants=>invalid_data_element )
                                          msgv1  = check-element )
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
                        %msg               = NEW zcx_da_variants( textid = zcx_da_variants=>high_value_missing
                                                                      msgv1  = variant-opt )
                      ) INTO TABLE reported-variants.
        CONTINUE.
      ENDIF.

      IF needs_high_value = abap_false AND variant-highvalue IS NOT INITIAL.
        INSERT VALUE #( %tky = variant-%tky ) INTO TABLE failed-variants.
        INSERT VALUE #( %tky               = variant-%tky
                        %state_area        = state_area_range
                        %element-highvalue = if_abap_behv=>mk-on
                        %msg               = NEW zcx_da_variants( textid = zcx_da_variants=>high_value_not_allowed
                                                                      msgv1  = variant-opt )
                      ) INTO TABLE reported-variants.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD checkvaluetypes.

    READ ENTITIES OF zr_da_variants IN LOCAL MODE
      ENTITY variants FIELDS ( value highvalue dataelement mappingvalue mappingdataelement )
      WITH CORRESPONDING #( keys )
      RESULT DATA(variants).

    DATA(value_check) = lcl_variants_factory=>value_check( ).

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
        IF value_check->data_element_exists( check-element ) = abap_false.
          CONTINUE.
        ENDIF.

        TRY.
            " one implementation for both doors into the configuration table
            value_check->check_value( value        = check-value
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
                            %msg        = type_error
                          ) INTO TABLE reported-variants.
        ENDTRY.

      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
