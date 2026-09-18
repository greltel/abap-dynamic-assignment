"! <p class="shorttext synchronized" lang="EN">Dynamic assignment variants</p>
"! Default implementation of {@link ZIF_DA_VARIANTS}: the facade consumers hold.
"! <p>Reading and writing goes through {@link ZIF_DA_REPOSITORY}, type checks
"! through {@link ZIF_DA_VALUE_CHECK}, rule evaluation through
"! {@link ZIF_DA_RULE_MATCHER} and user and clock through
"! {@link ZIF_DA_SYSTEM_CONTEXT}. Every collaborator can be injected; without
"! arguments the production set on {@link ZTDA_VARIANTS} is used.</p>
CLASS zcl_da_variants DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_da_variants.

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

    ALIASES sign_include FOR zif_da_variants~sign_include.
    ALIASES sign_exclude FOR zif_da_variants~sign_exclude.

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

    ALIASES get_variant    FOR zif_da_variants~get_variant.
    ALIASES set_variant    FOR zif_da_variants~set_variant.
    ALIASES map_value      FOR zif_da_variants~map_value.
    ALIASES delete_variant FOR zif_da_variants~delete_variant.

    "! Creates the framework on the default configuration table, or on an injected one.
    "! <p>An injected table must be structurally identical to {@link ZTDA_VARIANTS}
    "! and the caller names the packages it may live in. Collaborators passed here
    "! replace the production ones; a repository passed here wins over table_name.</p>
    "!
    "! @parameter table_name      | Configuration table, defaults to <em>ZTDA_VARIANTS</em>
    "! @parameter packages        | Package list an injected table must belong to
    "! @parameter repository      | Persistence, defaults to {@link ZCL_DA_REPOSITORY}
    "! @parameter value_check     | Type checks, defaults to {@link ZCL_DA_VALUE_CHECK}
    "! @parameter rule_matcher    | Rule evaluation, defaults to {@link ZCL_DA_RULE_MATCHER}
    "! @parameter system_context  | User and clock, defaults to the running session
    "! @raising   zcx_da_variants | Table is unknown or outside the allowed packages
    METHODS constructor
      IMPORTING table_name     TYPE ty_tabname OPTIONAL
                packages       TYPE string     OPTIONAL
                repository     TYPE REF TO zif_da_repository     OPTIONAL
                value_check    TYPE REF TO zif_da_value_check    OPTIONAL
                rule_matcher   TYPE REF TO zif_da_rule_matcher   OPTIONAL
                system_context TYPE REF TO zif_da_system_context OPTIONAL
      RAISING   zcx_da_variants.

  PRIVATE SECTION.

    TYPES ty_data_elements TYPE STANDARD TABLE OF ty_data_el WITH EMPTY KEY.

    CONSTANTS default_program TYPE ty_progname VALUE 'GLOBAL' ##NO_TEXT.

    "! Highest counter the NUMC(5) key can hold.
    CONSTANTS max_counter  TYPE i VALUE 99999.
    "! Times an append retries after another LUW took the allocated counter.
    CONSTANTS max_attempts TYPE i VALUE 5.

    CONSTANTS component_sign   TYPE string VALUE `SIGN`          ##NO_TEXT.
    CONSTANTS component_option TYPE string VALUE `OPTION`        ##NO_TEXT.
    CONSTANTS component_low    TYPE string VALUE `LOW`           ##NO_TEXT.
    CONSTANTS component_high   TYPE string VALUE `HIGH`          ##NO_TEXT.
    CONSTANTS column_value     TYPE string VALUE `VALUE`         ##NO_TEXT.
    CONSTANTS column_mapping   TYPE string VALUE `MAPPING_VALUE` ##NO_TEXT.

    DATA repository     TYPE REF TO zif_da_repository.
    DATA value_check    TYPE REF TO zif_da_value_check.
    DATA rule_matcher   TYPE REF TO zif_da_rule_matcher.
    DATA system_context TYPE REF TO zif_da_system_context.

    "! Normalises the program scope the caller passed.
    "! @parameter program_name | Program name, may be initial
    "! @parameter result       | Upper case program name, the global scope when initial
    METHODS program_scope
      IMPORTING program_name  TYPE ty_progname
      RETURNING VALUE(result) TYPE ty_progname.

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

    "! Returns the data elements without duplicates, in alphabetical order.
    "! @parameter elements | Data elements as they appear on the rows
    "! @parameter result   | Each data element once
    METHODS distinct
      IMPORTING elements      TYPE ty_data_elements
      RETURNING VALUE(result) TYPE ty_data_elements.

    "! Returns the rows that actually carry a mapping value.
    "! @parameter variants | Active variants, ordered by counter
    "! @parameter result   | Rows with a filled mapping value, order preserved
    METHODS mapping_variants
      IMPORTING variants      TYPE ty_variants
      RETURNING VALUE(result) TYPE ty_variants.

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

    "! Fills the administrative fields and the generated description.
    "! @parameter creation_info | Stamp to keep, initial for a row that is created
    "! @parameter row           | Variant row, completed in place
    METHODS stamp_admin_fields
      IMPORTING creation_info TYPE zif_da_repository=>ty_creation_info OPTIONAL
      CHANGING  row           TYPE ty_variant.

    "! Builds the description used when the caller does not supply one.
    "! @parameter user_name | Author of the row
    "! @parameter result    | Generated description
    METHODS default_description
      IMPORTING user_name     TYPE zif_da_system_context=>ty_user
      RETURNING VALUE(result) TYPE ty_description.

    "! Wraps a conversion error into the framework exception.
    "! @parameter conversion_error | Cause
    "! @parameter counter          | Row the value came from, initial for the input
    "! @parameter result           | Exception to raise, cause chained
    METHODS conversion_failed
      IMPORTING conversion_error TYPE REF TO cx_sy_conversion_error
                counter          TYPE ty_counter OPTIONAL
      RETURNING VALUE(result)    TYPE REF TO zcx_da_variants.

