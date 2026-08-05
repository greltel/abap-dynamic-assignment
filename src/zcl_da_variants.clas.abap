CLASS zcl_da_variants DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_da_variants.

    ALIASES ty_base_sign   FOR zif_da_variants~ty_base_sign.
    ALIASES ty_base_opt    FOR zif_da_variants~ty_base_opt.
    ALIASES ty_sign        FOR zif_da_variants~ty_sign.
    ALIASES ty_opt         FOR zif_da_variants~ty_opt.
    ALIASES ty_progname    FOR zif_da_variants~ty_progname.
    ALIASES ty_parameterid FOR zif_da_variants~ty_parameterid.
    ALIASES ty_counter     FOR zif_da_variants~ty_counter.
    ALIASES ty_value       FOR zif_da_variants~ty_value.
    ALIASES ty_data_el     FOR zif_da_variants~ty_data_el.
    ALIASES ty_description FOR zif_da_variants~ty_description.
    ALIASES ty_tabname     FOR zif_da_variants~ty_tabname.
    ALIASES ty_variant     FOR zif_da_variants~ty_variant.
    ALIASES ty_variants    FOR zif_da_variants~ty_variants.

    ALIASES sign_empty   FOR zif_da_variants~sign_empty.
    ALIASES sign_include FOR zif_da_variants~sign_include.
    ALIASES sign_exclude FOR zif_da_variants~sign_exclude.

    ALIASES opt_empty FOR zif_da_variants~opt_empty.
    ALIASES opt_eq    FOR zif_da_variants~opt_eq.
    ALIASES opt_ne    FOR zif_da_variants~opt_ne.
    ALIASES opt_bt    FOR zif_da_variants~opt_bt.
    ALIASES opt_nb    FOR zif_da_variants~opt_nb.
    ALIASES opt_cp    FOR zif_da_variants~opt_cp.
    ALIASES opt_np    FOR zif_da_variants~opt_np.
    ALIASES opt_lt    FOR zif_da_variants~opt_lt.
    ALIASES opt_le    FOR zif_da_variants~opt_le.
    ALIASES opt_gt    FOR zif_da_variants~opt_gt.
    ALIASES opt_ge    FOR zif_da_variants~opt_ge.

    ALIASES get_variant FOR zif_da_variants~get_variant.
    ALIASES set_variant FOR zif_da_variants~set_variant.

    "! Creates the framework on the default configuration table, or on an injected one.
    "! <p>An injected table must be structurally identical to {@link ZDA_VARIANTS}
    "! and must reside in one of the allowed packages.</p>
    "!
    "! @parameter table_name      | Configuration table, defaults to <em>ZDA_VARIANTS</em>
    "! @parameter packages        | Package list the table must belong to
    "! @raising   zcx_da_variants | Table is unknown or outside the allowed packages
    METHODS constructor
      IMPORTING table_name TYPE ty_tabname OPTIONAL
                packages   TYPE string     OPTIONAL
      RAISING   zcx_da_variants.

  PRIVATE SECTION.

    TYPES ty_user          TYPE zda_variants-created_by.
    TYPES ty_data_elements TYPE STANDARD TABLE OF ty_data_el WITH EMPTY KEY.

    CONSTANTS default_table    TYPE ty_tabname  VALUE 'ZDA_VARIANTS'         ##NO_TEXT.
    CONSTANTS default_packages TYPE string      VALUE 'ZDA_DYNAMIC_ASSIGNMENT' ##NO_TEXT.
    CONSTANTS default_program  TYPE ty_progname VALUE 'GLOBAL'               ##NO_TEXT.
    CONSTANTS fallback_user    TYPE ty_user     VALUE 'UNKNOWN'              ##NO_TEXT.

    CONSTANTS component_sign   TYPE string VALUE `SIGN`          ##NO_TEXT.
    CONSTANTS component_option TYPE string VALUE `OPTION`        ##NO_TEXT.
    CONSTANTS component_low    TYPE string VALUE `LOW`           ##NO_TEXT.
    CONSTANTS component_high   TYPE string VALUE `HIGH`          ##NO_TEXT.
    CONSTANTS column_value     TYPE string VALUE `VALUE`         ##NO_TEXT.
    CONSTANTS column_mapping   TYPE string VALUE `MAPPING_VALUE` ##NO_TEXT.

    DATA configuration_table TYPE ty_tabname.

    "! Reads all active variants of one parameter, ordered by counter.
    "! @parameter parameter_id    | Parameter to read
    "! @parameter program_name    | Program scope
    "! @parameter result          | Active variants, never empty
    "! @raising   zcx_da_variants | No active variant exists, or the types are inconsistent
    METHODS read_variants
      IMPORTING parameter_id  TYPE ty_parameterid
                program_name  TYPE ty_progname
      RETURNING VALUE(result) TYPE ty_variants
      RAISING   zcx_da_variants.

    "! Rejects a parameter whose rows do not all share one data element.
    "! @parameter variants        | Rows of one parameter
    "! @raising   zcx_da_variants | More than one data element found
    METHODS check_type_consistency
      IMPORTING variants TYPE ty_variants
      RAISING   zcx_da_variants.

    "! Resolves the DDIC type of a variant column.
    "! @parameter data_element    | Configured data element, may be initial
    "! @parameter sample_value    | Fallback value used when no data element is configured
    "! @parameter result          | Element description of the resolved type
    "! @raising   zcx_da_variants | The configured data element does not exist
    METHODS resolve_element_type
      IMPORTING data_element  TYPE ty_data_el
                sample_value  TYPE ty_value
      RETURNING VALUE(result) TYPE REF TO cl_abap_elemdescr
      RAISING   zcx_da_variants.

    "! Appends one range line per variant to the caller's own range table.
    "! @parameter variants | Active variants, ordered by counter
    "! @parameter range    | Caller's range table, appended in place
    METHODS fill_range
      IMPORTING variants TYPE ty_variants
      CHANGING  range    TYPE STANDARD TABLE.

    "! Appends one value per variant to the caller's own value table.
    "! @parameter variants | Active variants, ordered by counter
    "! @parameter values   | Caller's value table, appended in place
    METHODS fill_values
      IMPORTING variants TYPE ty_variants
      CHANGING  values   TYPE STANDARD TABLE.

    "! Builds a dynamically typed table of value and mapping pairs.
    "! @parameter variants        | Active variants, ordered by counter
    "! @parameter result          | Reference to the generated table
    "! @raising   zcx_da_variants | Type creation or value conversion failed
    METHODS build_mapping_table
      IMPORTING variants      TYPE ty_variants
      RETURNING VALUE(result) TYPE REF TO data
      RAISING   zcx_da_variants.

    "! Returns the highest counter currently stored for one parameter.
    "! @parameter parameter_id    | Parameter to inspect
    "! @parameter program_name    | Program scope
    "! @parameter result          | Highest counter, initial when nothing is stored
    "! @raising   zcx_da_variants | The configuration table could not be read
    METHODS get_last_counter
      IMPORTING parameter_id  TYPE ty_parameterid
                program_name  TYPE ty_progname
      RETURNING VALUE(result) TYPE ty_counter
      RAISING   zcx_da_variants.

    "! Validates the parts of a variant that the database cannot enforce.
    "! @parameter data_element         | Data element of the value, may be initial
    "! @parameter mapping_data_element | Data element of the mapping value, may be initial
    "! @parameter option               | Comparison operator of the range line
    "! @parameter high_value           | Upper bound of the range line
    "! @raising   zcx_da_variants      | A data element is unknown, or a bound is missing
    METHODS validate_input
      IMPORTING data_element         TYPE ty_data_el
                mapping_data_element TYPE ty_data_el
                option               TYPE ty_opt
                high_value           TYPE ty_value
      RAISING   zcx_da_variants.

    "! Fills the administrative fields and the generated description.
    "! @parameter row             | Variant row, completed in place
    "! @raising   zcx_da_variants | The configuration table could not be read
    METHODS stamp_admin_fields
      CHANGING row TYPE ty_variant
      RAISING  zcx_da_variants.

    "! Returns the technical name of the current user, or a fallback.
    "! @parameter result | User name, <em>UNKNOWN</em> when the context is unavailable
    METHODS current_user
      RETURNING VALUE(result) TYPE ty_user.

    "! Builds the description used when the caller does not supply one.
    "! @parameter user_name | Author of the row
    "! @parameter result    | Generated description
    METHODS default_description
      IMPORTING user_name     TYPE ty_user
      RETURNING VALUE(result) TYPE ty_description.

    "! Writes one completed variant row to the configuration table.
    "! @parameter row             | Variant row to store
    "! @raising   zcx_da_variants | The database rejected the row
    METHODS persist_row
      IMPORTING row TYPE ty_variant
      RAISING   zcx_da_variants.

    "! Checks whether a name refers to an existing elementary DDIC type.
    "! @parameter data_element | Name to check
    "! @parameter result       | <em>abap_true</em> when the data element exists
    METHODS data_element_exists
      IMPORTING data_element  TYPE ty_data_el
      RETURNING VALUE(result) TYPE abap_boolean.

