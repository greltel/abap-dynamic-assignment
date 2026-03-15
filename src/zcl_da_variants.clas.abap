CLASS zcl_da_variants DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_base_sign TYPE c LENGTH 1.
    TYPES ty_base_opt  TYPE c LENGTH 2.

    TYPES:
      BEGIN OF ENUM ty_sign BASE TYPE char1,
        sign_empty   VALUE IS INITIAL ##NEEDED,
        sign_include VALUE 'I' ##NEEDED,
        sign_exclude VALUE 'E' ##NEEDED,
      END OF ENUM ty_sign.

    TYPES:
      BEGIN OF ENUM ty_opt BASE TYPE char2,
        opt_empty VALUE IS INITIAL ##NEEDED,
        opt_eq    VALUE 'EQ' ##NEEDED,
        opt_ne    VALUE 'NE' ##NEEDED,
        opt_bt    VALUE 'BT' ##NEEDED,
        opt_nb    VALUE 'NB' ##NEEDED,
        opt_cp    VALUE 'CP' ##NEEDED,
        opt_np    VALUE 'NP' ##NEEDED,
        opt_lt    VALUE 'LT' ##NEEDED,
        opt_le    VALUE 'LE' ##NEEDED,
        opt_gt    VALUE 'GT' ##NEEDED,
        opt_ge    VALUE 'GE' ##NEEDED,
      END OF ENUM ty_opt.

    TYPES ty_progname    TYPE c LENGTH 40.
    TYPES ty_parameterid TYPE c LENGTH 40.
    TYPES ty_value       TYPE c LENGTH 255.
    TYPES ty_data_el     TYPE c LENGTH 30.
    TYPES ty_description TYPE c LENGTH 80.
    TYPES ty_tabname     TYPE c LENGTH 16.
    TYPES ty_counter     TYPE n LENGTH 5.

    METHODS constructor
      IMPORTING im_tabname TYPE ty_tabname OPTIONAL.

    METHODS get_variant
      IMPORTING im_parameterid          TYPE ty_parameterid
                im_progname             TYPE ty_progname OPTIONAL
      EXPORTING ex_fieldvalue           TYPE any
                ex_mapping_fieldvalue   TYPE any
                ex_table_values         TYPE STANDARD TABLE
                ex_table_mapping_values TYPE REF TO data
                ex_range                TYPE STANDARD TABLE
      RAISING   zcx_da_variants.

    METHODS set_variant
      IMPORTING im_parameterid          TYPE ty_parameterid
                im_progname             TYPE ty_progname    OPTIONAL
                im_fieldvalue           TYPE ty_value
                im_high_value           TYPE ty_value       OPTIONAL
                im_data_element         TYPE ty_data_el     OPTIONAL
                im_mapping_fieldvalue   TYPE ty_value       OPTIONAL
                im_mapping_data_element TYPE ty_data_el     OPTIONAL
                im_sign                 TYPE ty_sign        OPTIONAL
                im_opt                  TYPE ty_opt         OPTIONAL
                im_description          TYPE ty_description OPTIONAL
                im_is_active            TYPE abap_boolean   DEFAULT abap_true
                im_commit               TYPE abap_boolean   DEFAULT abap_true
      RAISING   zcx_da_variants.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS mc_range_sign      TYPE ty_value     VALUE 'SIGN'   ##NO_TEXT.
    CONSTANTS mc_range_option    TYPE ty_value     VALUE 'OPTION' ##NO_TEXT.
    CONSTANTS mc_range_low       TYPE ty_value     VALUE 'LOW'    ##NO_TEXT.
    CONSTANTS mc_range_high      TYPE ty_value     VALUE 'HIGH'   ##NO_TEXT.

    TYPES:
      BEGIN OF t_variants_table,
        mandt                 TYPE mandt,
        progname              TYPE ty_progname,
        parameterid           TYPE ty_parameterid,
        counter               TYPE n LENGTH 5,
        is_active             TYPE abap_boolean,
        sign                  TYPE c LENGTH 1,
        opt                   TYPE c LENGTH 2,
        value                 TYPE ty_value,
        high_value            TYPE ty_value,
        data_element          TYPE ty_data_el,
        mapping_value         TYPE ty_value,
        mapping_data_element  TYPE ty_data_el,
        description           TYPE ty_description,
        created_by            TYPE c LENGTH 12,
        created_at            TYPE tzntstmpl,
        last_changed_by       TYPE c LENGTH 12,
        last_changed_at       TYPE tzntstmpl,
        local_last_changed_at TYPE tzntstmpl,
      END OF t_variants_table.
    TYPES tt_variants TYPE STANDARD TABLE OF t_variants_table WITH EMPTY KEY.

    DATA m_tabname TYPE ty_tabname.

    CONSTANTS c_default_program_name  TYPE ty_progname VALUE 'GLOBAL'.
    CONSTANTS c_default_data_element  TYPE string      VALUE 'CHAR255' ##NO_TEXT.
    CONSTANTS c_value_column_name     TYPE string      VALUE 'VALUE' ##NO_TEXT.
    CONSTANTS c_mapping_column_name   TYPE string      VALUE 'MAPPING_VALUE' ##NO_TEXT.
    CONSTANTS c_table_first_line      TYPE i           VALUE 1 ##NO_TEXT.
    CONSTANTS c_character_length_1    TYPE i           VALUE 1 ##NO_TEXT.
    CONSTANTS c_character_length_2    TYPE i           VALUE 2 ##NO_TEXT.
    CONSTANTS c_default_logging_table TYPE ty_tabname  VALUE 'ZDA_VARIANTS' ##NO_TEXT.

    METHODS get_last_counter
      IMPORTING im_parameterid    TYPE ty_parameterid
                im_progname       TYPE ty_progname OPTIONAL
      RETURNING VALUE(re_counter) TYPE ty_counter.

    METHODS database_table_exists
      IMPORTING im_database_table TYPE ty_tabname
      RETURNING VALUE(re_exists)  TYPE abap_bool.

    METHODS data_element_exists
      IMPORTING im_data_element  TYPE ty_data_el
      RETURNING VALUE(re_exists) TYPE abap_bool.

