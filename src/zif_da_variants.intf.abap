"! <p class="shorttext synchronized" lang="EN">Dynamic assignment variants</p>
"! <h1>Dynamic runtime parameters</h1>
"! <p>Decouples configuration values from code. Values, ranges and mappings are
"! maintained in {@link ZDA_VARIANTS} and materialised at runtime with RTTS, so
"! that no program needs a hardcoded literal.</p>
"! <p>Read with METH:get_variant, write with METH:set_variant.
"! Failures are reported through {@link ZCX_DA_VARIANTS}.</p>
INTERFACE zif_da_variants
  PUBLIC.

  TYPES ty_base_sign TYPE zde_da_sign.
  TYPES ty_base_opt  TYPE zde_da_opt.

  TYPES:
    "! Sign of a range line. Pass these constants instead of literals.
    BEGIN OF ENUM ty_sign BASE TYPE ty_base_sign,
      sign_empty   VALUE IS INITIAL ##NEEDED,
      sign_include VALUE 'I' ##NEEDED,
      sign_exclude VALUE 'E' ##NEEDED,
    END OF ENUM ty_sign.

  TYPES:
    "! Comparison operator of a range line. Pass these constants instead of literals.
    BEGIN OF ENUM ty_opt BASE TYPE ty_base_opt,
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

  TYPES:
    "! Program scope of a variant.
    ty_progname    TYPE zda_variants-progname,
    "! Parameter identifier.
    ty_parameterid TYPE zda_variants-parameterid,
    "! Sequence number inside one program and parameter pair.
    ty_counter     TYPE zda_variants-counter,
    "! Raw variant value as stored in the configuration table.
    ty_value       TYPE zda_variants-value,
    "! Name of a DDIC data element.
    ty_data_el     TYPE zda_variants-data_element,
    "! Free description of a variant.
    ty_description TYPE zda_variants-description,
    "! Name of a configuration table.
    ty_tabname     TYPE c LENGTH 30,
    "! Row type of the configuration table.
    ty_variant     TYPE zda_variants,
    "! Configuration rows, ordered by counter.
    ty_variants    TYPE STANDARD TABLE OF zda_variants WITH EMPTY KEY.

  "! Reads all active variants of a parameter and fills the requested targets.
  "! <p>Only the targets the caller actually supplies are computed. Every value is
  "! written into the caller's own variable, so a <em>RANGE OF matnr</em> comes back
  "! as a real MATNR range with both bounds converted by the DDIC type.</p>
  "!
  "! @parameter parameter_id        | Parameter to read, case insensitive
  "! @parameter program_name        | Program scope, defaults to <em>GLOBAL</em>
  "! @parameter field_value         | Value of the first active variant
  "! @parameter mapping_field_value | Mapping value of the first active variant
  "! @parameter values              | One row per active variant
  "! @parameter mapping_values      | Value and mapping pairs, dynamically typed
  "! @parameter range               | Range table, ready for <em>SELECT ... IN</em>
  "! @raising   zcx_da_variants     | No active variant found, or a conversion failed
  METHODS get_variant
    IMPORTING parameter_id        TYPE ty_parameterid
              program_name        TYPE ty_progname OPTIONAL
    EXPORTING field_value         TYPE any
              mapping_field_value TYPE any
              values              TYPE STANDARD TABLE
              mapping_values      TYPE REF TO data
              range               TYPE STANDARD TABLE
    RAISING   zcx_da_variants.

  "! Creates or replaces one variant row. The caller owns the LUW.
  "! <p>Leave <em>counter</em> initial to append a new row. Pass an existing counter
  "! to replace that row, which makes seed data scripts idempotent. Replacing keeps
  "! the original creator and creation time.</p>
  "! <p>Set <em>commit</em> only from standalone scripts. Never from a RAP handler,
  "! a determination or a validation.</p>
  "!
  "! @parameter parameter_id         | Parameter to write, case insensitive
  "! @parameter program_name         | Program scope, defaults to <em>GLOBAL</em>
  "! @parameter counter              | Existing counter to replace, initial to append
  "! @parameter field_value          | Value, or lower bound of a range line
  "! @parameter high_value           | Upper bound, mandatory for <em>BT</em> and <em>NB</em>
  "! @parameter data_element         | DDIC type of the value, initial for the column type
  "! @parameter mapping_field_value  | Value the variant maps to
  "! @parameter mapping_data_element | DDIC type of the mapping value
  "! @parameter sign                 | Include or exclude, defaults to <em>sign_include</em>
  "! @parameter option               | Comparison operator, defaults to <em>opt_eq</em>
  "! @parameter description          | Free description, generated when left initial
  "! @parameter is_active            | Only active variants are returned by get_variant
  "! @parameter commit               | Commit the LUW, defaults to <em>abap_false</em>
  "! @raising   zcx_da_variants      | Validation failed or the database rejected the row
  METHODS set_variant
    IMPORTING parameter_id         TYPE ty_parameterid
              program_name         TYPE ty_progname    OPTIONAL
              counter              TYPE ty_counter     OPTIONAL
              field_value          TYPE ty_value
              high_value           TYPE ty_value       OPTIONAL
              data_element         TYPE ty_data_el     OPTIONAL
              mapping_field_value  TYPE ty_value       OPTIONAL
              mapping_data_element TYPE ty_data_el     OPTIONAL
              sign                 TYPE ty_sign        OPTIONAL
              option               TYPE ty_opt         OPTIONAL
              description          TYPE ty_description OPTIONAL
              is_active            TYPE abap_boolean   DEFAULT abap_true
              commit               TYPE abap_boolean   DEFAULT abap_false
    RAISING   zcx_da_variants.

  "! Classifies a value against the range lines of a parameter.
  "! <p>Where get_variant( ) answers <em>"which values are in scope"</em>, this answers
  "! <em>"which bucket does X fall into"</em>. Every active row is a rule, evaluated in
  "! counter order, with the operator and the bounds it carries.</p>
  "! <p>The comparison runs in the configured DDIC type, so a <em>BT 9 AND 100</em> on a
  "! numeric element matches 50, which a character comparison would miss. Patterns
  "! (<em>CP</em>, <em>NP</em>) always compare character wise.</p>
  "! <p>The first rule that answers decides. A rule with <em>sign_exclude</em> that answers
  "! stops the search and reports no match, which is how a hole is punched into a
  "! range that otherwise maps as a whole.</p>
  "!
  "! @parameter parameter_id    | Parameter holding the rules, case insensitive
  "! @parameter program_name    | Program scope, defaults to <em>GLOBAL</em>
  "! @parameter input           | Value to classify
  "! @parameter mapping_value   | Mapping value of the rule that matched
  "! @parameter matched         | <em>abap_true</em> when a rule included the input
  "! @raising   zcx_da_variants | The parameter is unknown, or a value does not convert
  METHODS map_value
    IMPORTING parameter_id  TYPE ty_parameterid
              program_name  TYPE ty_progname OPTIONAL
              input         TYPE ty_value
    EXPORTING mapping_value TYPE any
              matched       TYPE abap_boolean
    RAISING   zcx_da_variants.

  "! Removes one variant, or every variant of a parameter. The caller owns the LUW.
  "! <p>Leave <em>counter</em> initial to remove the whole parameter. Deleting rows that
  "! are not there is not an error, so a cleanup script can run twice.</p>
  "!
  "! @parameter parameter_id    | Parameter to remove from, case insensitive
  "! @parameter program_name    | Program scope, defaults to <em>GLOBAL</em>
  "! @parameter counter         | Row to remove, initial for the whole parameter
  "! @parameter commit          | Commit the LUW, defaults to <em>abap_false</em>
  "! @parameter result          | Number of rows that were removed
  "! @raising   zcx_da_variants | No parameter was named, or the database refused
  METHODS delete_variant
    IMPORTING parameter_id  TYPE ty_parameterid
              program_name  TYPE ty_progname  OPTIONAL
              counter       TYPE ty_counter   OPTIONAL
              commit        TYPE abap_boolean DEFAULT abap_false
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_da_variants.

ENDINTERFACE.
