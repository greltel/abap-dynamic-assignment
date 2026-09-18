*"* use this source file for your ABAP unit test classes

"! Authorization double: allows or denies every activity, as the test decides,
"! so that no test depends on the PFCG roles of whoever runs it.
CLASS ltd_authorization DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_da_authorization.

    "! Refuses the activity from now on; every other one stays allowed.
    "! @parameter activity | Activity to refuse
    METHODS deny
      IMPORTING activity TYPE zif_da_authorization=>ty_activity.

  PRIVATE SECTION.
    DATA denied TYPE STANDARD TABLE OF zif_da_authorization=>ty_activity WITH EMPTY KEY.

ENDCLASS.


CLASS ltd_authorization IMPLEMENTATION.
  METHOD deny.
    INSERT activity INTO TABLE denied.
  ENDMETHOD.

  METHOD zif_da_authorization~is_allowed.
    result = xsdbool( NOT line_exists( denied[ table_line = activity ] ) ).
  ENDMETHOD.

  METHOD zif_da_authorization~is_allowed_for.
    result = zif_da_authorization~is_allowed( activity ).
  ENDMETHOD.
ENDCLASS.


"! Covers the early numbering of {@link ZBP_R_DA_VARIANTS}.
CLASS ltc_numbering DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    TYPES ty_drafts TYPE STANDARD TABLE OF ztda_variants_d WITH EMPTY KEY.

    METHODS insert_draft
      IMPORTING parameter_id TYPE ztda_variants-parameterid
                counter      TYPE ztda_variants-counter.

    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    CONSTANTS test_program    TYPE ztda_variants-progname    VALUE 'TEST_PROG' ##NO_TEXT.
    CONSTANTS test_parameter  TYPE ztda_variants-parameterid VALUE 'UNIT_TEST' ##NO_TEXT.
    CONSTANTS other_parameter TYPE ztda_variants-parameterid VALUE 'OTHER'     ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    "! The first variant of a parameter gets counter 00001.
    METHODS given_empty_then_counter_one FOR TESTING RAISING cx_static_check.
    "! Numbering continues after the highest stored counter.
    METHODS given_stored_then_next_ctr   FOR TESTING RAISING cx_static_check.
    "! Regression for two entities of one request sharing a counter.
    METHODS given_two_new_then_uniq_ctr  FOR TESTING RAISING cx_static_check.
    "! Each parameter keeps its own counter sequence.
    METHODS given_two_keys_then_own_ctr  FOR TESTING RAISING cx_static_check.
    "! A draft that is not yet activated must still block its counter.
    METHODS given_draft_then_next_ctr    FOR TESTING RAISING cx_static_check.
    "! An exhausted key range must be reported, not wrapped around to 00000.
    METHODS given_counter_full_then_fail FOR TESTING RAISING cx_static_check.

    METHODS insert_variant
      IMPORTING parameter_id TYPE ztda_variants-parameterid
                counter      TYPE ztda_variants-counter.

ENDCLASS.


