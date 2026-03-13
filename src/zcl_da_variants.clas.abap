CLASS zcl_da_variants DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES ty_progname    TYPE c LENGTH 40.
    TYPES ty_parameterid TYPE c LENGTH 40.
    TYPES ty_value       TYPE c LENGTH 255.
    TYPES ty_data_el     TYPE c LENGTH 30.
    TYPES ty_sign        TYPE c LENGTH 1.
    TYPES ty_description TYPE c LENGTH 80.
    TYPES ty_tabname     TYPE c LENGTH 16.
    TYPES ty_msgty       TYPE c LENGTH 1.
    TYPES ty_counter     TYPE n LENGTH 5.

    METHODS constructor
      IMPORTING
        !im_tabname TYPE ty_tabname OPTIONAL .
    METHODS get_variant
      IMPORTING
        !im_parameterid          TYPE ty_parameterid
        !im_progname             TYPE ty_progname OPTIONAL
      EXPORTING
        !ex_fieldvalue           TYPE any
        !ex_mapping_fieldvalue   TYPE any
        !ex_table_values         TYPE STANDARD TABLE
        !ex_table_mapping_values TYPE REF TO data
        !ex_range                TYPE STANDARD TABLE
        !ex_result               TYPE bapi_mtype
        !ex_message              TYPE bapi_msg .
    METHODS set_variant
      IMPORTING
        !im_parameterid          TYPE ty_parameterid
        !im_progname             TYPE ty_progname OPTIONAL
        !im_fieldvalue           TYPE ty_value
        !im_data_element         TYPE ty_data_el OPTIONAL
        !im_mapping_fieldvalue   TYPE ty_value OPTIONAL
        !im_mapping_data_element TYPE ty_data_el OPTIONAL
        !im_sign                 TYPE ty_sign OPTIONAL
        !im_description          TYPE ty_description OPTIONAL
        !im_commit               TYPE abap_boolean DEFAULT abap_true
      RETURNING
        VALUE(ex_result)         TYPE ty_msgty .
  PROTECTED SECTION.
  PRIVATE SECTION.

    " Message Types (BAPI_MTYPE)
    CONSTANTS mc_msg_typ_success TYPE bapi_mtype VALUE 'S' ##NO_TEXT.
    CONSTANTS mc_msg_typ_error   TYPE bapi_mtype VALUE 'E' ##NO_TEXT.

    " Range Table Components (Field Names)
    CONSTANTS mc_range_sign      TYPE string VALUE 'SIGN'   ##NO_TEXT.
    CONSTANTS mc_range_option    TYPE string VALUE 'OPTION' ##NO_TEXT.
    CONSTANTS mc_range_low       TYPE string VALUE 'LOW'    ##NO_TEXT.
    CONSTANTS mc_range_high      TYPE string VALUE 'HIGH'   ##NO_TEXT.

    " Range Table Values
    CONSTANTS mc_sign_include    TYPE tvarv_sign VALUE 'I'  ##NO_TEXT.
    CONSTANTS mc_option_equal    TYPE char02     VALUE 'EQ' ##NO_TEXT.

    TYPES:
      BEGIN OF t_variants_table,
        mandt                TYPE mandt,
        progname             TYPE ty_progname,
        parameterid          TYPE ty_parameterid,
        counter              TYPE n LENGTH 5,
        value                TYPE ty_value,
        data_element         TYPE ty_data_el,
        mapping_value        TYPE ty_value,
        mapping_data_element TYPE ty_data_el,
        sign                 TYPE ty_sign,
        description          TYPE ty_description,
      END OF t_variants_table .
    TYPES:
      tt_variants TYPE STANDARD TABLE OF t_variants_table INITIAL SIZE 0 WITH EMPTY KEY .

    DATA m_tabname TYPE ty_tabname .
    CONSTANTS c_default_data_element  TYPE string  VALUE 'CHAR255' ##NO_TEXT.
    CONSTANTS c_value_column_name     TYPE string  VALUE 'VALUE' ##NO_TEXT.
    CONSTANTS c_mapping_column_name   TYPE string  VALUE 'MAPPING_VALUE' ##NO_TEXT.
    CONSTANTS c_table_first_line      TYPE i       VALUE 1 ##NO_TEXT.
    CONSTANTS c_character_length_1    TYPE i       VALUE 1 ##NO_TEXT.
    CONSTANTS c_character_length_2    TYPE i       VALUE 2 ##NO_TEXT.
    CONSTANTS c_default_logging_table TYPE ty_tabname  VALUE 'ZDA_VARIANTS' ##NO_TEXT.

    METHODS get_last_counter
      IMPORTING
        !im_parameterid   TYPE ty_parameterid
        !im_progname      TYPE ty_progname OPTIONAL
      RETURNING
        VALUE(re_counter) TYPE ty_counter.

    METHODS database_table_exists
      IMPORTING
        !im_database_table TYPE ty_tabname
      RETURNING
        VALUE(re_exists)   TYPE abap_bool .

    METHODS data_element_exists
      IMPORTING
        !im_data_element TYPE ty_data_el
      RETURNING
        VALUE(re_exists) TYPE abap_bool .

