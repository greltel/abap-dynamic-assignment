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

    "! Checks whether a name refers to an existing elementary DDIC type.
    "! @parameter data_element | Name to check
    "! @parameter result       | <em>abap_true</em> when an elementary data element exists
    CLASS-METHODS data_element_exists
      IMPORTING data_element  TYPE ty_data_el
      RETURNING VALUE(result) TYPE abap_boolean.

    "! Rejects a value that its configured data element could not hold unchanged.
    "! <p>Three losses happen without any runtime error and are caught here instead:
    "! <em>NUMC</em> keeps the digits of the source and drops the rest, <em>CHAR</em>
    "! truncates on the right, and a date field is character like, so a day that does
    "! not exist in the calendar is copied straight in.</p>
    "! <p>Leading zeros added by <em>NUMC</em> are not a loss and stay accepted.</p>
    "!
    "! @parameter value           | Value as it is stored in the configuration table
    "! @parameter data_element    | Configured type, initial for the native column type
    "! @raising   zcx_da_variants | The value would be truncated, filtered or is no date
    CLASS-METHODS check_value
      IMPORTING value        TYPE ty_value
                data_element TYPE ty_data_el
      RAISING   zcx_da_variants.

  PRIVATE SECTION.

    TYPES ty_user          TYPE zda_variants-created_by.
    TYPES ty_data_elements TYPE STANDARD TABLE OF ty_data_el WITH EMPTY KEY.

    TYPES: "! Creation stamp of a row that is already stored.
      BEGIN OF ty_creation_info,
        created_by TYPE zda_variants-created_by,
        created_at TYPE zda_variants-created_at,
      END OF ty_creation_info.

    CONSTANTS default_table    TYPE ty_tabname  VALUE 'ZDA_VARIANTS'         ##NO_TEXT.
    CONSTANTS default_packages TYPE string      VALUE 'ZDA_DYNAMIC_ASSIGNMENT' ##NO_TEXT.
    CONSTANTS default_program  TYPE ty_progname VALUE 'GLOBAL'               ##NO_TEXT.
    CONSTANTS fallback_user    TYPE ty_user     VALUE 'UNKNOWN'              ##NO_TEXT.

    "! Highest counter the NUMC(5) key can hold.
    CONSTANTS max_counter  TYPE i VALUE 99999.
    "! Times an append retries after another LUW took the allocated counter.
    CONSTANTS max_attempts TYPE i VALUE 5.

    TYPES ty_month_lengths TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    CONSTANTS digits      TYPE string VALUE `0123456789` ##NO_TEXT.
    CONSTANTS date_length TYPE i VALUE 8.
    CONSTANTS time_length TYPE i VALUE 6.
    CONSTANTS february    TYPE i VALUE 2.
    CONSTANTS leap_day    TYPE i VALUE 29.
    CONSTANTS max_year    TYPE i VALUE 9999.
    CONSTANTS max_month   TYPE i VALUE 12.
    CONSTANTS max_hour    TYPE i VALUE 23.
    CONSTANTS max_minute  TYPE i VALUE 59.
    CONSTANTS max_second  TYPE i VALUE 59.

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

    "! Rejects a parameter whose rows do not share one value and one mapping type.
    "! @parameter variants        | Rows of one parameter
    "! @raising   zcx_da_variants | More than one data element found on either column
    METHODS check_type_consistency
      IMPORTING variants TYPE ty_variants
      RAISING   zcx_da_variants.

    "! Returns the rows that actually carry a mapping value.
    "! @parameter variants | Active variants, ordered by counter
    "! @parameter result   | Rows with a filled mapping value, order preserved
    METHODS mapping_variants
      IMPORTING variants      TYPE ty_variants
      RETURNING VALUE(result) TYPE ty_variants.

    "! Resolves the DDIC type of a variant column.
    "! @parameter data_element    | Configured data element, may be initial
    "! @parameter sample_value    | Fallback value used when no data element is configured
    "! @parameter result          | Element description of the resolved type
    "! @raising   zcx_da_variants | The configured data element does not exist
    CLASS-METHODS resolve_element_type
      IMPORTING data_element  TYPE ty_data_el
                sample_value  TYPE ty_value
      RETURNING VALUE(result) TYPE REF TO cl_abap_elemdescr
      RAISING   zcx_da_variants.

    "! Writes the value into its configured type and reports what the type refuses.
    "! @parameter value           | Value to convert
    "! @parameter data_element    | Configured data element, named in the message
    "! @parameter element         | Resolved type of the data element
    "! @parameter result          | Data reference holding the converted value
    "! @raising   zcx_da_variants | The conversion failed or overflowed
    CLASS-METHODS check_convertible
      IMPORTING value         TYPE ty_value
                data_element  TYPE ty_data_el
                element       TYPE REF TO cl_abap_elemdescr
      RETURNING VALUE(result) TYPE REF TO data
      RAISING   zcx_da_variants.

    "! Rejects a value that a character like type would truncate or filter.
    "! @parameter value           | Value to convert
    "! @parameter data_element    | Configured data element, named in the message
    "! @parameter element         | Resolved type of the data element
    "! @raising   zcx_da_variants | The value does not survive the round trip
    CLASS-METHODS check_round_trip
      IMPORTING value        TYPE ty_value
                data_element TYPE ty_data_el
                element      TYPE REF TO cl_abap_elemdescr
      RAISING   zcx_da_variants.

    "! Rejects a value that is not a day the calendar knows.
    "! @parameter value           | Value to check, expected as YYYYMMDD
    "! @parameter data_element    | Configured data element, named in the message
    "! @raising   zcx_da_variants | The value is no valid date
    CLASS-METHODS check_date
      IMPORTING value        TYPE ty_value
                data_element TYPE ty_data_el
      RAISING   zcx_da_variants.

    "! Rejects a value that is not a time of day.
    "! @parameter value           | Value to check, expected as HHMMSS
    "! @parameter data_element    | Configured data element, named in the message
    "! @raising   zcx_da_variants | The value is no valid time
    CLASS-METHODS check_time
      IMPORTING value        TYPE ty_value
                data_element TYPE ty_data_el
      RAISING   zcx_da_variants.

    "! Strips what a type adds by itself, so that only real losses remain visible.
    "! @parameter value     | Value to normalise
    "! @parameter type_kind | Type kind of the target, drives the leading zero rule
    "! @parameter result    | Comparable form of the value
    CLASS-METHODS normalized
      IMPORTING value         TYPE ty_value
                type_kind     TYPE abap_typekind
      RETURNING VALUE(result) TYPE string.

    "! Returns the last day the given month has in the given year.
    "! @parameter year   | Calendar year, drives the leap year rule
    "! @parameter month  | Calendar month between 1 and 12
    "! @parameter result | Last day of that month
    CLASS-METHODS last_day_of_month
      IMPORTING year          TYPE i
                month         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! Answers whether February has 29 days in the given year.
    "! @parameter year   | Calendar year
    "! @parameter result | <em>abap_true</em> for a leap year
    CLASS-METHODS is_leap_year
      IMPORTING year          TYPE i
      RETURNING VALUE(result) TYPE abap_boolean.

    "! Appends one range line per variant to the caller's own range table.
    "! <p>The caller's table is emptied again when a stored value does not fit the
    "! target type, so that a rejected read never leaves half a range behind.</p>
    "! @parameter variants        | Active variants, ordered by counter
    "! @parameter range           | Caller's range table, appended in place
    "! @raising   zcx_da_variants | A stored value does not fit the caller's range type
    METHODS fill_range
      IMPORTING variants TYPE ty_variants
      CHANGING  range    TYPE STANDARD TABLE
      RAISING   zcx_da_variants.

    "! Appends one value per variant to the caller's own value table.
    "! <p>The caller's table is emptied again when a stored value does not fit the
    "! target type, so that a rejected read never leaves half a result behind.</p>
    "! @parameter variants        | Active variants, ordered by counter
    "! @parameter values          | Caller's value table, appended in place
    "! @raising   zcx_da_variants | A stored value does not fit the caller's line type
    METHODS fill_values
      IMPORTING variants TYPE ty_variants
      CHANGING  values   TYPE STANDARD TABLE
      RAISING   zcx_da_variants.

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

    "! Allocates the counter that follows the highest one currently in use.
    "! @parameter parameter_id    | Parameter to number
    "! @parameter program_name    | Program scope
    "! @parameter result          | Next free counter
    "! @raising   zcx_da_variants | The key range is exhausted, or the table is unreadable
    METHODS next_counter
      IMPORTING parameter_id  TYPE ty_parameterid
                program_name  TYPE ty_progname
      RETURNING VALUE(result) TYPE ty_counter
      RAISING   zcx_da_variants.

    "! Numbers and inserts a new row, retrying when another LUW took the counter.
    "! <p>The append path never replaces a stored row. When the counter allocated
    "! here is taken between the read and the insert, the next one is allocated and
    "! the insert is repeated up to <em>max_attempts</em> times.</p>
    "! @parameter row             | Variant row without a counter, completed in place
    "! @raising   zcx_da_variants | No free counter could be secured
    METHODS append_row
      CHANGING row TYPE ty_variant
      RAISING  zcx_da_variants.

    "! Validates the parts of a variant that the database cannot enforce.
    "! <p>Enforces exactly the rules the Fiori application enforces, so that both
    "! doors into the configuration table accept the same rows.</p>
    "! @parameter parameter_id         | Parameter the row belongs to
    "! @parameter field_value          | Value, or lower bound of a range line
    "! @parameter data_element         | Data element of the value, may be initial
    "! @parameter mapping_field_value  | Value the variant maps to, may be initial
    "! @parameter mapping_data_element | Data element of the mapping value, may be initial
    "! @parameter option               | Comparison operator of the range line
    "! @parameter high_value           | Upper bound of the range line
    "! @raising   zcx_da_variants      | The row would not be accepted by the application
    METHODS validate_input
      IMPORTING parameter_id         TYPE ty_parameterid
                field_value          TYPE ty_value
                data_element         TYPE ty_data_el
                mapping_field_value  TYPE ty_value
                mapping_data_element TYPE ty_data_el
                option               TYPE ty_opt
                high_value           TYPE ty_value
      RAISING   zcx_da_variants.

    "! Rejects a row whose values would not survive their configured types.
    "! @parameter field_value          | Value, or lower bound of a range line
    "! @parameter high_value           | Upper bound, stored in the same type
    "! @parameter data_element         | Data element of both bounds, may be initial
    "! @parameter mapping_field_value  | Value the variant maps to, may be initial
    "! @parameter mapping_data_element | Data element of the mapping value, may be initial
    "! @raising   zcx_da_variants      | A value does not fit its data element
    METHODS validate_values
      IMPORTING field_value          TYPE ty_value
                high_value           TYPE ty_value
                data_element         TYPE ty_data_el
                mapping_field_value  TYPE ty_value
                mapping_data_element TYPE ty_data_el
      RAISING   zcx_da_variants.

    "! Rejects a row that misses a field the behaviour definition declares mandatory.
    "! @parameter parameter_id    | Parameter the row belongs to
    "! @parameter field_value     | Value, or lower bound of a range line
    "! @raising   zcx_da_variants | Parameter or value is initial
    METHODS validate_mandatory
      IMPORTING parameter_id TYPE ty_parameterid
                field_value  TYPE ty_value
      RAISING   zcx_da_variants.

    "! Rejects a row whose configured types cannot be resolved.
    "! @parameter data_element         | Data element of the value, may be initial
    "! @parameter mapping_data_element | Data element of the mapping value, may be initial
    "! @raising   zcx_da_variants      | A data element is unknown or not elementary
    METHODS validate_data_elements
      IMPORTING data_element         TYPE ty_data_el
                mapping_data_element TYPE ty_data_el
      RAISING   zcx_da_variants.

    "! Rejects a range line whose bounds do not match its comparison operator.
    "! @parameter option          | Comparison operator of the range line
    "! @parameter high_value      | Upper bound of the range line
    "! @raising   zcx_da_variants | A bound is missing, or one is given where none belongs
    METHODS validate_range
      IMPORTING option     TYPE ty_opt
                high_value TYPE ty_value
      RAISING   zcx_da_variants.

    "! Reads the creation stamp of a row that is about to be replaced.
    "! @parameter row             | Variant row carrying the key to look up
    "! @parameter result          | Stored creation stamp, initial when the row is new
    "! @raising   zcx_da_variants | The configuration table could not be read
    METHODS read_creation_info
      IMPORTING row           TYPE ty_variant
      RETURNING VALUE(result) TYPE ty_creation_info
      RAISING   zcx_da_variants.

    "! Fills the administrative fields and the generated description.
    "! @parameter creation_info | Stamp to keep, initial for a row that is created
    "! @parameter row           | Variant row, completed in place
    METHODS stamp_admin_fields
      IMPORTING creation_info TYPE ty_creation_info OPTIONAL
      CHANGING  row           TYPE ty_variant.

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

    "! Replaces one completed variant row in the configuration table.
    "! <p>Only the replace path uses this. Overwriting a stored row is the point
    "! here, which is why the caller has to supply the counter explicitly.</p>
    "! @parameter row             | Variant row to store
    "! @raising   zcx_da_variants | The database rejected the row
    METHODS persist_row
      IMPORTING row TYPE ty_variant
      RAISING   zcx_da_variants.

    "! Inserts one completed variant row without ever replacing a stored one.
    "! @parameter row             | Variant row to insert
    "! @parameter result          | <em>abap_false</em> when the key was already taken
    "! @raising   zcx_da_variants | The configuration table could not be written
    METHODS insert_row
      IMPORTING row           TYPE ty_variant
      RETURNING VALUE(result) TYPE abap_boolean
      RAISING   zcx_da_variants.

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

    validate_input( parameter_id         = parameter
                    field_value          = field_value
                    data_element         = element
                    mapping_field_value  = mapping_field_value
                    mapping_data_element = mapping_element
                    option               = variant_option
                    high_value           = high_value ).

    DATA(row) = VALUE ty_variant(
        progname        = program
        parameterid     = parameter
        counter         = counter
        is_active       = is_active
        sign            = CONV ty_base_sign( variant_sign )
        opt             = CONV ty_base_opt( variant_option )
        value           = field_value
        high_value      = high_value
        data_element    = element
        mapping_value   = mapping_field_value
        mapping_data_el = mapping_element
        description     = description ).

    IF counter IS INITIAL.
      " append - the counter is allocated here and the row is only ever inserted
      append_row( CHANGING row = row ).
    ELSE.
      " replace - the caller owns the key, so overwriting the row is intended
      stamp_admin_fields( EXPORTING creation_info = read_creation_info( row )
                          CHANGING  row           = row ).
      persist_row( row ).
    ENDIF.

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

    IF lines( elements ) > 1.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-012 } { variants[ 1 ]-parameterid }: |
                                                  && concat_lines_of( table = elements sep = `, ` ) ).
    ENDIF.

    " only rows that map something take part, a row without a mapping value has no type
    DATA(mapping_rows) = mapping_variants( variants ).

    DATA(mapping_elements) = VALUE ty_data_elements(
                                 FOR GROUPS mapping_element OF mapping_row IN mapping_rows
                                 GROUP BY mapping_row-mapping_data_el
                                 ( mapping_element ) ).

    IF lines( mapping_elements ) > 1.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-014 } { variants[ 1 ]-parameterid }: |
                                                  && concat_lines_of( table = mapping_elements sep = `, ` ) ).
    ENDIF.

  ENDMETHOD.


  METHOD mapping_variants.

    result = VALUE #( FOR variant IN variants
                      WHERE ( mapping_value IS NOT INITIAL )
                      ( variant ) ).

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

    TRY.
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

      CATCH cx_sy_conversion_error INTO DATA(conversion_error).
        CLEAR range.
        RAISE EXCEPTION NEW zcx_da_variants(
                  text     = |{ TEXT-001 } { conversion_error->get_text( ) } [{ variant-counter }]|
                  previous = conversion_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD fill_values.

    TRY.
        LOOP AT variants INTO DATA(variant).
          APPEND INITIAL LINE TO values ASSIGNING FIELD-SYMBOL(<value_line>).
          <value_line> = variant-value.
        ENDLOOP.

      CATCH cx_sy_conversion_error INTO DATA(conversion_error).
        CLEAR values.
        RAISE EXCEPTION NEW zcx_da_variants(
                  text     = |{ TEXT-001 } { conversion_error->get_text( ) } [{ variant-counter }]|
                  previous = conversion_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD build_mapping_table.

    FIELD-SYMBOLS <mapping_table> TYPE STANDARD TABLE.

    DATA(first_variant) = VALUE ty_variant( variants[ 1 ] OPTIONAL ).

    " the mapping type belongs to the rows that map something, not to the first row
    DATA(mapping_rows)  = mapping_variants( variants ).
    DATA(first_mapping) = VALUE ty_variant( mapping_rows[ 1 ] OPTIONAL ).

    DATA(value_type)   = resolve_element_type( data_element = first_variant-data_element
                                               sample_value = first_variant-value ).
    DATA(mapping_type) = resolve_element_type( data_element = first_mapping-mapping_data_el
                                               sample_value = first_mapping-mapping_value ).

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
        LOOP AT mapping_rows INTO DATA(variant).

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


  METHOD next_counter.

    DATA(highest) = CONV i( get_last_counter( parameter_id = parameter_id
                                              program_name = program_name ) ).

    IF highest >= max_counter.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-015 } { parameter_id }| ).
    ENDIF.

    result = highest + 1.

  ENDMETHOD.


  METHOD append_row.

    DO max_attempts TIMES.

      row-counter = next_counter( parameter_id = row-parameterid
                                  program_name = row-progname ).

      stamp_admin_fields( CHANGING row = row ).

      IF insert_row( row ) = abap_true.
        RETURN.
      ENDIF.

    ENDDO.

    " every allocated counter was taken by a competing LUW before the insert
    RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-016 } { row-parameterid }| ).

  ENDMETHOD.


  METHOD validate_input.

    validate_mandatory( parameter_id = parameter_id
                        field_value  = field_value ).

    validate_data_elements( data_element         = data_element
                            mapping_data_element = mapping_data_element ).

    validate_range( option     = option
                    high_value = high_value ).

    validate_values( field_value          = field_value
                     high_value           = high_value
                     data_element         = data_element
                     mapping_field_value  = mapping_field_value
                     mapping_data_element = mapping_data_element ).

  ENDMETHOD.


  METHOD validate_values.

    " both bounds live in the same column and therefore in the same type
    check_value( value        = field_value
                 data_element = data_element ).

    check_value( value        = high_value
                 data_element = data_element ).

    check_value( value        = mapping_field_value
                 data_element = mapping_data_element ).

  ENDMETHOD.


  METHOD check_value.

    " the native 255 character column holds anything, and nothing is lost from nothing
    IF value IS INITIAL OR data_element IS INITIAL.
      RETURN.
    ENDIF.

    DATA(element) = resolve_element_type( data_element = data_element
                                          sample_value = value ).

    CASE element->type_kind.

      WHEN cl_abap_typedescr=>typekind_date.
        check_date( value        = value
                    data_element = data_element ).

      WHEN cl_abap_typedescr=>typekind_time.
        check_time( value        = value
                    data_element = data_element ).

      WHEN cl_abap_typedescr=>typekind_char
        OR cl_abap_typedescr=>typekind_num
        OR cl_abap_typedescr=>typekind_string.
        " character like targets truncate and filter without raising anything
        check_round_trip( value        = value
                          data_element = data_element
                          element      = element ).

      WHEN OTHERS.
        " every other type reports on its own that the value does not fit
        check_convertible( value        = value
                           data_element = data_element
                           element      = element ).

    ENDCASE.

  ENDMETHOD.


  METHOD check_convertible.

    TRY.
        CREATE DATA result TYPE HANDLE element.
        ASSIGN result->* TO FIELD-SYMBOL(<target>).

        <target> = value.

      CATCH cx_sy_conversion_error cx_sy_create_data_error INTO DATA(conversion_error).
        RAISE EXCEPTION NEW zcx_da_variants(
                  text     = |{ TEXT-020 } { data_element }: { conversion_error->get_text( ) }|
                  previous = conversion_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD check_round_trip.

    DATA stored TYPE ty_value.

    DATA(target) = check_convertible( value        = value
                                      data_element = data_element
                                      element      = element ).

    ASSIGN target->* TO FIELD-SYMBOL(<target>).

    " read the value back the way get_variant( ) would see it
    stored = <target>.

    IF normalized( value = stored type_kind = element->type_kind )
       <> normalized( value = value type_kind = element->type_kind ).
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-021 } { data_element }| ).
    ENDIF.

  ENDMETHOD.


  METHOD normalized.

    result = condense( CONV string( value ) ).

    " NUMC pads with leading zeros, which adds nothing and loses nothing
    IF type_kind = cl_abap_typedescr=>typekind_num.
      SHIFT result LEFT DELETING LEADING '0'.
    ENDIF.

  ENDMETHOD.


  METHOD check_date.

    " a date field is character like, so an impossible day is copied straight in
    DATA(text) = condense( CONV string( value ) ).

    IF strlen( text ) <> date_length OR text CN digits.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-022 } { data_element }| ).
    ENDIF.

    DATA(year)  = CONV i( substring( val = text off = 0 len = 4 ) ).
    DATA(month) = CONV i( substring( val = text off = 4 len = 2 ) ).
    DATA(day)   = CONV i( substring( val = text off = 6 len = 2 ) ).

    IF year < 1 OR year > max_year OR month < 1 OR month > max_month.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-022 } { data_element }| ).
    ENDIF.

    IF day < 1 OR day > last_day_of_month( year = year month = month ).
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-022 } { data_element }| ).
    ENDIF.

  ENDMETHOD.


  METHOD check_time.

    DATA(text) = condense( CONV string( value ) ).

    IF strlen( text ) <> time_length OR text CN digits.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-023 } { data_element }| ).
    ENDIF.

    DATA(hours)   = CONV i( substring( val = text off = 0 len = 2 ) ).
    DATA(minutes) = CONV i( substring( val = text off = 2 len = 2 ) ).
    DATA(seconds) = CONV i( substring( val = text off = 4 len = 2 ) ).

    IF hours > max_hour OR minutes > max_minute OR seconds > max_second.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-023 } { data_element }| ).
    ENDIF.

  ENDMETHOD.


  METHOD last_day_of_month.

    DATA(lengths) = VALUE ty_month_lengths( ( 31 ) ( 28 ) ( 31 ) ( 30 ) ( 31 ) ( 30 )
                                            ( 31 ) ( 31 ) ( 30 ) ( 31 ) ( 30 ) ( 31 ) ).

    result = VALUE #( lengths[ month ] OPTIONAL ).

    IF month = february AND is_leap_year( year ) = abap_true.
      result = leap_day.
    ENDIF.

  ENDMETHOD.


  METHOD is_leap_year.

    result = xsdbool( ( year MOD 4 = 0 AND year MOD 100 <> 0 ) OR year MOD 400 = 0 ).

  ENDMETHOD.


  METHOD validate_mandatory.

    IF parameter_id IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-017 }| ).
    ENDIF.

    IF field_value IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-018 } { parameter_id }| ).
    ENDIF.

  ENDMETHOD.


  METHOD validate_data_elements.

    IF data_element IS NOT INITIAL AND data_element_exists( data_element ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-005 } { data_element }| ).
    ENDIF.

    IF mapping_data_element IS NOT INITIAL
       AND data_element_exists( mapping_data_element ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-006 } { mapping_data_element }| ).
    ENDIF.

  ENDMETHOD.


  METHOD validate_range.

    DATA(takes_high_value) = xsdbool( option = opt_bt OR option = opt_nb ).

    IF takes_high_value = abap_true AND high_value IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-013 } { CONV ty_base_opt( option ) }| ).
    ENDIF.

    " the Fiori application rejects this too, an upper bound has no meaning here
    IF takes_high_value = abap_false AND high_value IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( text = |{ TEXT-019 } { CONV ty_base_opt( option ) }| ).
    ENDIF.

  ENDMETHOD.


  METHOD read_creation_info.

    TRY.
        SELECT SINGLE
          FROM (me->configuration_table)
          FIELDS created_by, created_at
          WHERE progname    = @row-progname
            AND parameterid = @row-parameterid
            AND counter     = @row-counter
          INTO @result.

      CATCH cx_sy_dynamic_osql_semantics
            cx_sy_dynamic_osql_syntax INTO DATA(sql_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-004 } { sql_error->get_text( ) }|
                                             previous = sql_error ).
    ENDTRY.

  ENDMETHOD.


  METHOD stamp_admin_fields.
    DATA change_time TYPE zda_variants-created_at.

    DATA(user_name) = current_user( ).

    GET TIME STAMP FIELD change_time.

    " replacing a row must not rewrite its original creator
    row-created_by            = COND #( WHEN creation_info-created_by IS NOT INITIAL
                                        THEN creation_info-created_by
                                        ELSE user_name ).
    row-created_at            = COND #( WHEN creation_info-created_at IS NOT INITIAL
                                        THEN creation_info-created_at
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


  METHOD insert_row.

    TRY.
        INSERT (me->configuration_table) FROM @row.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(write_error).
        RAISE EXCEPTION NEW zcx_da_variants( text     = |{ TEXT-010 } { write_error->get_text( ) }|
                                             previous = write_error ).
    ENDTRY.

    " a key that is already taken is not an error, the caller allocates the next one
    result = xsdbool( sy-subrc = 0 ).

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


