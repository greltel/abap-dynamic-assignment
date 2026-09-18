"! <p class="shorttext synchronized" lang="EN">Exception Class for Dynamic Assignment</p>
"! Raised by the framework when a variant cannot be read, checked or written.
"! <p>Every message is a T100 message of the class <em>ZDA</em>, so that the
"! same exception object serves the API caller and, through
"! {@link IF_ABAP_BEHV_MESSAGE}, the RAP behavior pool.</p>
CLASS zcx_da_variants DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_abap_behv_message.

    CONSTANTS message_class TYPE symsgid VALUE 'ZDA' ##NO_TEXT.

    CONSTANTS:
      BEGIN OF conversion_failed,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '001',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF conversion_failed.

    CONSTANTS:
      BEGIN OF rtts_failed,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '002',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF rtts_failed.

    CONSTANTS:
      BEGIN OF no_active_variant,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '003',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF no_active_variant.

    CONSTANTS:
      BEGIN OF database_error,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '004',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF database_error.

    CONSTANTS:
      BEGIN OF invalid_data_element,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '005',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF invalid_data_element.

    CONSTANTS:
      BEGIN OF invalid_mapping_element,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '006',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF invalid_mapping_element.

    CONSTANTS:
      BEGIN OF write_failed,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '009',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF write_failed.

    CONSTANTS:
      BEGIN OF write_error,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '010',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF write_error.

    CONSTANTS:
      BEGIN OF table_not_allowed,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '011',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF table_not_allowed.

    CONSTANTS:
      BEGIN OF inconsistent_elements,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '012',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF inconsistent_elements.

    CONSTANTS:
      BEGIN OF high_value_missing,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '013',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF high_value_missing.

    CONSTANTS:
      BEGIN OF inconsistent_mapping_elements,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '014',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF inconsistent_mapping_elements.

    CONSTANTS:
      BEGIN OF counter_exhausted,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '015',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF counter_exhausted.

    CONSTANTS:
      BEGIN OF counter_not_secured,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '016',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF counter_not_secured.

    CONSTANTS:
      BEGIN OF parameter_missing,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '017',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF parameter_missing.

    CONSTANTS:
      BEGIN OF value_missing,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '018',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF value_missing.

    CONSTANTS:
      BEGIN OF high_value_not_allowed,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '019',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF high_value_not_allowed.

    CONSTANTS:
      BEGIN OF value_not_convertible,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '020',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF value_not_convertible.

    CONSTANTS:
      BEGIN OF value_does_not_fit,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '021',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF value_does_not_fit.

    CONSTANTS:
      BEGIN OF invalid_date,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '022',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF invalid_date.

    CONSTANTS:
      BEGIN OF invalid_time,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '023',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF invalid_time.

    CONSTANTS:
      BEGIN OF packages_missing,
        msgid TYPE symsgid      VALUE message_class,
        msgno TYPE symsgno      VALUE '024',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV3',
        attr4 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV4',
      END OF packages_missing.

    "! Creates the exception for one T100 message of the class ZDA.
    "! <p>The message variables are converted to the 50 characters a message
    "! variable holds; longer texts are cut, which is the T100 contract.</p>
    "! @parameter textid   | Message, one of the constants of this class
    "! @parameter previous | Original exception, kept for the exception chain
    "! @parameter severity | Severity when the message reaches the RAP framework
    "! @parameter msgv1    | Message variable &amp;1
    "! @parameter msgv2    | Message variable &amp;2
    "! @parameter msgv3    | Message variable &amp;3
    "! @parameter msgv4    | Message variable &amp;4
    METHODS constructor
      IMPORTING textid   LIKE if_t100_message=>t100key OPTIONAL
                previous LIKE previous                 OPTIONAL
                severity TYPE if_abap_behv_message=>t_severity DEFAULT if_abap_behv_message=>severity-error
                msgv1    TYPE csequence OPTIONAL
                msgv2    TYPE csequence OPTIONAL
                msgv3    TYPE csequence OPTIONAL
                msgv4    TYPE csequence OPTIONAL.

ENDCLASS.



CLASS zcx_da_variants IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor( previous = previous ).

    CLEAR me->textid.
    if_t100_message~t100key = COND #( WHEN textid IS INITIAL
                                      THEN if_t100_message=>default_textid
                                      ELSE textid ).

    if_abap_behv_message~m_severity = severity.

    if_t100_dyn_msg~msgv1 = msgv1.
    if_t100_dyn_msg~msgv2 = msgv2.
    if_t100_dyn_msg~msgv3 = msgv3.
    if_t100_dyn_msg~msgv4 = msgv4.

  ENDMETHOD.


ENDCLASS.
