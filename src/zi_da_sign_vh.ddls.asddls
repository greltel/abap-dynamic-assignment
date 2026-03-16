@EndUserText.label: 'City Value Help'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DA_SIGN_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity ZI_DA_SIGN_VH
{
      @EndUserText.label: 'Sign'
      @EndUserText.quickInfo: 'Sign Name'
  key sign      : zde_da_sign;
      @EndUserText.label: 'Sign Description'
      @EndUserText.quickInfo: 'Sign Description'
      sign_descr : abap.char(20);
}