CLASS ltc_numbering IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZTDA_VARIANTS' )
                                                                                     ( 'ZTDA_VARIANTS_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    lcl_variants_factory=>inject_authorization( NEW ltd_authorization( ) ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
    lcl_variants_factory=>inject_authorization( VALUE #( ) ).
  ENDMETHOD.

  METHOD given_empty_then_counter_one.
    " when
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( ( %cid        = 'C1'
                           progname    = test_program
                           parameterid = test_parameter
                           value       = 'A' ) )
           MAPPED DATA(mapped)
           FAILED DATA(failed).

    " then
    cl_abap_unit_assert=>assert_initial( act = failed
                                         msg = 'Creating the first variant must not fail' ).

    cl_abap_unit_assert=>assert_equals( exp = '00001'
                                        act = mapped-variants[ %cid = 'C1' ]-counter
                                        msg = 'The first variant of a parameter must get counter 00001' ).
  ENDMETHOD.

  METHOD given_stored_then_next_ctr.
    " given
    insert_variant( parameter_id = test_parameter
                    counter      = '00007' ).

    " when
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( ( %cid        = 'C1'
                           progname    = test_program
                           parameterid = test_parameter
                           value       = 'B' ) )
           MAPPED DATA(mapped).

    " then
    cl_abap_unit_assert=>assert_equals( exp = '00008'
                                        act = mapped-variants[ %cid = 'C1' ]-counter
                                        msg = 'Numbering must continue after the highest stored counter' ).
  ENDMETHOD.

  METHOD given_two_new_then_uniq_ctr.
    " when - two entities for the same key inside one request
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( progname    = test_program
                         parameterid = test_parameter
                         ( %cid  = 'C1'
                           value = 'A' )
                         ( %cid  = 'C2'
                           value = 'B' ) )
           MAPPED DATA(mapped)
           FAILED DATA(failed).

    " then
    cl_abap_unit_assert=>assert_initial( act = failed
                                         msg = 'Creating two variants for one key must not fail' ).

    cl_abap_unit_assert=>assert_differs( exp = mapped-variants[ %cid = 'C1' ]-counter
                                         act = mapped-variants[ %cid = 'C2' ]-counter
                                         msg = 'Each entity of one request must get its own counter' ).
  ENDMETHOD.

  METHOD given_two_keys_then_own_ctr.
    " given - one parameter already carries rows, the other does not
    insert_variant( parameter_id = test_parameter
                    counter      = '00042' ).

    " when
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( progname = test_program
                         ( %cid        = 'C1'
                           parameterid = test_parameter
                           value       = 'A' )
                         ( %cid        = 'C2'
                           parameterid = other_parameter
                           value       = 'B' ) )
           MAPPED DATA(mapped).

    " then
    cl_abap_unit_assert=>assert_equals( exp = '00001'
                                        act = mapped-variants[ %cid = 'C2' ]-counter
                                        msg = 'An untouched parameter must start its own sequence at 00001' ).
  ENDMETHOD.

  METHOD given_draft_then_next_ctr.
    " given - a draft that occupies counter 00001 but was never activated
    insert_draft( parameter_id = test_parameter
                  counter      = '00001' ).

    " when
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( ( %cid        = 'C1'
                           progname    = test_program
                           parameterid = test_parameter
                           value       = 'B' ) )
           MAPPED DATA(mapped).

    " then
    cl_abap_unit_assert=>assert_equals( exp = '00002'
                                        act = mapped-variants[ %cid = 'C1' ]-counter
                                        msg = 'A pending draft must not hand its counter to the next variant' ).
  ENDMETHOD.

  METHOD given_counter_full_then_fail.
    " given - the last counter the NUMC(5) key can hold is already allocated
    insert_variant( parameter_id = test_parameter
                    counter      = '99999' ).

    " when
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( ( %cid        = 'C1'
                           progname    = test_program
                           parameterid = test_parameter
                           value       = 'A' ) )
           MAPPED DATA(mapped)
           FAILED DATA(failed).

    " then
    cl_abap_unit_assert=>assert_not_initial( act = failed-variants
                                             msg = 'A create that cannot be numbered must be reported as failed' ).

    cl_abap_unit_assert=>assert_initial( act = mapped-variants
                                         msg = 'The counter must never wrap around to 00000' ).
  ENDMETHOD.

  METHOD insert_draft.
    sql_environment->insert_test_data( VALUE ty_drafts( ( progname    = test_program
                                                          parameterid = parameter_id
                                                          counter     = counter ) ) ).
  ENDMETHOD.

  METHOD insert_variant.
    sql_environment->insert_test_data( VALUE zcl_da_variants=>ty_variants( ( progname    = test_program
                                                                             parameterid = parameter_id
                                                                             counter     = counter
                                                                             is_active   = abap_true
                                                                             sign        = 'I'
                                                                             opt         = 'EQ'
                                                                             value       = 'X' ) ) ).
  ENDMETHOD.
ENDCLASS.


"! Covers the determination that fills the defaults of a new variant.
CLASS ltc_defaults DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    CONSTANTS test_program   TYPE ztda_variants-progname    VALUE 'TEST_PROG' ##NO_TEXT.
    CONSTANTS test_parameter TYPE ztda_variants-parameterid VALUE 'UNIT_TEST' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    "! A new variant must be active without the user ticking the box.
    METHODS given_new_then_active       FOR TESTING RAISING cx_static_check.
    "! A new variant must default to sign include.
    METHODS given_new_then_sign_include FOR TESTING RAISING cx_static_check.
    "! A new variant must default to option equal.
    METHODS given_new_then_option_equal FOR TESTING RAISING cx_static_check.
    "! A sign supplied by the user must survive the determination.
    METHODS given_sign_then_sign_kept   FOR TESTING RAISING cx_static_check.
    "! An option supplied by the user must survive the determination.
    METHODS given_option_then_opt_kept  FOR TESTING RAISING cx_static_check.

    METHODS create_variant
      IMPORTING !sign         TYPE zde_da_sign OPTIONAL
                !option       TYPE zde_da_opt  OPTIONAL
      RETURNING VALUE(result) TYPE zr_da_variants.

ENDCLASS.


CLASS ltc_defaults IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZTDA_VARIANTS' )
                                                                                     ( 'ZTDA_VARIANTS_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    lcl_variants_factory=>inject_authorization( NEW ltd_authorization( ) ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
    lcl_variants_factory=>inject_authorization( VALUE #( ) ).
  ENDMETHOD.

  METHOD given_new_then_active.
    cl_abap_unit_assert=>assert_true( act = create_variant( )-isactive
                                      msg = 'A new variant must be active without user interaction' ).
  ENDMETHOD.

  METHOD given_new_then_sign_include.
    cl_abap_unit_assert=>assert_equals( exp = 'I'
                                        act = create_variant( )-sign
                                        msg = 'A new variant must default to sign include' ).
  ENDMETHOD.

  METHOD given_new_then_option_equal.
    cl_abap_unit_assert=>assert_equals( exp = 'EQ'
                                        act = create_variant( )-opt
                                        msg = 'A new variant must default to option equal' ).
  ENDMETHOD.

  METHOD given_sign_then_sign_kept.
    cl_abap_unit_assert=>assert_equals( exp = 'E'
                                        act = create_variant( sign = 'E' )-sign
                                        msg = 'A sign supplied by the user must not be overwritten' ).
  ENDMETHOD.

  METHOD given_option_then_opt_kept.
    cl_abap_unit_assert=>assert_equals( exp = 'NE'
                                        act = create_variant( option = 'NE' )-opt
                                        msg = 'An option supplied by the user must not be overwritten' ).
  ENDMETHOD.

  METHOD create_variant.
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value sign opt )
           WITH VALUE #( ( %cid        = 'C1'
                           progname    = test_program
                           parameterid = test_parameter
                           Value       = 'A'
                           Sign        = sign
                           Opt         = option ) )
           MAPPED DATA(mapped).

    READ ENTITIES OF zr_da_variants
         ENTITY variants
         FIELDS ( progname parameterid counter isactive sign opt )
         WITH VALUE #( ( %tky = mapped-variants[ 1 ]-%tky ) )
         RESULT DATA(variants).

    result = CORRESPONDING #( variants[ 1 ] ).
  ENDMETHOD.
ENDCLASS.


"! Covers the two save time validations, triggered through the draft
"! determine action <em>Prepare</em> so that no test has to commit.
CLASS ltc_validations DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    DATA next_id TYPE i.

    CONSTANTS test_program  TYPE ztda_variants-progname     VALUE 'TEST_PROG'    ##NO_TEXT.
    CONSTANTS elementary_el TYPE ztda_variants-data_element VALUE 'ZDE_DA_SIGN'  ##NO_TEXT.
    CONSTANTS structured_el TYPE ztda_variants-data_element VALUE 'ZTDA_VARIANTS' ##NO_TEXT.
    CONSTANTS unknown_el    TYPE ztda_variants-data_element VALUE 'ZDE_NO_SUCH'  ##NO_TEXT.
    CONSTANTS numeric_el    TYPE ztda_variants-data_element VALUE 'ZDE_DA_COUNTER' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    "! BT without an upper bound must be rejected.
    METHODS given_bt_no_high_then_fail    FOR TESTING RAISING cx_static_check.
    "! NB without an upper bound must be rejected.
    METHODS given_nb_no_high_then_fail    FOR TESTING RAISING cx_static_check.
    "! BT with an upper bound must pass.
    METHODS given_bt_with_high_then_ok    FOR TESTING RAISING cx_static_check.
    "! An upper bound outside BT and NB must be rejected.
    METHODS given_eq_with_high_then_fail  FOR TESTING RAISING cx_static_check.
    "! A rejected variant must carry a message for the user.
    METHODS given_failure_then_message    FOR TESTING RAISING cx_static_check.
    "! An unknown data element must be rejected.
    METHODS given_bad_element_then_fail   FOR TESTING RAISING cx_static_check.
    "! A structured type must be rejected as data element.
    METHODS given_struct_el_then_fail     FOR TESTING RAISING cx_static_check.
    "! An unknown mapping data element must be rejected.
    METHODS given_bad_map_el_then_fail    FOR TESTING RAISING cx_static_check.
    "! An existing elementary data element must pass.
    METHODS given_good_element_then_ok    FOR TESTING RAISING cx_static_check.
    "! A variant without any data element must pass.
    METHODS given_no_element_then_ok      FOR TESTING RAISING cx_static_check.

    " ----- the value has to fit the element it is configured with -----------
    "! Text in a NUMC element is filtered to zeros and must be rejected.
    METHODS given_text_in_numc_then_fail  FOR TESTING RAISING cx_static_check.
    "! A value longer than its CHAR element is truncated and must be rejected.
    METHODS given_long_value_then_fail    FOR TESTING RAISING cx_static_check.
    "! The mapping value must fit its own mapping data element.
    METHODS given_bad_map_value_then_fail FOR TESTING RAISING cx_static_check.
    "! A value that fits its element exactly must still pass.
    METHODS given_fitting_value_then_ok   FOR TESTING RAISING cx_static_check.

    METHODS save_variant
      IMPORTING !value          TYPE ztda_variants-value           DEFAULT 'A'
                high_value      TYPE ztda_variants-high_value      OPTIONAL
                !option         TYPE zde_da_opt                    DEFAULT 'EQ'
                data_element    TYPE ztda_variants-data_element    OPTIONAL
                mapping_value   TYPE ztda_variants-mapping_value   OPTIONAL
                mapping_data_el TYPE ztda_variants-mapping_data_el OPTIONAL
      EXPORTING has_failure     TYPE abap_boolean
                has_message     TYPE abap_boolean.

ENDCLASS.


CLASS ltc_validations IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZTDA_VARIANTS' )
                                                                                     ( 'ZTDA_VARIANTS_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    lcl_variants_factory=>inject_authorization( NEW ltd_authorization( ) ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
    lcl_variants_factory=>inject_authorization( VALUE #( ) ).
  ENDMETHOD.

  METHOD given_bt_no_high_then_fail.
    save_variant( EXPORTING option      = 'BT'
                  IMPORTING has_failure = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'BT without an upper bound must be rejected' ).
  ENDMETHOD.

  METHOD given_nb_no_high_then_fail.
    save_variant( EXPORTING option      = 'NB'
                  IMPORTING has_failure = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'NB without an upper bound must be rejected' ).
  ENDMETHOD.

  METHOD given_bt_with_high_then_ok.
    save_variant( EXPORTING option      = 'BT'
                            high_value  = '9999'
                  IMPORTING has_failure = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_false( act = has_failure
                                       msg = 'BT with an upper bound must pass' ).
  ENDMETHOD.

  METHOD given_eq_with_high_then_fail.
    save_variant( EXPORTING option      = 'EQ'
                            high_value  = '9999'
                  IMPORTING has_failure = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'An upper bound is only allowed for BT and NB' ).
  ENDMETHOD.

  METHOD given_failure_then_message.
    save_variant( EXPORTING option      = 'BT'
                  IMPORTING has_message = DATA(has_message) ).

    cl_abap_unit_assert=>assert_true( act = has_message
                                      msg = 'A rejected variant must explain itself to the user' ).
  ENDMETHOD.

  METHOD given_bad_element_then_fail.
    save_variant( EXPORTING data_element = unknown_el
                  IMPORTING has_failure  = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'An unknown data element must be rejected' ).
  ENDMETHOD.

  METHOD given_struct_el_then_fail.
    save_variant( EXPORTING data_element = structured_el
                  IMPORTING has_failure  = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'A structured type must not be accepted as data element' ).
  ENDMETHOD.

  METHOD given_bad_map_el_then_fail.
    save_variant( EXPORTING mapping_value   = 'X'
                            mapping_data_el = unknown_el
                  IMPORTING has_failure     = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'An unknown mapping data element must be rejected' ).
  ENDMETHOD.

  METHOD given_good_element_then_ok.
    save_variant( EXPORTING data_element = elementary_el
                  IMPORTING has_failure  = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_false( act = has_failure
                                       msg = 'An existing elementary data element must pass' ).
  ENDMETHOD.

  METHOD given_no_element_then_ok.
    save_variant( IMPORTING has_failure = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_false( act = has_failure
                                       msg = 'A variant without a data element must pass' ).
  ENDMETHOD.

  METHOD given_text_in_numc_then_fail.
    save_variant( EXPORTING value        = 'ABC'
                            data_element = numeric_el
                  IMPORTING has_failure  = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'Text in a NUMC element is filtered to zeros and must be rejected' ).
  ENDMETHOD.

  METHOD given_long_value_then_fail.
    save_variant( EXPORTING value        = 'IE'
                            data_element = elementary_el
                  IMPORTING has_failure  = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'A value longer than its CHAR element is truncated and must be rejected' ).
  ENDMETHOD.

  METHOD given_bad_map_value_then_fail.
    save_variant( EXPORTING mapping_value   = 'LONG'
                            mapping_data_el = elementary_el
                  IMPORTING has_failure     = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_true( act = has_failure
                                      msg = 'The mapping value must fit its own mapping data element' ).
  ENDMETHOD.

  METHOD given_fitting_value_then_ok.
    save_variant( EXPORTING value        = 'I'
                            data_element = elementary_el
                  IMPORTING has_failure  = DATA(has_failure) ).

    cl_abap_unit_assert=>assert_false( act = has_failure
                                       msg = 'A value that fits its element exactly must pass' ).
  ENDMETHOD.

  METHOD save_variant.
    CLEAR: has_failure,
           has_message.

    " every call uses its own parameter so that the tests never share a key
    next_id += 1.
    DATA(parameter) = CONV ztda_variants-parameterid( |UNIT_TEST_{ next_id }| ).

    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value opt highvalue
                           dataelement mappingvalue mappingdataelement )
           WITH VALUE #( ( %cid               = 'C1'
                           progname           = test_program
                           parameterid        = parameter
                           value              = value
                           opt                = option
                           highvalue          = high_value
                           dataelement        = data_element
                           mappingvalue       = mapping_value
                           mappingdataelement = mapping_data_el ) ).

    " on save validations only run during the save sequence
    COMMIT ENTITIES RESPONSE OF zr_da_variants
           FAILED DATA(failed)
           REPORTED DATA(reported).

    has_failure = xsdbool( failed-variants IS NOT INITIAL ).

    LOOP AT reported-variants INTO DATA(reported_line).
      IF reported_line-%msg IS BOUND.
        has_message = abap_true.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


"! Covers the global and instance authorization handlers.
"! <p>The handlers ask {@link ZIF_DA_AUTHORIZATION} through the local factory,
"! so the double decides what is allowed and the tests run identically for
"! every user.</p>
CLASS ltc_authorizations DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    CLASS-DATA sql_environment TYPE REF TO if_osql_test_environment.

    DATA authorization TYPE REF TO ltd_authorization.

    CONSTANTS test_program   TYPE ztda_variants-progname    VALUE 'TEST_PROG' ##NO_TEXT.
    CONSTANTS test_parameter TYPE ztda_variants-parameterid VALUE 'UNIT_TEST' ##NO_TEXT.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    METHODS setup.
    METHODS teardown.

    "! Without create authorization the create request must fail as unauthorized.
    METHODS given_no_create_auth_then_fail FOR TESTING RAISING cx_static_check.
    "! With create authorization the create request must go through.
    METHODS given_create_auth_then_ok      FOR TESTING RAISING cx_static_check.
    "! Without change authorization an update of a draft must fail.
    METHODS given_no_change_auth_then_fail FOR TESTING RAISING cx_static_check.
    "! With change authorization an update of a draft must go through.
    METHODS given_change_auth_then_ok      FOR TESTING RAISING cx_static_check.

    METHODS create_variant
      RETURNING VALUE(result) LIKE if_abap_behv=>cause-unauthorized.

    METHODS update_draft_variant
      RETURNING VALUE(result) LIKE if_abap_behv=>cause-unauthorized.

ENDCLASS.


CLASS ltc_authorizations IMPLEMENTATION.
  METHOD class_setup.
    sql_environment = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZTDA_VARIANTS' )
                                                                                     ( 'ZTDA_VARIANTS_D' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_environment->clear_doubles( ).
    authorization = NEW ltd_authorization( ).
    lcl_variants_factory=>inject_authorization( authorization ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
    lcl_variants_factory=>inject_authorization( VALUE #( ) ).
  ENDMETHOD.

  METHOD given_no_create_auth_then_fail.
    " given
    authorization->deny( zif_da_authorization=>activity-create ).

    " then
    cl_abap_unit_assert=>assert_equals( exp = if_abap_behv=>cause-unauthorized
                                        act = create_variant( )
                                        msg = `A create without authorization must fail as unauthorized` ).
  ENDMETHOD.

  METHOD given_create_auth_then_ok.
    cl_abap_unit_assert=>assert_initial( act = create_variant( )
                                         msg = `A create with authorization must not fail` ).
  ENDMETHOD.

  METHOD given_no_change_auth_then_fail.
    " given
    authorization->deny( zif_da_authorization=>activity-change ).

    " then
    cl_abap_unit_assert=>assert_equals( exp = if_abap_behv=>cause-unauthorized
                                        act = update_draft_variant( )
                                        msg = `An update without change authorization must fail as unauthorized` ).
  ENDMETHOD.

  METHOD given_change_auth_then_ok.
    cl_abap_unit_assert=>assert_initial( act = update_draft_variant( )
                                         msg = `An update with change authorization must not fail` ).
  ENDMETHOD.

  METHOD create_variant.
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( ( %cid        = 'C1'
                           progname    = test_program
                           parameterid = test_parameter
                           Value       = 'A' ) )
           FAILED DATA(failed).

    " initial when nothing failed, otherwise the cause of the first failure
    result = VALUE #( failed-variants[ 1 ]-%fail-cause OPTIONAL ).
  ENDMETHOD.

  METHOD update_draft_variant.
    " an active row would be read through the CDS view, which the OSQL double does not
    " cover, so the update runs on a draft that lives in the transactional buffer
    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           CREATE FIELDS ( progname parameterid value )
           WITH VALUE #( ( %cid        = 'C1'
                           %is_draft   = if_abap_behv=>mk-on
                           progname    = test_program
                           parameterid = test_parameter
                           Value       = 'X' ) )
           MAPPED DATA(mapped).

    MODIFY ENTITIES OF zr_da_variants
           ENTITY variants
           UPDATE FIELDS ( description )
           WITH VALUE #( ( %tky        = mapped-variants[ 1 ]-%tky
                           description = 'changed' ) )
           FAILED DATA(failed).

    result = VALUE #( failed-variants[ 1 ]-%fail-cause OPTIONAL ).
  ENDMETHOD.
ENDCLASS.
