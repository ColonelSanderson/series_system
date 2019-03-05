module SeriesSystemValidations
  extend JSONModel

  def self.series_system_relationship_check_dates(hash)
    errors = []

    begin
      JSONModel::Validations.parse_sloppy_date(hash['start_date']) if hash['start_date']
    rescue ArgumentError => e
      errors << ["start_date", "not a valid date"]
    end

    begin
      JSONModel::Validations.parse_sloppy_date(hash['end_date']) if hash['end_date']
    rescue ArgumentError => e
      errors << ["end_date", "not a valid date"]
    end

    errors
  end


  def self.series_system_check_relationship_refs(hash, source_jsonmodel_type)
    errors = []

    rules = RelationshipRules.instance.rules_for_jsonmodel_type(source_jsonmodel_type)

    rules.each do |rule|
      next unless RelationshipRules.instance.supported?(rule)
      next if rule.source_jsonmodel_category == rule.target_jsonmodel_category

      property = RelationshipRules.instance.build_jsonmodel_property(rule.target_jsonmodel_category)

      ASUtils.wrap(hash[property]).each_with_index do |reln_hash, i|
        next unless reln_hash["ref"]

        relationship_jsonmodel = reln_hash["jsonmodel_type"]
        ref_jsonmodel_type = JSONModel.parse_reference(reln_hash["ref"])[:type].to_s
        possible_ref_types = JSONModel(relationship_jsonmodel.intern).schema.fetch("properties").fetch("ref").fetch("type").collect{|t| t["type"]}
        possible_ref_types.reject!{|type| type == "JSONModel(:#{source_jsonmodel_type}) uri"}
        unless possible_ref_types.include?("JSONModel(:#{ref_jsonmodel_type}) uri")
          errors << ["#{property}/#{i}/ref", "not a valid jsonmodel_type"]
        end
      end
    end

    errors
  end

  RelationshipRules.instance.supported_rules.each do |rule|
    next if rule.source_jsonmodel_category == rule.target_jsonmodel_category

    RelationshipRules.instance.jsonmodel_expander(rule.source_jsonmodel_category).each do |source_jsonmodel_type|
      validation_name = "#{source_jsonmodel_type}_series_system_relationships"
      if JSONModel(source_jsonmodel_type.intern) and !JSONModel.custom_validations.include?(validation_name)
        JSONModel(source_jsonmodel_type.intern).add_validation(validation_name) do |hash|
          series_system_check_relationship_refs(hash, source_jsonmodel_type)
        end
      end
    end
  end

  RelationshipRules.instance.all_relationship_jsonmodels.each do |relationship_jsonmodel|
    JSONModel(relationship_jsonmodel.intern).add_validation("#{relationship_jsonmodel}_check_dates") do |hash|
      series_system_relationship_check_dates(hash)
    end
  end
end
