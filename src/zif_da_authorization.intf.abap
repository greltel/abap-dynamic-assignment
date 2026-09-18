"! <p class="shorttext synchronized" lang="EN">Authorization check of the framework</p>
"! Answers whether the current user may maintain variants.
"! <p>The behavior pool asks this interface instead of running
"! <em>AUTHORITY-CHECK</em> itself, so that unit tests decide the answer
"! instead of the PFCG roles of whoever runs them.</p>
INTERFACE zif_da_authorization
  PUBLIC.

  "! Activity of the authorization object ZDA_VAR.
  TYPES ty_activity TYPE c LENGTH 2.

  "! Activities the framework checks.
  CONSTANTS:
    BEGIN OF activity,
      create  TYPE ty_activity VALUE '01',
      change  TYPE ty_activity VALUE '02',
      display TYPE ty_activity VALUE '03',
      delete  TYPE ty_activity VALUE '06',
    END OF activity.

  "! Answers whether the user may perform the activity on some program scope.
  "! @parameter activity | Activity to check
  "! @parameter result   | <em>abap_true</em> when the activity is allowed
  METHODS is_allowed
    IMPORTING activity      TYPE ty_activity
    RETURNING VALUE(result) TYPE abap_boolean.

  "! Answers whether the user may perform the activity on one program scope.
  "! @parameter activity     | Activity to check
  "! @parameter program_name | Program scope of the variant
  "! @parameter result       | <em>abap_true</em> when the activity is allowed
  METHODS is_allowed_for
    IMPORTING activity      TYPE ty_activity
              program_name  TYPE zif_da_variants=>ty_progname
    RETURNING VALUE(result) TYPE abap_boolean.

ENDINTERFACE.
