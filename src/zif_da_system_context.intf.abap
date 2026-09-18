"! <p class="shorttext synchronized" lang="EN">System context</p>
"! The one place that knows who the current user is and what time it is.
"! <p>Injected into everything that stamps rows or generates descriptions, so that
"! tests run against a fixed user and a fixed clock instead of the system.</p>
INTERFACE zif_da_system_context
  PUBLIC.

  "! User name in the format the administrative fields store.
  TYPES ty_user       TYPE ztda_variants-created_by.
  "! Point in time in the format the administrative fields store.
  TYPES ty_time_stamp TYPE ztda_variants-created_at.

  "! Technical name of the current user.
  "! @parameter result | User name, initial when no user context exists
  METHODS user_name
    RETURNING VALUE(result) TYPE ty_user.

  "! Current point in time.
  "! @parameter result | UTC time stamp, as the administrative fields store it
  METHODS time_stamp
    RETURNING VALUE(result) TYPE ty_time_stamp.

  "! Current system date.
  "! @parameter result | Date in the system time zone
  METHODS current_date
    RETURNING VALUE(result) TYPE d.

  "! Current system time.
  "! @parameter result | Time in the system time zone
  METHODS current_time
    RETURNING VALUE(result) TYPE t.

ENDINTERFACE.