ENDCLASS.



CLASS ZCL_DA_VARIANTS IMPLEMENTATION.


  METHOD constructor.

*&----------------------------------------------------------------------*
*&  DETERMINE CUSTOMIZING TABLE TO RETRIEVE VALUES
*&----------------------------------------------------------------------*
    me->m_tabname = COND #(
                            WHEN im_tabname IS SUPPLIED AND im_tabname IS NOT INITIAL AND me->database_table_exists( im_tabname ) EQ abap_true
                            THEN to_upper( im_tabname )
                            ELSE to_upper( me->c_default_logging_table )
                          ).

  ENDMETHOD.


  METHOD database_table_exists.

    TRY.
        cl_abap_typedescr=>describe_by_name( EXPORTING  p_name = im_database_table
                                             EXCEPTIONS type_not_found = 1 ).
        IF syst-subrc IS INITIAL.
          RETURN abap_true.
        ENDIF.

      CATCH cx_root.
        RETURN abap_false.
    ENDTRY.

  ENDMETHOD.


  METHOD get_last_counter.

    TRY.

        SELECT SINGLE FROM (me->m_tabname) AS a
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

*&----------------------------------------------------------------------*
*&  INITIALIZATION-DATA DECLARATION
*&----------------------------------------------------------------------*
    DATA:lt_data            TYPE me->tt_variants,
         lr_table_values    TYPE REF TO data,
         lr_table_mapping   TYPE REF TO data,
         lr_range_table     TYPE REF TO data,
         lr_range_structure TYPE REF TO data.

    FIELD-SYMBOLS:<fs_table_values>  TYPE STANDARD TABLE,
                  <fs_range_table>   TYPE STANDARD TABLE,
                  <fs_table_mapping> TYPE STANDARD TABLE.

    CLEAR:ex_result,ex_message,ex_range,ex_fieldvalue,ex_mapping_fieldvalue.

    ex_result = me->mc_msg_typ_success.

*&----------------------------------------------------------------------*
*&  SELECT DATA FROM TABLE
*&----------------------------------------------------------------------*

    TRY.

        SELECT FROM (me->m_tabname)
        FIELDS *
        WHERE progname    EQ @( to_upper( im_progname ) ) AND
              parameterid EQ @( to_upper( im_parameterid ) )
        ORDER BY counter ASCENDING
        INTO CORRESPONDING FIELDS OF TABLE @lt_data.

