@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Value Help for Program Name'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #C, sizeCategory: #S, dataClass: #CUSTOMIZING }
@ObjectModel.resultSet.sizeCategory: #XS

@Search.searchable: true

define view entity ZI_DA_PROGNAME_VH
  as select from ZI_DA_VARIANTS
{
      @EndUserText.label: 'Program Name'
      @Search.defaultSearchElement: true
  key Progname
}
group by
  Progname
