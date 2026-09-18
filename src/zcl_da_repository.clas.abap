"! <p class="shorttext synchronized" lang="EN">Repository on the configuration table</p>
"! Production implementation of {@link ZIF_DA_REPOSITORY} on {@link ZTDA_VARIANTS},
"! or on an injected table of the same structure.
"! <p>Reading and writing a table whose name arrives at runtime is dynamic SQL by
"! definition; the name is therefore validated once in the constructor and never
"! taken from anywhere else.</p>
CLASS zcl_da_repository DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_da_repository.

    "! Name of the table the framework ships with.
    CONSTANTS default_table TYPE zif_da_variants=>ty_tabname VALUE 'ZTDA_VARIANTS' ##NO_TEXT.

    "! Creates the repository on the default table, or on an injected one.
    "! <p>The default table needs no further check. An injected table must be a
    "! database table inside one of the given packages, which the caller has to
    "! name explicitly: nobody but the caller knows where their copy lives.</p>
    "! @parameter table_name      | Configuration table, defaults to <em>ZTDA_VARIANTS</em>
    "! @parameter packages        | Package list the injected table must belong to
    "! @raising   zcx_da_variants | Table unknown, outside the packages, or packages missing
    METHODS constructor
      IMPORTING table_name TYPE zif_da_variants=>ty_tabname OPTIONAL
                packages   TYPE string                      OPTIONAL
      RAISING   zcx_da_variants.

  PRIVATE SECTION.

    TYPES ty_program_range   TYPE RANGE OF ztda_variants-progname.
    TYPES ty_parameter_range TYPE RANGE OF ztda_variants-parameterid.

    CONSTANTS range_include TYPE c LENGTH 1 VALUE 'I'  ##NO_TEXT.
    CONSTANTS range_equal   TYPE c LENGTH 2 VALUE 'EQ' ##NO_TEXT.

    DATA configuration_table TYPE zif_da_variants=>ty_tabname.

    "! Validates an injected table name against the allowed packages.
    "! @parameter table_name      | Table to validate, already in upper case
    "! @parameter packages        | Package list
    "! @raising   zcx_da_variants | Table unknown or outside the packages
    METHODS validate_table
      IMPORTING table_name TYPE zif_da_variants=>ty_tabname
                packages   TYPE string
      RAISING   zcx_da_variants.

    "! Keeps the higher of a stored counter and the one already known for its key.
    "! @parameter counter  | Counter read from one of the tables
    "! @parameter counters | Highest counter per key, updated in place
    METHODS merge_counter
      IMPORTING counter  TYPE zif_da_repository=>ty_last_counter
      CHANGING  counters TYPE zif_da_repository=>ty_last_counters.

    "! Wraps a dynamic SQL error into the framework exception.
    "! @parameter textid    | Message to raise
    "! @parameter sql_error | Cause
    "! @parameter result    | Exception to raise, cause chained
    METHODS wrapped
      IMPORTING textid        LIKE if_t100_message=>t100key
                sql_error     TYPE REF TO cx_root
      RETURNING VALUE(result) TYPE REF TO zcx_da_variants.

ENDCLASS.



