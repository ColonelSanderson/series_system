module SeriesSystemValidations
  extend JSONModel

  def self.series_system_relationship_check_dates(hash)
    errors = []

    ['start_date', 'end_date'].each do |date|
      unless hash.fetch(date, '').empty?
        # make sure it's a valid date
        begin
          JSONModel::Validations.parse_sloppy_date(hash[date])
        rescue ArgumentError => e
          errors << [date, "not a valid date"]
        end

        unless valid_date_format(hash[date])
          errors << [date, "date format must be one of YYYY, YYYY-MM, or YYYY-MM-DD"]
        end
      end
    end

    if !hash.fetch('start_date', '').empty? && !hash.fetch('end_date', '').empty? && errors.empty?
      shorty = [hash['start_date'].length, hash['end_date'].length].min
      if hash['start_date'][0,shorty] > hash['end_date'][0,shorty]
        # NOTE: as_mogwai plugin relies on this string for exception handling.
        # If you change this, update it there too!
        errors << ['end_date', 'cannot be before start date']
      end
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


  def self.check_controlling_agency(hash)
    errors = []

    control_relns = hash.fetch("series_system_agent_relationships", []).select do |ar|
      ar['jsonmodel_type'] == 'series_system_agent_record_ownership_relationship' &&
        ar['relator'] == 'is_controlled_by'
    end

    current_control_relns = control_relns.select{|r| !r['end_date'] }

    # series must have a current controller
    if hash['jsonmodel_type'] == 'resource' && current_control_relns.empty?
      errors << ["series_system_agent_relationships", "must have a current controlled by relationship with an agency"]
    end

    # mustn't have more than one current controller
    if current_control_relns.length > 1
      errors << ["series_system_agent_relationships", "cannot have more than one current controlled by relationship with an agency"]
    end

    while !control_relns.empty?
      reln = control_relns.pop

      control_relns.each do |cr|
        # control mustn't overlap
        if overlap?(reln['start_date'], cr['end_date']) && overlap?(cr['start_date'], reln['end_date'])
          errors << ["series_system_agent_relationships", "controlled by relationship dates cannot overlap"]
        end
      end
    end

    errors
  end


  def self.overlap?(start_date, end_date)
    start_date ||= '0' * end_date.length
    end_date ||= '9' * start_date.length

    shorty = [start_date.length, end_date.length].min
    start_date[0,shorty] < end_date[0,shorty]
  end


  def self.check_dates_of_existence(hash)
    errors = []

    if hash.fetch('dates_of_existence', []).length != 1
      errors << ["corporate_entity_dates_of_existence", "must have dates of existence"]
    end

    errors
  end


  def self.valid_date_format(date)
    # make sure date complies with the formatting standard we're enforcing
    # must be one of: YYYY, YYYY-MM, YYYY-MM-DD
    date.nil? || date.empty? || (date.match(/^\d\d\d\d(-\d\d(-\d\d)?)?$/) ? true : false)
  end


  def self.check_date_format(hash)
    errors = []
    ['begin', 'end'].each do |date|
      unless valid_date_format(hash[date])
        errors << [date, "date format must be one of YYYY, YYYY-MM, or YYYY-MM-DD"]
      end
    end
    errors
  end


  if JSONModel(:resource)
    JSONModel(:resource).add_validation("check_series_controlling_agency") do |hash|
      check_controlling_agency(hash)
    end
  end


  if JSONModel(:archival_object)
    JSONModel(:archival_object).add_validation("check_item_controlling_agency") do |hash|
      check_controlling_agency(hash)
    end
  end

  if JSONModel(:agent_corporate_entity)
    JSONModel(:agent_corporate_entity).add_validation("check_dates_of_existence") do |hash|
      check_dates_of_existence(hash)
    end
  end

  if JSONModel(:date)
    JSONModel(:date).add_validation("check_date_format") do |hash|
      check_date_format(hash)
    end
  end

end
