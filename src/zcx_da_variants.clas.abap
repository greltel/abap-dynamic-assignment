"! <p class="shorttext synchronized" lang="EN">Exception Class for Dynamic Assignment</p>
"! Raised by {@link ZCL_DA_VARIANTS} when a variant cannot be read or written.
"! <p>Carries a free message text so that the cause survives all the way to the
"! caller. returns that text when it is filled,
"! and falls back to the T100 message otherwise.</p>
CLASS zcx_da_variants DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    "! Creates the exception with either a T100 key or a free message text.
    "! @parameter textid   | T100 key, defaults to the generic text id
    "! @parameter previous | Original exception, kept for the exception chain
    "! @parameter text     | Free message text
    METHODS constructor
      IMPORTING textid   LIKE if_t100_message=>t100key OPTIONAL
                previous LIKE previous                 OPTIONAL
                text     TYPE string                   OPTIONAL.

    METHODS if_message~get_text REDEFINITION.

  PRIVATE SECTION.

    DATA message_text TYPE string.

ENDCLASS.



CLASS zcx_da_variants IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor( previous = previous ).

    me->message_text = text.

    CLEAR me->textid.
    if_t100_message~t100key = COND #( WHEN textid IS INITIAL
                                      THEN if_t100_message=>default_textid
                                      ELSE textid ).

  ENDMETHOD.


  METHOD if_message~get_text.

    result = COND #( WHEN me->message_text IS NOT INITIAL
                     THEN me->message_text
                     ELSE super->if_message~get_text( ) ).

  ENDMETHOD.


ENDCLASS.

