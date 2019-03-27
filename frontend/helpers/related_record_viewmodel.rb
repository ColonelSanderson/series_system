class RelatedRecordViewModel

  def initialize(related_record, current_record_uri)
    @related_record = related_record
    @related_record_type = related_record.fetch('jsonmodel_type')
    @related_record_json = ASUtils.json_parse(@related_record['json'])

    @current_record_uri = current_record_uri
    @current_record_type = JSONModel.parse_reference(@current_record_uri).fetch(:type)
  end

  DisplayRelationship = Struct.new(:relator, :start_date, :end_date, :note)

  def relationships
    result = []

    # The set of JSONModel properties that might contain the reference to the
    # linked record we've found.
    relationship_properties = RelationshipRules.instance.relationship_jsonmodel_properties(@related_record_type,
                                                                                           @current_record_type)

    relationship_properties.each do |property|
      @related_record_json[property].each do |reference|
        # For each reference we find that links to this record,
        # pull out and translate its relator.  This requires
        # knowing which dynamic enum the relator is from, which
        # unfortunately requires a trip back to the JSONModel
        # Schema...

        relator_name = JSONModel(reference['jsonmodel_type'].intern).schema['properties']['relator']['dynamic_enum']

        if reference['ref'] == @current_record_uri
          reverse_relator = RelationshipRules.instance.flip_relator(relator_name, reference['relator'])

          result << DisplayRelationship.new(I18n.t("enumerations.#{relator_name}.#{reverse_relator}"),
                                            reference.fetch('start_date', ''),
                                            reference.fetch('end_date', ''),
                                            reference.fetch('note', ''))
        end
      end
    end


    result
  end

end