*&----------------------------------------------------------------------*
*&  CONSTRUCT SINGLE VALUE-RANGE AND TABLES FOR RETURN
*&----------------------------------------------------------------------*
        IF syst-subrc IS INITIAL AND lt_data IS NOT INITIAL.

          "RETURN SINGLE VALUE
          ex_fieldvalue = VALUE #( lt_data[ c_table_first_line ]-value OPTIONAL ).

          "RETURN MAPPING VALUE
          ex_mapping_fieldvalue = VALUE #( lt_data[ c_table_first_line ]-mapping_value OPTIONAL ).

          IF ex_range                IS REQUESTED OR
             ex_table_values         IS REQUESTED OR
             ex_table_mapping_values IS REQUESTED.

            "RETURN RANGE TABLE-VALUES TABLE-MAPPING TABLE
            TRY.

                DATA(lo_range_tab) = cl_abap_tabledescr=>create(
                    p_line_type  = cl_abap_structdescr=>create( VALUE cl_abap_structdescr=>component_table(
                                                                ( name = me->mc_range_sign   type  = cl_abap_elemdescr=>get_c( p_length = me->c_character_length_1 ) )
                                                                ( name = me->mc_range_option type  = cl_abap_elemdescr=>get_c( p_length = me->c_character_length_2 ) )

                                                                ( name = me->mc_range_low    type  = COND #( WHEN ( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) IS NOT INITIAL
                                                                                                             THEN CAST #( cl_abap_elemdescr=>describe_by_name( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) )
                                                                                                             ELSE CAST #( cl_abap_elemdescr=>describe_by_data( VALUE #( lt_data[ c_table_first_line ]-value OPTIONAL ) ) ) ) )

                                                                ( name = me->mc_range_high   type  = COND #( WHEN ( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) IS NOT INITIAL
                                                                                                             THEN CAST #( cl_abap_elemdescr=>describe_by_name( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) )
                                                                                                             ELSE CAST #( cl_abap_elemdescr=>describe_by_data( VALUE #( lt_data[ c_table_first_line ]-value OPTIONAL ) ) ) ) ) ) )
                    p_table_kind = cl_abap_tabledescr=>tablekind_std
                    p_key_kind   = cl_abap_tabledescr=>keydefkind_default
                    p_unique     = abap_false ).

                DATA(lo_values_tab) = cl_abap_tabledescr=>create(
                    p_line_type  = cl_abap_structdescr=>create( VALUE cl_abap_structdescr=>component_table(
                                                                ( name = to_upper( me->c_value_column_name )   type  = COND #( WHEN ( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) IS NOT INITIAL
                                                                                                                               THEN CAST #( cl_abap_elemdescr=>describe_by_name( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) )
                                                                                                                               ELSE CAST #( cl_abap_elemdescr=>describe_by_data( VALUE #( lt_data[ c_table_first_line ]-value OPTIONAL ) ) ) ) ) ) )
                    p_table_kind = cl_abap_tabledescr=>tablekind_std
                    p_key_kind   = cl_abap_tabledescr=>keydefkind_default
                    p_unique     = abap_false ).

                DATA(lo_values_mapping_tab) = cl_abap_tabledescr=>create(
                    p_line_type  = cl_abap_structdescr=>create( VALUE cl_abap_structdescr=>component_table(
                                                                ( name = to_upper( me->c_value_column_name )    type  = COND #( WHEN ( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) IS NOT INITIAL
                                                                                                                                THEN CAST #( cl_abap_elemdescr=>describe_by_name( VALUE #( lt_data[ c_table_first_line ]-data_element OPTIONAL ) ) )
                                                                                                                                ELSE CAST #( cl_abap_elemdescr=>describe_by_data( VALUE #( lt_data[ c_table_first_line ]-value OPTIONAL ) ) ) ) )
                                                                ( name = to_upper( me->c_mapping_column_name )  type  = COND #( WHEN ( VALUE #( lt_data[ c_table_first_line ]-mapping_data_element OPTIONAL ) ) IS NOT INITIAL
                                                                                                                                THEN CAST #( cl_abap_elemdescr=>describe_by_name( VALUE #( lt_data[ c_table_first_line ]-mapping_data_element OPTIONAL ) ) )
                                                                                                                                ELSE CAST #( cl_abap_elemdescr=>describe_by_data( VALUE #( lt_data[ c_table_first_line ]-mapping_value OPTIONAL ) ) ) ) ) ) )
                    p_table_kind = cl_abap_tabledescr=>tablekind_std
                    p_key_kind   = cl_abap_tabledescr=>keydefkind_default
                    p_unique     = abap_false ).

                CREATE DATA lr_range_table     TYPE HANDLE lo_range_tab.
                CREATE DATA lr_table_values    TYPE HANDLE lo_values_tab.
                CREATE DATA lr_table_mapping   TYPE HANDLE lo_values_mapping_tab.

                ASSIGN lr_range_table->* TO <fs_range_table>.
                ASSIGN lr_table_values->* TO <fs_table_values>.
                ASSIGN lr_table_mapping->* TO <fs_table_mapping>.

              CATCH cx_sy_struct_attributes cx_sy_table_attributes cx_sy_create_data_error INTO DATA(lo_exception).
                ex_result   = me->mc_msg_typ_error.
                ex_message = lo_exception->get_text( ).
                RETURN.
            ENDTRY.

            LOOP AT lt_data ASSIGNING FIELD-SYMBOL(<fs_data_line>).

              "RANGE TABLE
              APPEND INITIAL LINE TO <fs_range_table> ASSIGNING FIELD-SYMBOL(<fs_range_structure>).

              ASSIGN COMPONENT me->mc_range_low OF STRUCTURE <fs_range_structure> TO FIELD-SYMBOL(<low>).
              IF syst-subrc IS INITIAL.
                <low> = <fs_data_line>-value.
              ENDIF.

              ASSIGN COMPONENT me->mc_range_sign OF STRUCTURE <fs_range_structure> TO FIELD-SYMBOL(<sign>).
              IF syst-subrc IS INITIAL.
                <sign> = COND #( WHEN <fs_data_line>-sign IS NOT INITIAL
                                 THEN <fs_data_line>-sign
                                 ELSE me->mc_sign_include ).
              ENDIF.

              ASSIGN COMPONENT me->mc_range_option OF STRUCTURE <fs_range_structure> TO FIELD-SYMBOL(<option>).
              IF syst-subrc IS INITIAL.
                <option> = me->mc_option_equal.
              ENDIF.

              UNASSIGN:<low>,<sign>,<option>.

              "VALUES TABLE
              APPEND INITIAL LINE TO <fs_table_values> ASSIGNING FIELD-SYMBOL(<fs_values_line>).
              IF syst-subrc IS INITIAL.
                <fs_values_line> = <fs_data_line>-value.
              ENDIF.

              "MAPPING TABLE
              IF <fs_data_line>-mapping_value IS NOT INITIAL.

                APPEND INITIAL LINE TO <fs_table_mapping> ASSIGNING FIELD-SYMBOL(<fs_mapping_line>).

                IF syst-subrc IS INITIAL.
                  ASSIGN COMPONENT me->c_value_column_name OF STRUCTURE <fs_mapping_line> TO FIELD-SYMBOL(<fs_value>).
                  IF syst-subrc IS INITIAL.
                    <fs_value> = <fs_data_line>-value.
                  ENDIF.

                  ASSIGN COMPONENT me->c_mapping_column_name OF STRUCTURE <fs_mapping_line> TO FIELD-SYMBOL(<fs_mapping_value>).
                  IF syst-subrc IS INITIAL.
                    <fs_mapping_value> = <fs_data_line>-mapping_value.
                  ENDIF.

                ENDIF.

              ENDIF.

            ENDLOOP.

            IF <fs_range_table> IS NOT INITIAL.
              ex_range = <fs_range_table>.
            ENDIF.

            IF <fs_table_values> IS NOT INITIAL.
              ex_table_values = <fs_table_values>.
            ENDIF.

            IF <fs_table_mapping> IS NOT INITIAL.
              ex_table_mapping_values = REF #( <fs_table_mapping> ).
            ENDIF.

          ENDIF.

        ELSE.

          ex_result  = me->mc_msg_typ_error.
          ex_message = 'No Data Retrieved for Specified Criteria'.

        ENDIF.

      CATCH cx_sy_dynamic_osql_semantics cx_sy_dynamic_osql_syntax INTO DATA(lo_sql_exception).
        ex_result  = me->mc_msg_typ_error.
        ex_message = lo_sql_exception->get_text( ).
        RETURN.
    ENDTRY.

  ENDMETHOD.


  METHOD set_variant.

    IF im_data_element IS NOT INITIAL AND me->data_element_exists( im_data_element ) = abap_false.
      ex_result = me->mc_msg_typ_error.
      RETURN.
    ENDIF.

    IF im_mapping_data_element IS NOT INITIAL AND me->data_element_exists( im_mapping_data_element ) = abap_false.
      ex_result = me->mc_msg_typ_error.
      RETURN.
    ENDIF.

    TRY.
        DATA(lv_uname) = cl_abap_context_info=>get_user_technical_name( ).
        DATA(lv_date)  = cl_abap_context_info=>get_system_date( ).
        DATA(lv_time)  = cl_abap_context_info=>get_system_time( ).
      CATCH cx_abap_context_info_error.
        lv_uname = 'UNKNOWN'.
    ENDTRY.

*&----------------------------------------------------------------------*
*&  INSERT TO DATABASE TABLE
*&----------------------------------------------------------------------*
    DATA(lv_progname) = COND #( WHEN im_progname IS NOT INITIAL THEN im_progname ELSE 'GLOBAL' ).
    DATA(lv_desc) = COND #( WHEN im_description IS NOT INITIAL THEN im_description ELSE |Entry Created at { lv_date }-{ lv_time } from user { lv_uname }| ).

    TRY.
        INSERT (me->m_tabname) FROM @( VALUE me->t_variants_table(
                                                                   parameterid          = im_parameterid
                                                                   progname             = lv_progname
                                                                   counter              = me->get_last_counter( im_parameterid = im_parameterid im_progname = lv_progname ) + 1
                                                                   value                = im_fieldvalue
                                                                   data_element         = COND #( WHEN im_data_element IS NOT INITIAL THEN im_data_element ELSE me->c_default_data_element )
                                                                   mapping_value        = COND #( WHEN im_mapping_fieldvalue IS NOT INITIAL THEN im_mapping_fieldvalue )
                                                                   mapping_data_element = COND #( WHEN im_mapping_data_element IS NOT INITIAL AND im_mapping_fieldvalue IS NOT INITIAL THEN im_mapping_data_element
                                                                                                  WHEN im_mapping_data_element IS INITIAL AND im_mapping_fieldvalue IS NOT INITIAL THEN me->c_default_data_element )
                                                                   sign                 = COND #( WHEN im_sign IS NOT INITIAL THEN im_sign ELSE me->mc_sign_include )
                                                                   description          = CONV #( lv_desc ) ) ##OPERATOR[DESCRIPTION]
                                                                 ).

        ex_result = COND #( WHEN syst-subrc IS INITIAL THEN me->mc_msg_typ_success ELSE me->mc_msg_typ_error ).

        IF im_commit EQ abap_true AND ex_result EQ me->mc_msg_typ_success.
          COMMIT WORK.
        ENDIF.

      CATCH cx_stream_io_exception cx_close_resource_error cx_sy_dynamic_osql_error cx_sy_sql_unsupported_feature
            cx_sy_open_sql_db cx_sy_open_sql_error cx_sy_sql_error cx_static_check INTO DATA(lo_exception).
        ex_result = me->mc_msg_typ_error.
    ENDTRY.

  ENDMETHOD.


  METHOD data_element_exists.

    TRY.
        cl_abap_typedescr=>describe_by_name( EXPORTING p_name          = im_data_element
                                             RECEIVING p_descr_ref     = DATA(lo_descr)
                                             EXCEPTIONS type_not_found = 1 ).

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
