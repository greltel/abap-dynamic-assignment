@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Value Help for Parameter ID'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #C, sizeCategory: #S, dataClass: #CUSTOMIZING }

@Search.searchable: true

define view entity ZI_DA_PARAMID_VH
  as select from ZI_DA_VARIANTS
{
      @EndUserText.label: 'Program Name'
      @Search.defaultSearchElement: true
  key Progname,

      @EndUserText.label: 'Parameter ID'
      @Search.defaultSearchElement: true
  key Parameterid
}
group by
  Progname,
  Parameterid
