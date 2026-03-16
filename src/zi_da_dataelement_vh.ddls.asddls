@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Data Elements'
@Search.searchable: true
define view entity ZI_DA_DATAELEMENT_VH
  as select from I_DataElementLabelText
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @ObjectModel.text.element: ['Description']
      @EndUserText.label: 'Data Element'
  key ABAPDataElement as DataElement,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Semantics.text: true
      @EndUserText.label: 'Description'
      ABAPDataElementDescription as Description
}
where Language = $session.system_language
