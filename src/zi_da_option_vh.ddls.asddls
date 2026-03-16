@EndUserText.label: 'City Value Help'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DA_OPTION_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity ZI_DA_OPTION_VH
{
      @EndUserText.label: 'Options'
      @EndUserText.quickInfo: 'Options Name'
  key options      : zde_da_opt;
      @EndUserText.label: 'Options Description'
      @EndUserText.quickInfo: 'Options Description'
      options_descr : abap.char(20);
}
