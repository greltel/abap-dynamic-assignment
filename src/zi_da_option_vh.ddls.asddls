@EndUserText.label: 'Value Help for Option'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DA_OPTION_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity ZI_DA_OPTION_VH
{
      @EndUserText.label: 'Option'
      @EndUserText.quickInfo: 'Comparison operator'
      @ObjectModel.text.element: [ 'options_descr' ]
  key options       : zde_da_opt;

      @EndUserText.label: 'Option Description'
      @EndUserText.quickInfo: 'Description of the comparison operator'
      @Semantics.text: true
      options_descr : abap.char(60);
}
