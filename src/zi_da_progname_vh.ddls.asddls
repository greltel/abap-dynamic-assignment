@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Program Name'
define view entity ZI_DA_PROGNAME_VH
  as select from zda_variants
{
      @EndUserText.label: 'Program Name'
  key progname as Progname
}
group by
  progname