ENDCLASS.



CLASS zcl_da_variants IMPLEMENTATION.


  METHOD constructor.

    " the framework is instantiated without arguments in production, tests pass doubles
    me->repository     = COND #( WHEN repository IS BOUND
                                 THEN repository
                                 ELSE NEW zcl_da_repository( table_name = table_name
                                                             packages   = packages ) ).
    me->value_check    = COND #( WHEN value_check IS BOUND
                                 THEN value_check
                                 ELSE NEW zcl_da_value_check( ) ).
    me->rule_matcher   = COND #( WHEN rule_matcher IS BOUND
                                 THEN rule_matcher
                                 ELSE NEW zcl_da_rule_matcher( me->value_check ) ).
    me->system_context = COND #( WHEN system_context IS BOUND
                                 THEN system_context
                                 ELSE NEW zcl_da_system_context( ) ).

  ENDMETHOD.


  METHOD program_scope.

    result = to_upper( COND ty_progname( WHEN program_name IS NOT INITIAL
                                         THEN program_name
                                         ELSE default_program ) ).

  ENDMETHOD.


  METHOD zif_da_variants~get_variant.

    CLEAR: field_value, mapping_field_value, values, mapping_values, range.

    DATA(parameter) = CONV ty_parameterid( to_upper( parameter_id ) ).
    DATA(program)   = program_scope( program_name ).

    DATA(variants)      = read_variants( parameter_id = parameter
                                         program_name = program ).
    DATA(first_variant) = VALUE ty_variant( variants[ 1 ] OPTIONAL ).

    TRY.
        IF field_value IS SUPPLIED.
          field_value = first_variant-value.
        ENDIF.

        IF mapping_field_value IS SUPPLIED.
          mapping_field_value = first_variant-mapping_value.
        ENDIF.

      CATCH cx_sy_conversion_error INTO DATA(conversion_error).
        RAISE EXCEPTION conversion_failed( conversion_error ).
    ENDTRY.

    IF range IS SUPPLIED.
      fill_range( EXPORTING variants = variants
                  CHANGING  range    = range ).
    ENDIF.

    IF values IS SUPPLIED.
      fill_values( EXPORTING variants = variants
                   CHANGING  values   = values ).
    ENDIF.

    IF mapping_values IS SUPPLIED.
      mapping_values = build_mapping_table( variants ).
    ENDIF.

  ENDMETHOD.


  METHOD zif_da_variants~set_variant.

    DATA(parameter) = CONV ty_parameterid( to_upper( parameter_id ) ).
    DATA(program)   = program_scope( program_name ).

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
        sign            = variant_sign
        opt             = variant_option
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
      stamp_admin_fields( EXPORTING creation_info = repository->read_creation_info( row )
                          CHANGING  row           = row ).
      repository->replace_row( row ).
    ENDIF.

    IF commit = abap_true.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.


  METHOD zif_da_variants~map_value.

    CLEAR: mapping_value, matched.

    DATA(parameter) = CONV ty_parameterid( to_upper( parameter_id ) ).
    DATA(program)   = program_scope( program_name ).

    DATA(variants) = read_variants( parameter_id = parameter
                                    program_name = program ).

    " every row of one parameter shares the type, read_variants( ) has checked that
    DATA(first_variant) = VALUE ty_variant( variants[ 1 ] OPTIONAL ).
    DATA(element)       = value_check->resolve_element_type( data_element = first_variant-data_element
                                                             sample_value = first_variant-value ).

    LOOP AT variants INTO DATA(variant).

      IF rule_matcher->accepts( variant = variant
                                input   = input
                                element = element ) = abap_false.
        CONTINUE.
      ENDIF.

      " the first rule that answers decides, whether it includes or excludes
      IF variant-sign = sign_exclude.
        RETURN.
      ENDIF.

      TRY.
          IF mapping_value IS SUPPLIED.
            mapping_value = variant-mapping_value.
          ENDIF.

        CATCH cx_sy_conversion_error INTO DATA(conversion_error).
          RAISE EXCEPTION conversion_failed( conversion_error = conversion_error
                                             counter          = variant-counter ).
      ENDTRY.

      matched = abap_true.
      RETURN.

    ENDLOOP.

  ENDMETHOD.


  METHOD zif_da_variants~delete_variant.

    DATA(parameter) = CONV ty_parameterid( to_upper( parameter_id ) ).
    DATA(program)   = program_scope( program_name ).

    " without a parameter this would clear whatever happens to have a blank key
    IF parameter IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>parameter_missing ).
    ENDIF.

    result = repository->delete_rows( program_name = program
                                      parameter_id = parameter
                                      counter      = counter ).

    IF commit = abap_true.
      COMMIT WORK.
    ENDIF.

  ENDMETHOD.


  METHOD read_variants.

    result = repository->read_active_variants( program_name = program_name
                                               parameter_id = parameter_id ).

    IF result IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>no_active_variant
                                           msgv1  = parameter_id ).
    ENDIF.

    check_type_consistency( result ).

  ENDMETHOD.


  METHOD check_type_consistency.

    DATA(elements) = distinct( VALUE ty_data_elements( FOR variant IN variants ( variant-data_element ) ) ).

    IF lines( elements ) > 1.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>inconsistent_elements
                                           msgv1  = variants[ 1 ]-parameterid
                                           msgv2  = concat_lines_of( table = elements sep = `, ` ) ).
    ENDIF.

    " only rows that map something take part, a row without a mapping value has no type
    DATA(mapping_rows) = mapping_variants( variants ).

    DATA(mapping_elements) = distinct( VALUE ty_data_elements( FOR mapping_row IN mapping_rows
                                                                ( mapping_row-mapping_data_el ) ) ).

    IF lines( mapping_elements ) > 1.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>inconsistent_mapping_elements
                                           msgv1  = variants[ 1 ]-parameterid
                                           msgv2  = concat_lines_of( table = mapping_elements sep = `, ` ) ).
    ENDIF.

  ENDMETHOD.


  METHOD distinct.

    result = elements.
    SORT result.
    DELETE ADJACENT DUPLICATES FROM result.

  ENDMETHOD.


  METHOD mapping_variants.

    result = VALUE #( FOR variant IN variants
                      WHERE ( mapping_value IS NOT INITIAL )
                      ( variant ) ).

  ENDMETHOD.


  METHOD fill_range.

    TRY.
        LOOP AT variants INTO DATA(variant).

          INSERT INITIAL LINE INTO TABLE range ASSIGNING FIELD-SYMBOL(<range_line>).

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
        RAISE EXCEPTION conversion_failed( conversion_error = conversion_error
                                           counter          = variant-counter ).
    ENDTRY.

  ENDMETHOD.


  METHOD fill_values.

    TRY.
        LOOP AT variants INTO DATA(variant).
          INSERT INITIAL LINE INTO TABLE values ASSIGNING FIELD-SYMBOL(<value_line>).
          <value_line> = variant-value.
        ENDLOOP.

      CATCH cx_sy_conversion_error INTO DATA(conversion_error).
        CLEAR values.
        RAISE EXCEPTION conversion_failed( conversion_error = conversion_error
                                           counter          = variant-counter ).
    ENDTRY.

  ENDMETHOD.


  METHOD build_mapping_table.

    FIELD-SYMBOLS <mapping_table> TYPE STANDARD TABLE.

    DATA(first_variant) = VALUE ty_variant( variants[ 1 ] OPTIONAL ).

    " the mapping type belongs to the rows that map something, not to the first row
    DATA(mapping_rows)  = mapping_variants( variants ).
    DATA(first_mapping) = VALUE ty_variant( mapping_rows[ 1 ] OPTIONAL ).

    DATA(value_type)   = value_check->resolve_element_type( data_element = first_variant-data_element
                                                            sample_value = first_variant-value ).
    DATA(mapping_type) = value_check->resolve_element_type( data_element = first_mapping-mapping_data_el
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
        RAISE EXCEPTION NEW zcx_da_variants( textid   = zcx_da_variants=>rtts_failed
                                             msgv1    = rtts_error->get_text( )
                                             previous = rtts_error ).
    ENDTRY.

    ASSIGN result->* TO <mapping_table>.

    TRY.
        LOOP AT mapping_rows INTO DATA(variant).

          INSERT INITIAL LINE INTO TABLE <mapping_table> ASSIGNING FIELD-SYMBOL(<mapping_line>).

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
        RAISE EXCEPTION conversion_failed( conversion_error = conversion_error
                                           counter          = variant-counter ).
    ENDTRY.

  ENDMETHOD.


  METHOD next_counter.

    DATA(last_counters) = repository->read_last_counters(
                              VALUE #( ( progname    = program_name
                                         parameterid = parameter_id ) ) ).

    DATA(highest) = CONV i( VALUE #( last_counters[ progname    = program_name
                                                    parameterid = parameter_id ]-counter OPTIONAL ) ).

    IF highest >= max_counter.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>counter_exhausted
                                           msgv1  = parameter_id ).
    ENDIF.

    result = highest + 1.

  ENDMETHOD.


  METHOD append_row.

    DO max_attempts TIMES.

      row-counter = next_counter( parameter_id = row-parameterid
                                  program_name = row-progname ).

      stamp_admin_fields( CHANGING row = row ).

      IF repository->insert_row( row ) = abap_true.
        RETURN.
      ENDIF.

    ENDDO.

    " every allocated counter was taken by a competing LUW before the insert
    RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>counter_not_secured
                                         msgv1  = row-parameterid ).

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
    value_check->check_value( value        = field_value
                              data_element = data_element ).

    value_check->check_value( value        = high_value
                              data_element = data_element ).

    value_check->check_value( value        = mapping_field_value
                              data_element = mapping_data_element ).

  ENDMETHOD.


  METHOD validate_mandatory.

    IF parameter_id IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>parameter_missing ).
    ENDIF.

    IF field_value IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>value_missing
                                           msgv1  = parameter_id ).
    ENDIF.

  ENDMETHOD.


  METHOD validate_data_elements.

    IF data_element IS NOT INITIAL AND value_check->data_element_exists( data_element ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_data_element
                                           msgv1  = data_element ).
    ENDIF.

    IF mapping_data_element IS NOT INITIAL
       AND value_check->data_element_exists( mapping_data_element ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>invalid_mapping_element
                                           msgv1  = mapping_data_element ).
    ENDIF.

  ENDMETHOD.


  METHOD validate_range.

    DATA(takes_high_value) = xsdbool( option = opt_bt OR option = opt_nb ).

    IF takes_high_value = abap_true AND high_value IS INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>high_value_missing
                                           msgv1  = option ).
    ENDIF.

    " the Fiori application rejects this too, an upper bound has no meaning here
    IF takes_high_value = abap_false AND high_value IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_da_variants( textid = zcx_da_variants=>high_value_not_allowed
                                           msgv1  = option ).
    ENDIF.

  ENDMETHOD.


  METHOD stamp_admin_fields.

    DATA(user_name)   = system_context->user_name( ).
    DATA(change_time) = system_context->time_stamp( ).

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


  METHOD default_description.

    DATA(current_date) = system_context->current_date( ).
    DATA(current_time) = system_context->current_time( ).

    " the text is a translatable message, filled with the ISO forms of date and time
    MESSAGE i007(zda) WITH |{ current_date DATE = ISO }| |{ current_time TIME = ISO }| user_name
      INTO DATA(description).

    result = description.

  ENDMETHOD.


  METHOD conversion_failed.

    DATA(cause) = conversion_error->get_text( ).

    result = NEW zcx_da_variants( textid   = zcx_da_variants=>conversion_failed
                                  msgv1    = COND #( WHEN counter IS INITIAL
                                                     THEN cause
                                                     ELSE |{ cause } [{ counter }]| )
                                  previous = conversion_error ).

  ENDMETHOD.


ENDCLASS.
