@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Projection View for Variants'

@Metadata.allowExtensions: true

@Search.searchable: true

define root view entity ZC_DA_VARIANTS
  provider contract transactional_query
  as projection on ZI_DA_VARIANTS

{
      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_DA_PROGNAME_VH', element: 'Progname' } } ]
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key Progname,

      @Consumption.valueHelpDefinition: [ { entity: { name: 'ZI_DA_PARAMID_VH', element: 'Parameterid' },
                                            additionalBinding: [ { localElement: 'Progname',
                                                                   element: 'Progname',
                                                                   usage: #FILTER } ] } ]
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
  key Parameterid,

  key Counter,

      IsActive,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_DA_SIGN_VH', element: 'sign' } }]
      Sign,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_DA_OPTION_VH', element: 'options' } }]
      Opt,
      Value,
      HighValue,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_DA_DATAELEMENT_VH', element: 'DataElement' } }]
      DataElement,
      MappingValue,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_DA_DATAELEMENT_VH', element: 'DataElement' } }]
      MappingDataElement,
      Description,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt
}