ENDCLASS.



CLASS ZCL_DA_VARIANTS IMPLEMENTATION.


  METHOD constructor.
    me->m_tabname = COND #(
                            WHEN im_tabname IS NOT INITIAL AND me->database_table_exists( im_tabname ) EQ abap_true
                            THEN to_upper( im_tabname )
                            ELSE to_upper( me->c_default_logging_table )
                          ).
  ENDMETHOD.


  METHOD database_table_exists.
    TRY.
        cl_abap_typedescr=>describe_by_name( EXPORTING p_name          = im_database_table
                                             EXCEPTIONS type_not_found = 1 ).

        IF syst-subrc IS NOT INITIAL.
          RETURN abap_false.
        ENDIF.

        RETURN abap_true.

      CATCH cx_root.
        RETURN abap_false.
    ENDTRY.
  ENDMETHOD.


  METHOD get_last_counter.
    TRY.
        SELECT FROM (me->m_tabname) AS a
          FIELDS ( MAX( a~counter ) )
          WHERE a~parameterid EQ @im_parameterid AND
                a~progname    EQ @im_progname
          INTO @re_counter.

        IF syst-subrc IS NOT INITIAL.
          CLEAR re_counter.
        ENDIF.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax.
        CLEAR re_counter.
    ENDTRY.
  ENDMETHOD.


  METHOD get_variant.

    DATA lt_data          TYPE me->tt_variants.
    DATA lr_table_values  TYPE REF TO data.
    DATA lr_table_mapping TYPE REF TO data.
    DATA lr_range_table   TYPE REF TO data.

    FIELD-SYMBOLS <fs_table_values>  TYPE STANDARD TABLE.
    FIELD-SYMBOLS <fs_range_table>   TYPE STANDARD TABLE.
    FIELD-SYMBOLS <fs_table_mapping> TYPE STANDARD TABLE.

    CLEAR: ex_range,
           ex_fieldvalue,
           ex_mapping_fieldvalue,
           ex_table_values,
           ex_table_mapping_values.

    DATA(lv_paramid)  = CONV ty_parameterid( to_upper( im_parameterid ) ).
    DATA(lv_progname) = CONV ty_progname( to_upper( COND #( WHEN im_progname IS NOT INITIAL THEN im_progname ELSE c_default_program_name ) ) ).

    TRY.
        SELECT FROM (me->m_tabname)
          FIELDS *
          WHERE progname    EQ @lv_progname
            AND parameterid EQ @lv_paramid
            AND is_active   EQ @abap_true
          ORDER BY counter ASCENDING
          INTO CORRESPONDING FIELDS OF TABLE @lt_data.

        IF syst-subrc IS INITIAL AND lt_data IS NOT INITIAL.

          TRY.
              ex_fieldvalue         = VALUE #( lt_data[ c_table_first_line ]-value OPTIONAL ).
              ex_mapping_fieldvalue = VALUE #( lt_data[ c_table_first_line ]-mapping_value OPTIONAL ).
            CATCH cx_sy_conversion_error INTO DATA(lo_conv_err).
              RAISE EXCEPTION NEW zcx_da_variants( iv_text = |{ TEXT-001 } { lo_conv_err->get_text( ) }| previous = lo_conv_err ).
          ENDTRY.

          TRY.

              DATA lo_elem_descr     TYPE REF TO cl_abap_elemdescr.
              DATA lo_map_elem_descr TYPE REF TO cl_abap_elemdescr.

              DATA(lv_first_data_el) = VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ).
              DATA(lv_first_map_el)  = VALUE #( lt_data[ c_table_first_line ]-mapping_data_element OPTIONAL ).

              lo_elem_descr = COND #( WHEN lv_first_data_el IS NOT INITIAL THEN
                                      CAST #( cl_abap_elemdescr=>describe_by_name( lv_first_data_el ) )
                                      ELSE
                                      CAST #( cl_abap_elemdescr=>describe_by_data( VALUE #( lt_data[ c_table_first_line ]-value OPTIONAL ) ) ) ).


              lo_map_elem_descr = COND #( WHEN lv_first_map_el IS NOT INITIAL THEN
                                          CAST #( cl_abap_elemdescr=>describe_by_name( lv_first_map_el ) )
                                          ELSE
                                          CAST #( cl_abap_elemdescr=>describe_by_data( VALUE #( lt_data[ c_table_first_line ]-mapping_value OPTIONAL ) ) ) ).

              IF ex_range IS REQUESTED.

                DATA(lo_range_tab) = cl_abap_tabledescr=>create(
                    p_line_type  = cl_abap_structdescr=>create(
                        VALUE cl_abap_structdescr=>component_table(
                            ( name = mc_range_sign   type = cl_abap_elemdescr=>get_c( p_length = c_character_length_1 ) )
                            ( name = mc_range_option type = cl_abap_elemdescr=>get_c( p_length = c_character_length_2 ) )
                            ( name = mc_range_low    type = lo_elem_descr )
                            ( name = mc_range_high   type = lo_elem_descr ) ) )
                    p_table_kind = cl_abap_tabledescr=>tablekind_std
                    p_key_kind   = cl_abap_tabledescr=>keydefkind_default
                    p_unique     = abap_false ).

                CREATE DATA lr_range_table TYPE HANDLE lo_range_tab.
                ASSIGN lr_range_table->* TO <fs_range_table>.

              ENDIF.

              IF ex_table_values IS REQUESTED.

                DATA(lo_values_tab) = cl_abap_tabledescr=>create(
                    p_line_type  = cl_abap_structdescr=>create(
                        VALUE cl_abap_structdescr=>component_table(
                            ( name = to_upper( me->c_value_column_name ) type = lo_elem_descr ) ) )
                    p_table_kind = cl_abap_tabledescr=>tablekind_std
                    p_key_kind   = cl_abap_tabledescr=>keydefkind_default
                    p_unique     = abap_false ).

                CREATE DATA lr_table_values TYPE HANDLE lo_values_tab.
                ASSIGN lr_table_values->* TO <fs_table_values>.

              ENDIF.

              IF ex_table_mapping_values IS REQUESTED.

                DATA(lo_values_mapping_tab) = cl_abap_tabledescr=>create(
                    p_line_type  = cl_abap_structdescr=>create(
                        VALUE cl_abap_structdescr=>component_table(
                            ( name = to_upper( me->c_value_column_name )   type = lo_elem_descr )
                            ( name = to_upper( me->c_mapping_column_name ) type = lo_map_elem_descr ) ) )
                    p_table_kind = cl_abap_tabledescr=>tablekind_std
                    p_key_kind   = cl_abap_tabledescr=>keydefkind_default
                    p_unique     = abap_false ).

                CREATE DATA lr_table_mapping TYPE HANDLE lo_values_mapping_tab.
                ASSIGN lr_table_mapping->* TO <fs_table_mapping>.

              ENDIF.

            CATCH cx_root INTO DATA(lo_rtts_exception).
              RAISE EXCEPTION NEW zcx_da_variants( iv_text  = |{ TEXT-002 } { lo_rtts_exception->get_text( ) }|
                                                   previous = lo_rtts_exception ).
          ENDTRY.

          TRY.
              LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs_data_line>).

                IF ex_range IS REQUESTED.

                  APPEND INITIAL LINE TO <fs_range_table> ASSIGNING FIELD-SYMBOL(<fs_range_structure>).
                  ASSIGN COMPONENT me->mc_range_low OF STRUCTURE <fs_range_structure> TO FIELD-SYMBOL(<low>).
                  IF syst-subrc IS INITIAL.
                    <low> = <fs_data_line>-value.
                  ENDIF.

                  ASSIGN COMPONENT me->mc_range_high OF STRUCTURE <fs_range_structure> TO FIELD-SYMBOL(<high>).
                  IF syst-subrc IS INITIAL AND <fs_data_line>-high_value IS NOT INITIAL.
                    <high> = <fs_data_line>-high_value.
                  ENDIF.

                  ASSIGN COMPONENT me->mc_range_sign OF STRUCTURE <fs_range_structure> TO FIELD-SYMBOL(<sign>).
                  IF syst-subrc IS INITIAL.
                    <sign> =  <fs_data_line>-sign.
                  ENDIF.

                  ASSIGN COMPONENT me->mc_range_option OF STRUCTURE <fs_range_structure> TO FIELD-SYMBOL(<option>).
                  IF syst-subrc IS INITIAL.
                    <option> =  <fs_data_line>-opt.
                  ENDIF.

                  UNASSIGN: <low>, <high>, <sign>, <option>.

                ENDIF.

                IF ex_table_values IS REQUESTED.

                  APPEND INITIAL LINE TO <fs_table_values> ASSIGNING FIELD-SYMBOL(<fs_values_line>).
                  IF syst-subrc IS INITIAL.
                    <fs_values_line> = <fs_data_line>-value.
                  ENDIF.

                ENDIF.

                IF ex_table_mapping_values IS REQUESTED AND <fs_data_line>-mapping_value IS NOT INITIAL.

                  APPEND INITIAL LINE TO <fs_table_mapping> ASSIGNING FIELD-SYMBOL(<fs_mapping_line>).
                  IF syst-subrc IS INITIAL.
                    ASSIGN COMPONENT me->c_value_column_name OF STRUCTURE <fs_mapping_line> TO FIELD-SYMBOL(<fs_value>).
                    IF syst-subrc IS INITIAL. <fs_value> = <fs_data_line>-value. ENDIF.

                    ASSIGN COMPONENT me->c_mapping_column_name OF STRUCTURE <fs_mapping_line> TO FIELD-SYMBOL(<fs_mapping_value>).
                    IF syst-subrc IS INITIAL. <fs_mapping_value> = <fs_data_line>-mapping_value. ENDIF.
                  ENDIF.

                ENDIF.

              ENDLOOP.
            CATCH cx_sy_conversion_error INTO DATA(lo_loop_err).
              RAISE EXCEPTION NEW zcx_da_variants( iv_text = |{ TEXT-001 } { lo_loop_err->get_text( ) }| previous = lo_loop_err ).
          ENDTRY.

          IF ex_range IS REQUESTED AND <fs_range_table> IS ASSIGNED. ex_range = <fs_range_table>. ENDIF.
          IF ex_table_values IS REQUESTED AND <fs_table_values> IS ASSIGNED. ex_table_values = <fs_table_values>. ENDIF.
          IF ex_table_mapping_values IS REQUESTED AND <fs_table_mapping> IS ASSIGNED. ex_table_mapping_values = REF #( <fs_table_mapping> ). ENDIF.

        ELSE.
          RAISE EXCEPTION NEW zcx_da_variants( iv_text = |{ TEXT-003 } { im_parameterid }| ).
        ENDIF.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(lo_sql_exception).
        RAISE EXCEPTION NEW zcx_da_variants( iv_text  = |{ TEXT-004 } { lo_sql_exception->get_text( ) }|
                                             previous = lo_sql_exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD set_variant.

    DATA(lv_paramid)  = CONV ty_parameterid( to_upper( im_parameterid ) ).
    DATA(lv_progname) = CONV ty_progname( to_upper( COND #( WHEN im_progname IS NOT INITIAL THEN im_progname ELSE c_default_program_name ) ) ).
    DATA(lv_data_el)  = CONV ty_data_el( to_upper( COND #( WHEN im_data_element IS NOT INITIAL THEN im_data_element ELSE me->c_default_data_element ) ) ).
    DATA(lv_map_el)   = CONV ty_data_el( to_upper( COND #( WHEN im_mapping_data_element IS NOT INITIAL AND im_mapping_fieldvalue IS NOT INITIAL THEN im_mapping_data_element
                                         WHEN im_mapping_data_element IS INITIAL AND im_mapping_fieldvalue IS NOT INITIAL THEN me->c_default_data_element
                                         ELSE space ) ) ).

    DATA(lv_enum_sign) = COND #( WHEN im_sign IS NOT INITIAL THEN im_sign ELSE sign_include ).
    DATA(lv_enum_opt)  = COND #( WHEN im_opt  IS NOT INITIAL THEN im_opt  ELSE opt_eq ).

    DATA(lv_db_sign)   = CONV ty_base_sign( lv_enum_sign ).
    DATA(lv_db_opt)    = CONV ty_base_opt( lv_enum_opt ).

    IF lv_data_el IS NOT INITIAL AND me->data_element_exists( lv_data_el ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( iv_text = |{ TEXT-005 } { lv_data_el }| ).
    ENDIF.

    IF lv_map_el IS NOT INITIAL AND me->data_element_exists( lv_map_el ) = abap_false.
      RAISE EXCEPTION NEW zcx_da_variants( iv_text = |{ TEXT-006 } { lv_map_el }| ).
    ENDIF.

    DATA lv_uname TYPE string.
    DATA lv_date  TYPE d.
    DATA lv_time  TYPE t.
    DATA lv_ts    TYPE tzntstmpl.

    TRY.
        lv_uname = cl_abap_context_info=>get_user_technical_name( ).
        lv_date  = cl_abap_context_info=>get_system_date( ).
        lv_time  = cl_abap_context_info=>get_system_time( ).
      CATCH cx_abap_context_info_error.
        lv_uname = 'UNKNOWN'.
    ENDTRY.

    GET TIME STAMP FIELD lv_ts.

    DATA(lv_desc) = COND #( WHEN im_description IS NOT INITIAL
                            THEN im_description
                            ELSE |{ TEXT-007 } { lv_date }-{ lv_time } { TEXT-008 } { lv_uname }| ).

    TRY.
        INSERT (me->m_tabname) FROM @( VALUE me->t_variants_table(
                                           parameterid           = lv_paramid
                                           progname              = lv_progname
                                           counter               = get_last_counter( im_parameterid = lv_paramid
                                                                                     im_progname    = lv_progname ) + 1
                                           is_active             = im_is_active
                                           sign                  = lv_db_sign
                                           opt                   = lv_db_opt
                                           value                 = im_fieldvalue
                                           high_value            = im_high_value
                                           data_element          = lv_data_el
                                           mapping_value         = COND #( WHEN im_mapping_fieldvalue IS NOT INITIAL THEN im_mapping_fieldvalue ELSE space )
                                           mapping_data_element  = lv_map_el
                                           description           = CONV #( lv_desc ) ##OPERATOR[DESCRIPTION]
                                           created_by            = lv_uname
                                           created_at            = lv_ts
                                           last_changed_by       = lv_uname
                                           last_changed_at       = lv_ts
                                           local_last_changed_at = lv_ts ) ).

        IF syst-subrc IS NOT INITIAL.
          RAISE EXCEPTION NEW zcx_da_variants( iv_text = |{ TEXT-009 } { lv_paramid }| ).
        ENDIF.

        IF im_commit = abap_true.
          COMMIT WORK.
        ENDIF.

      CATCH cx_root INTO DATA(lo_exception).
        RAISE EXCEPTION NEW zcx_da_variants( iv_text  = |{ TEXT-010 } { lo_exception->get_text( ) }|
                                             previous = lo_exception ).
    ENDTRY.

  ENDMETHOD.


  METHOD data_element_exists.
    TRY.
        cl_abap_typedescr=>describe_by_name( EXPORTING p_name          = im_data_element
                                             RECEIVING p_descr_ref     = DATA(lo_descr)
                                             EXCEPTIONS type_not_found = 1  ).

        IF syst-subrc IS NOT INITIAL.
          RETURN abap_false.
        ENDIF.

        IF lo_descr->kind = cl_abap_typedescr=>kind_elem.
          RETURN abap_true.
        ENDIF.

      CATCH cx_root.
        RETURN abap_false.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
