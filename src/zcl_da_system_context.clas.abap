"! <p class="shorttext synchronized" lang="EN">System context of the running session</p>
"! Production implementation of {@link ZIF_DA_SYSTEM_CONTEXT}. The only class of
"! the framework that reads the user and the clock of the system.
CLASS zcl_da_system_context DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES zif_da_system_context.

ENDCLASS.



CLASS zcl_da_system_context IMPLEMENTATION.


  METHOD zif_da_system_context~user_name.

    result = cl_abap_context_info=>get_user_technical_name( ).

  ENDMETHOD.


  METHOD zif_da_system_context~time_stamp.

    GET TIME STAMP FIELD result.

  ENDMETHOD.


  METHOD zif_da_system_context~current_date.

    result = cl_abap_context_info=>get_system_date( ).

  ENDMETHOD.


  METHOD zif_da_system_context~current_time.

    result = cl_abap_context_info=>get_system_time( ).

  ENDMETHOD.


ENDCLASS.