ENDCLASS.



CLASS zcl_da_variants IMPLEMENTATION.


  METHOD constructor.

    DATA(requested_table) = CONV ty_tabname( to_upper(
                                COND #( WHEN table_name IS NOT INITIAL
                                        THEN table_name
                                        ELSE default_table ) ) ).

    DATA(allowed_packages) = COND string( WHEN packages IS NOT INITIAL
                                          THEN packages
                                          ELSE default_packages ).

    TRY.
        cl_abap_dyn_prg=>check_table_name_str( val      = CONV string( requested_table )
                                               packages = allowed_packages ).

      CATCH cx_abap_not_a_table cx_abap_not_in_package INTO DATA(table_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-011 } { requested_table }|
                                             previous = table_error ).
    ENDTRY.

    me->configuration_table = requested_table.

  ENDMETHOD.


  METHOD zif_da_variants~get_variant.

    CLEAR: field_value, mapping_field_value, values, mapping_values, range.

    DATA(parameter) = CONV ty_parameterid( to_upper( parameter_id ) ).
    DATA(program)   = CONV ty_progname( to_upper(
                          COND #( WHEN program_name IS NOT INITIAL
                                  THEN program_name
                                  ELSE default_program ) ) ).

    DATA(variants)      = read_variants( parameter_id = parameter
                                         program_name = program ).
    DATA(first_variant) = VALUE ty_variant( variants[ 1 ] OPTIONAL ).

    TRY.
        IF field_value IS REQUESTED.
          field_value = first_variant-value.
        ENDIF.

        IF mapping_field_value IS REQUESTED.
          mapping_field_value = first_variant-mapping_value.
        ENDIF.

      CATCH cx_sy_conversion_error INTO DATA(conversion_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-001 } { conversion_error->get_text( ) }|
                                             previous = conversion_error ).
    ENDTRY.

    IF range IS REQUESTED.
      fill_range( EXPORTING variants = variants
                  CHANGING  range    = range ).
    ENDIF.

    IF values IS REQUESTED.
      fill_values( EXPORTING variants = variants
                   CHANGING  values   = values ).
    ENDIF.

    IF mapping_values IS REQUESTED.
      mapping_values = build_mapping_table( variants ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_da_variants~set_variant.

    DATA(parameter) = CONV ty_parameterid( to_upper( parameter_id ) ).
    DATA(program)   = CONV ty_progname( to_upper(
                          COND #( WHEN program_name IS NOT INITIAL
                                  THEN program_name
                                  ELSE default_program ) ) ).

    DATA(element)         = CONV ty_data_el( to_upper( data_element ) ).
    DATA(mapping_element) = CONV ty_data_el( to_upper( mapping_data_element ) ).

    DATA(variant_sign)   = COND ty_sign( WHEN sign   IS NOT INITIAL THEN sign   ELSE sign_include ).
    DATA(variant_option) = COND ty_opt(  WHEN option IS NOT INITIAL THEN option ELSE opt_eq ).

    validate_input( data_element         = element
                    mapping_data_element = mapping_element
                    option               = variant_option
                    high_value           = high_value ).

    DATA(row) = VALUE ty_variant(
        progname        = program
        parameterid     = parameter
        counter         = COND #( WHEN counter IS NOT INITIAL
                                  THEN counter
                                  ELSE get_last_counter( parameter_id = parameter
                                                         program_name = program ) + 1 )
        is_active       = is_active
        sign            = CONV ty_base_sign( variant_sign )
        opt             = CONV ty_base_opt( variant_option )
        value           = field_value
        high_value      = high_value
        data_element    = element
        mapping_value   = mapping_field_value
        mapping_data_el = mapping_element
        description     = description ).

    stamp_admin_fields( CHANGING row = row ).

    persist_row( row ).

    IF commit = abap_true.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.


  METHOD read_variants.

    TRY.
        SELECT FROM (me->configuration_table)
          FIELDS progname, parameterid, counter, is_active, sign, opt,
                 value, high_value, data_element, mapping_value, mapping_data_el,
                 description
          WHERE progname    = @program_name
            AND parameterid = @parameter_id
            AND is_active   = @abap_true
          ORDER BY counter
          INTO CORRESPONDING FIELDS OF TABLE @result.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-004 } { sql_error->get_text( ) }|
                                             previous = sql_error ).
    ENDTRY.

    IF result IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-003 } { parameter_id }| ).
    ENDIF.

    check_type_consistency( result ).

  ENDMETHOD.


  METHOD check_type_consistency.

    DATA(elements) = VALUE ty_data_elements( FOR GROUPS element OF variant IN variants
                                             GROUP BY variant-data_element
                                             ( element ) ).

    IF lines( elements ) <= 1.
      RETURN.
    ENDIF.

    RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-012 } { variants[ 1 ]-parameterid }: |
                                                && concat_lines_of( table = elements sep = `, ` ) ).

  ENDMETHOD.


  METHOD resolve_element_type.

    IF data_element IS INITIAL.
      result = CAST #( cl_abap_elemdescr=>describe_by_data( sample_value ) ).
      RETURN.
    ENDIF.

    cl_abap_typedescr=>describe_by_name( EXPORTING  p_name         = data_element
                                         RECEIVING  p_descr_ref    = DATA(type)
                                         EXCEPTIONS type_not_found = 1
                                                    OTHERS         = 2 ).
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-005 } { data_element }| ).
    ENDIF.

    TRY.
        result = CAST #( type ).

      CATCH cx_sy_move_cast_error INTO DATA(cast_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-005 } { data_element }|
                                             previous = cast_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD fill_range.

    LOOP AT variants INTO DATA(variant).

      APPEND INITIAL LINE TO range ASSIGNING FIELD-SYMBOL(<range_line>).

      ASSIGN COMPONENT component_sign OF STRUCTURE <range_line> TO FIELD-SYMBOL(<sign>).
      IF sy-subrc = 0.
        <sign> = variant-sign.
      ENDIF.

      ASSIGN COMPONENT component_option OF STRUCTURE <range_line> TO FIELD-SYMBOL(<option>).
      IF sy-subrc = 0.
        <option> = variant-opt.
      ENDIF.

      ASSIGN COMPONENT component_low OF STRUCTURE <range_line> TO FIELD-SYMBOL(<low>).
      IF sy-subrc = 0.
        <low> = variant-value.
      ENDIF.

      ASSIGN COMPONENT component_high OF STRUCTURE <range_line> TO FIELD-SYMBOL(<high>).
      IF sy-subrc = 0 AND variant-high_value IS NOT INITIAL.
        <high> = variant-high_value.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD fill_values.

    LOOP AT variants INTO DATA(variant).
      APPEND INITIAL LINE TO values ASSIGNING FIELD-SYMBOL(<value_line>).
      <value_line> = variant-value.
    ENDLOOP.

  ENDMETHOD.


  METHOD build_mapping_table.

    FIELD-SYMBOLS <mapping_table> TYPE STANDARD TABLE.

    DATA(first_variant) = VALUE ty_variant( variants[ 1 ] OPTIONAL ).

    DATA(value_type)   = resolve_element_type( data_element = first_variant-data_element
                                               sample_value = first_variant-value ).
    DATA(mapping_type) = resolve_element_type( data_element = first_variant-mapping_data_el
                                               sample_value = first_variant-mapping_value ).

    TRY.
        DATA(table_type) = cl_abap_tabledescr=>create(
            p_line_type  = cl_abap_structdescr=>create(
                               VALUE cl_abap_structdescr=>component_table(
                                   ( name = column_value   type = value_type )
                                   ( name = column_mapping type = mapping_type ) ) )
            p_table_kind = cl_abap_tabledescr=>tablekind_std
            p_key_kind   = cl_abap_tabledescr=>keydefkind_default
            p_unique     = abap_false ).

        CREATE DATA result TYPE HANDLE table_type.

      CATCH cx_sy_struct_creation cx_sy_table_creation cx_sy_create_data_error
            INTO DATA(rtts_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-002 } { rtts_error->get_text( ) }|
                                             previous = rtts_error ).
    ENDTRY.

    ASSIGN result->* TO <mapping_table>.

    TRY.
        LOOP AT variants INTO DATA(variant) WHERE mapping_value IS NOT INITIAL.

          APPEND INITIAL LINE TO <mapping_table> ASSIGNING FIELD-SYMBOL(<mapping_line>).

          ASSIGN COMPONENT column_value OF STRUCTURE <mapping_line> TO FIELD-SYMBOL(<value>).
          IF sy-subrc = 0.
            <value> = variant-value.
          ENDIF.

          ASSIGN COMPONENT column_mapping OF STRUCTURE <mapping_line> TO FIELD-SYMBOL(<mapping>).
          IF sy-subrc = 0.
            <mapping> = variant-mapping_value.
          ENDIF.

        ENDLOOP.

      CATCH cx_sy_conversion_error INTO DATA(conversion_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-001 } { conversion_error->get_text( ) }|
                                             previous = conversion_error ).
    ENDTRY.

  ENDMETHOD.

  METHOD get_last_counter.

    TRY.
        SELECT FROM (me->configuration_table)
          FIELDS MAX( counter ) AS counter
          WHERE progname    = @program_name
            AND parameterid = @parameter_id
          INTO @result.

        IF me->configuration_table = default_table.
          " the Fiori application parks pending counters in the draft table
          SELECT FROM zda_variants_d
            FIELDS MAX( counter ) AS counter
            WHERE progname    = @program_name
              AND parameterid = @parameter_id
            INTO @DATA(draft_counter).

          result = nmax( val1 = result val2 = draft_counter ).
        ENDIF.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-004 } { sql_error->get_text( ) }|
                                             previous = sql_error ).
    ENDTRY.

  ENDMETHOD.

  METHOD validate_input.

    IF data_element IS NOT INITIAL AND data_element_exists( data_element ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-005 } { data_element }| ).
    ENDIF.

    IF mapping_data_element IS NOT INITIAL
       AND data_element_exists( mapping_data_element ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-006 } { mapping_data_element }| ).
    ENDIF.

    IF ( option = opt_bt OR option = opt_nb ) AND high_value IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-013 } { CONV ty_base_opt( option ) }| ).
    ENDIF.

  ENDMETHOD.


  METHOD stamp_admin_fields.
    DATA change_time TYPE zda_variants-created_at.

    DATA(user_name) = current_user( ).

    GET TIME STAMP FIELD change_time.

    TRY.
        " replacing a row must not rewrite its original creator
        TYPES: BEGIN OF ty_creation_info,
                 created_by TYPE zda_variants-created_by,
                 created_at TYPE zda_variants-created_at,
               END OF ty_creation_info.

        DATA stored_row TYPE ty_creation_info.

        SELECT SINGLE
          FROM (me->configuration_table)
          FIELDS created_by, created_at
          WHERE progname    = @row-progname
            AND parameterid = @row-parameterid
            AND counter     = @row-counter
          INTO @stored_row.

      CATCH cx_sy_dynamic_osql_semantics
            cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-004 } { sql_error->get_text( ) }|
                                             previous = sql_error ).
    ENDTRY.

    DATA(row_exists) = xsdbool( sy-subrc = 0 ).

    row-created_by            = COND #( WHEN row_exists = abap_true
                                        THEN stored_row-created_by
                                        ELSE user_name ).
    row-created_at            = COND #( WHEN row_exists = abap_true
                                        THEN stored_row-created_at
                                        ELSE change_time ).
    row-last_changed_by       = user_name.
    row-last_changed_at       = change_time.
    row-local_last_changed_at = change_time.

    IF row-description IS INITIAL.
      row-description = default_description( user_name ).
    ENDIF.
  ENDMETHOD.


  METHOD current_user.

    TRY.
        result = cl_abap_context_info=>get_user_technical_name( ).

      CATCH cx_abap_context_info_error.
        result = fallback_user.
    ENDTRY.

  ENDMETHOD.


  METHOD default_description.

    TRY.
        DATA(current_date) = cl_abap_context_info=>get_system_date( ).
        DATA(current_time) = cl_abap_context_info=>get_system_time( ).

        result = |{ TEXT-007 } { current_date DATE = ISO } { current_time TIME = ISO } |
              && |{ TEXT-008 } { user_name }|.

      CATCH cx_abap_context_info_error.
        result = |{ TEXT-008 } { user_name }|.
    ENDTRY.

  ENDMETHOD.


  METHOD persist_row.

    TRY.
        MODIFY (me->configuration_table) FROM @row.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(write_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-010 } { write_error->get_text( ) }|
                                             previous = write_error ).
    ENDTRY.

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-009 } { row-parameterid }| ).
    ENDIF.

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
