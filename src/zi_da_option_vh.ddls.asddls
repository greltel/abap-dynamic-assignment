@EndUserText.label: 'Value Help for Option'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DA_OPTION_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity ZI_DA_OPTION_VH
{
      @EndUserText.label: 'Option'
      @EndUserText.quickInfo: 'Comparison operator'
  key options       : zde_da_opt;

      @EndUserText.label: 'Option Description'
      @EndUserText.quickInfo: 'Description of the comparison operator'
      options_descr : abap.char(60);
}
