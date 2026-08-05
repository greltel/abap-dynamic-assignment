@EndUserText.label: 'Value Help for Sign'
@ObjectModel.query.implementedBy: 'ABAP:ZCL_DA_SIGN_VH'
@ObjectModel.resultSet.sizeCategory: #XS
define custom entity ZI_DA_SIGN_VH
{
      @EndUserText.label: 'Sign'
      @EndUserText.quickInfo: 'Include or exclude'
  key sign       : zde_da_sign;

      @EndUserText.label: 'Sign Description'
      @EndUserText.quickInfo: 'Description of the sign'
      sign_descr : abap.char(60);
}
