"! <p class="shorttext synchronized" lang="EN">Persistence of dynamic assignment variants</p>
"! Every database access of the framework goes through this interface, so that
"! the configuration table can be exchanged and the rest of the framework can
"! be tested against a double.
INTERFACE zif_da_repository
  PUBLIC.

  "! Creation stamp of a row that is already stored.
  TYPES: BEGIN OF ty_creation_info,
           created_by TYPE ztda_variants-created_by,
           created_at TYPE ztda_variants-created_at,
         END OF ty_creation_info.

  "! Highest counter in use for one program and parameter.
  TYPES: BEGIN OF ty_last_counter,
           progname    TYPE ztda_variants-progname,
           parameterid TYPE ztda_variants-parameterid,
           counter     TYPE ztda_variants-counter,
         END OF ty_last_counter.

  TYPES ty_last_counters TYPE SORTED TABLE OF ty_last_counter
                              WITH UNIQUE KEY progname parameterid.

  "! Keys to look up, duplicates allowed.
  TYPES ty_counter_keys  TYPE STANDARD TABLE OF ty_last_counter WITH EMPTY KEY.

  "! Reads all active variants of one parameter, ordered by counter.
  "! @parameter program_name    | Program scope
  "! @parameter parameter_id    | Parameter to read
  "! @parameter result          | Active variants, may be empty
  "! @raising   zcx_da_variants | The configuration table could not be read
  METHODS read_active_variants
    IMPORTING program_name  TYPE zif_da_variants=>ty_progname
              parameter_id  TYPE zif_da_variants=>ty_parameterid
    RETURNING VALUE(result) TYPE zif_da_variants=>ty_variants
    RAISING   zcx_da_variants.

  "! Reads the highest counter in use for every key, active rows and pending drafts alike.
  "! @parameter keys            | Program and parameter of every key to inspect
  "! @parameter result          | Highest counter per key, absent when nothing is stored
  "! @raising   zcx_da_variants | The configuration table could not be read
  METHODS read_last_counters
    IMPORTING keys          TYPE ty_counter_keys
    RETURNING VALUE(result) TYPE ty_last_counters
    RAISING   zcx_da_variants.

  "! Reads the creation stamp of a stored row.
  "! @parameter row             | Variant row carrying the key to look up
  "! @parameter result          | Stored creation stamp, initial when the row is new
  "! @raising   zcx_da_variants | The configuration table could not be read
  METHODS read_creation_info
    IMPORTING row           TYPE zif_da_variants=>ty_variant
    RETURNING VALUE(result) TYPE ty_creation_info
    RAISING   zcx_da_variants.

  "! Inserts one row without ever replacing a stored one.
  "! @parameter row             | Completed variant row
  "! @parameter result          | <em>abap_false</em> when the key was already taken
  "! @raising   zcx_da_variants | The configuration table could not be written
  METHODS insert_row
    IMPORTING row           TYPE zif_da_variants=>ty_variant
    RETURNING VALUE(result) TYPE abap_boolean
    RAISING   zcx_da_variants.

  "! Replaces one row, or inserts it when the key is new.
  "! @parameter row             | Completed variant row
  "! @raising   zcx_da_variants | The database rejected the row
  METHODS replace_row
    IMPORTING row TYPE zif_da_variants=>ty_variant
    RAISING   zcx_da_variants.

  "! Deletes one row, or every row of a parameter when no counter is given.
  "! @parameter program_name    | Program scope
  "! @parameter parameter_id    | Parameter to delete from
  "! @parameter counter         | Single row to delete, initial for the whole parameter
  "! @parameter result          | Number of rows removed
  "! @raising   zcx_da_variants | The configuration table could not be written
  METHODS delete_rows
    IMPORTING program_name  TYPE zif_da_variants=>ty_progname
              parameter_id  TYPE zif_da_variants=>ty_parameterid
              counter       TYPE zif_da_variants=>ty_counter OPTIONAL
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_da_variants.

ENDINTERFACE.
