@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Interface View for Variants'

@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #CUSTOMIZING }

define root view entity ZI_DA_VARIANTS
  as select from zda_variants

{
  key progname              as Progname,
  key parameterid           as Parameterid,
  key counter               as Counter,

      is_active             as IsActive,
      sign                  as Sign,
      opt                   as Opt,
      value                 as Value,
      high_value            as HighValue,
      data_element          as DataElement,
      mapping_value         as MappingValue,
      mapping_data_el       as MappingDataElement,
      description           as Description,

      // RAP Administrative Fields
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt
}