CLASS zcl_da_repository IMPLEMENTATION.


  METHOD constructor.

    IF table_name IS INITIAL.
      configuration_table = default_table.
      RETURN.
    ENDIF.

    DATA(requested_table) = CONV zif_da_variants=>ty_tabname( to_upper( table_name ) ).

    IF requested_table <> default_table.
      validate_table( table_name = requested_table
                      packages   = packages ).
    ENDIF.

    configuration_table = requested_table.

  ENDMETHOD.


  METHOD validate_table.

    IF packages IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>packages_missing ).
    ENDIF.

    TRY.
        cl_abap_dyn_prg=>check_table_name_str( val      = CONV string( table_name )
                                               packages = packages ).

      CATCH cx_abap_not_a_table cx_abap_not_in_package INTO DATA(table_error).
        RAISE EXCEPTION NEW zcx_da_variants( textid   = zcx_da_variants=>table_not_allowed
                                             msgv1    = table_name
                                             previous = table_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_da_repository~read_active_variants.

    TRY.
        SELECT FROM (configuration_table)
          FIELDS progname, parameterid, counter, is_active, sign, opt,
                 value, high_value, data_element, mapping_value, mapping_data_el,
                 description
          WHERE progname    = @program_name
            AND parameterid = @parameter_id
            AND is_active   = @abap_true
          ORDER BY counter
          INTO CORRESPONDING FIELDS OF TABLE @result.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION wrapped( textid    = zcx_da_variants=>database_error
                                 sql_error = sql_error ).
    ENDTRY.

  ENDMETHOD.

  METHOD zif_da_repository~read_last_counters.

    DATA active_counters TYPE zif_da_repository=>ty_counter_keys.
    DATA draft_counters  TYPE zif_da_repository=>ty_counter_keys.

    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    DATA(programs)   = VALUE ty_program_range( FOR GROUPS program OF key IN keys
                                               GROUP BY key-progname
                                               ( sign = range_include option = range_equal low = program ) ).

    DATA(parameters) = VALUE ty_parameter_range( FOR GROUPS parameter OF key IN keys
                                                 GROUP BY key-parameterid
                                                 ( sign = range_include option = range_equal low = parameter ) ).

    TRY.
        " a dynamic FROM rules out inline declarations, hence the typed tables above
        SELECT FROM (configuration_table)
          FIELDS progname, parameterid, MAX( counter ) AS counter
          WHERE progname    IN @programs
            AND parameterid IN @parameters
          GROUP BY progname, parameterid
          INTO TABLE @active_counters.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION wrapped( textid    = zcx_da_variants=>database_error
                                 sql_error = sql_error ).
    ENDTRY.

    LOOP AT active_counters INTO DATA(active_counter).
      merge_counter( EXPORTING counter  = active_counter
                     CHANGING  counters = result ).
    ENDLOOP.

    " only the shipped table has a Fiori application parking counters in drafts
    IF configuration_table <> default_table.
      RETURN.
    ENDIF.

    SELECT FROM ztda_variants_d
      FIELDS progname, parameterid, MAX( counter ) AS counter
      WHERE progname    IN @programs
        AND parameterid IN @parameters
      GROUP BY progname, parameterid
      INTO TABLE @draft_counters.

    LOOP AT draft_counters INTO DATA(draft_counter).
      merge_counter( EXPORTING counter  = draft_counter
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


  METHOD zif_da_repository~read_creation_info.

    TRY.
        SELECT SINGLE
          FROM (configuration_table)
          FIELDS created_by, created_at
          WHERE progname    = @row-progname
            AND parameterid = @row-parameterid
            AND counter     = @row-counter
          INTO @result.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION wrapped( textid    = zcx_da_variants=>database_error
                                 sql_error = sql_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD zif_da_repository~insert_row.

    TRY.
        INSERT (configuration_table) FROM @row.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION wrapped( textid    = zcx_da_variants=>write_error
                                 sql_error = sql_error ).
    ENDTRY.

    " a key that is already taken is not an error, the caller allocates the next one
    result = xsdbool( sy-subrc = 0 ).

  ENDMETHOD.


  METHOD zif_da_repository~replace_row.

    TRY.
        MODIFY (configuration_table) FROM @row.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION wrapped( textid    = zcx_da_variants=>write_error
                                 sql_error = sql_error ).
    ENDTRY.

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>write_failed
                                           msgv1  = row-parameterid ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_da_repository~delete_rows.

    TRY.
        IF counter IS INITIAL.
          DELETE FROM (configuration_table)
            WHERE progname    = @program_name
              AND parameterid = @parameter_id.
        ELSE.
          DELETE FROM (configuration_table)
            WHERE progname    = @program_name
              AND parameterid = @parameter_id
              AND counter     = @counter.
        ENDIF.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION wrapped( textid    = zcx_da_variants=>write_error
                                 sql_error = sql_error ).
    ENDTRY.

    " removing what is not there is not an error, a cleanup script may run twice
    result = sy-dbcnt.

  ENDMETHOD.


  METHOD wrapped.

    result = NEW zcx_da_variants( textid   = textid
                                  msgv1    = sql_error->get_text( )
                                  previous = sql_error ).

  ENDMETHOD.


ENDCLASS.
