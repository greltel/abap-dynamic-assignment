@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Value Help for Parameter ID'

define view entity ZI_DA_PARAMID_VH
  as select from zda_variants

{
      @EndUserText.label: 'Program Name'
  key progname    as Progname,     // <-- Προσθήκη

      @EndUserText.label: 'Parameter ID'
  key parameterid as Parameterid
}

group by progname,
         parameterid
