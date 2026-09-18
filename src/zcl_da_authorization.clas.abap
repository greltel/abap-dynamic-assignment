"! <p class="shorttext synchronized" lang="EN">Authorization check on ZDA_VAR</p>
"! Production implementation of {@link ZIF_DA_AUTHORIZATION}, backed by the
"! authorization object <em>ZDA_VAR</em>.
CLASS zcl_da_authorization DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_da_authorization.

ENDCLASS.



CLASS zcl_da_authorization IMPLEMENTATION.


  METHOD zif_da_authorization~is_allowed.

    AUTHORITY-CHECK OBJECT 'ZDA_VAR'
      ID 'ACTVT'    FIELD activity
      ID 'ZDA_PROG' DUMMY.

    result = xsdbool( sy-subrc = 0 ).

  ENDMETHOD.


  METHOD zif_da_authorization~is_allowed_for.

    AUTHORITY-CHECK OBJECT 'ZDA_VAR'
      ID 'ACTVT'    FIELD activity
      ID 'ZDA_PROG' FIELD program_name.

    result = xsdbool( sy-subrc = 0 ).

  ENDMETHOD.


ENDCLASS.
