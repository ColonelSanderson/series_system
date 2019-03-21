require 'singleton'

class RelationshipRules
  include Singleton

  attr_reader :rules, :relationships, :all_relationship_jsonmodels

  # The series system relationship rules define which types of records can link
  # to which other types of records.  These types are high-level categories like
  # "agent" which must be mapped to the underlying ArchivesSpace JSONModels.
  # Here are those mappings.
  #
  JSONMODEL_CATEGORIES = {
    :agent => [:agent_corporate_entity, :agent_family, :agent_person, :agent_software],
    :record => [:resource, :archival_object],
    :transfer => [:accession],
    :series => [:resource],
    :item => [:archival_object],
  }


  RelationshipRule = Struct.new(:source_jsonmodel_category, :target_jsonmodel_category, :relationship_types, :reverse_rule, :is_reversed) do
    def key
      "#{source_jsonmodel_category}__#{target_jsonmodel_category}"
    end
  end
  RelationshipType = Struct.new(:key, :relator, :relator_values)

  def initialize
    @mode = :backend

    relator_values = {}
    relator_values['abolition'] = {:source => "abolished", :target => "is_abolished_by"}
    relator_values['administers'] = {:source => "administered", :target => "is_administered_by"}
    relator_values['association'] = {:source => "is_associated_with", :target => "is_associated_with"}
    relator_values['authorisation'] = {:source => "authorises", :target => "is_authorised_by"}
    relator_values['containment'] = {:source => "contains", :target => "is_contained_within"}
    relator_values['creation'] = {:source => "established", :target => "established_by"}
    relator_values['derivation'] = {:source => "derives", :target => "is_derived_from"}
    relator_values['documentation'] = {:source => "is_documented_by", :target => "documents"}
    relator_values['ownership'] = {:source => "controls", :target => "is_controlled_by"}
    relator_values['represented'] = {:source => "represents", :target => "is_represented_by"}
    relator_values['responsibility'] = {:source => "is_responsible_for", :target => "under_responsibility_of"}
    relator_values['restriction'] = {:source => "restricts", :target => "is_restricted_by"}
    relator_values['succession'] = {:source => "supercedes", :target => "precedes"}
    relator_values['preferred_term'] = {:source => "has_preferred_term_of", :target => "is_preferred_term_of"}
    relator_values['nonpreferred_term'] = {:source => "has_nonpreferred_term_of", :target => "is_nonpreferred_term_of"}

    @relationships = {}
    relator_values.keys.each do |key|
      relator = "series_system_#{key}_relator"
      @relationships[key] = RelationshipType.new(key, relator, relator_values.fetch(key))
    end

    @rules = []
    @rules << RelationshipRule.new(:agent, :agent, ['succession', 'ownership', 'containment', 'association'])
    @rules << RelationshipRule.new(:agent, :record, ['ownership', 'creation'])
    @rules << RelationshipRule.new(:agent, :transfer, ['ownership'])
    @rules << RelationshipRule.new(:agent, :mandate, ['authorisation', 'ownership', 'creation', 'administers'])
    @rules << RelationshipRule.new(:agent, :function, ['administers'])

    @rules << RelationshipRule.new(:series, :series, ['succession', 'ownership', 'association'])
    @rules << RelationshipRule.new(:series, :item, ['containment', 'ownership'])

    @rules << RelationshipRule.new(:item, :item, ['containment', 'succession'])

    @rules << RelationshipRule.new(:transfer, :record, ['containment'])

    @rules << RelationshipRule.new(:mandate, :series, ['association', 'ownership', 'documentation', 'restriction'])
    @rules << RelationshipRule.new(:mandate, :mandate, ['association', 'containment', 'succession'])
    @rules << RelationshipRule.new(:mandate, :function, ['creation', 'association', 'abolition'])

    @rules << RelationshipRule.new(:function, :series, ['documentation', 'association'])
    @rules << RelationshipRule.new(:function, :function, ['containment', 'association', 'succession', 'preferred_term', 'nonpreferred_term'])

    @all_relationship_jsonmodels = []

    expand_reverse_relationship_rules!
  end

  # An enduring relationship can't be terminated unless there's a new
  # relationship (with a different record) to take its place.
  def enduring_relationships
    ['series_system_agent_record_ownership_relationship']
  end

  # Non-closeable relationships are left open even when an agency is being terminated
  def non_auto_closeable_relationships
    result = []

    rules.each do |rule|
      next unless rule.source_jsonmodel_category == :agent

      rule.relationship_types.each do |relationship_type|
        if ['creation', 'succession'].include?(relationship_type)
          result << build_relationship_jsonmodel_name(rule, relationship_type)
        end
      end
    end

    result
  end

  def mode(mode)
    @mode = mode
    self
  end

  def bootstrap!
    log "Series System Relationships Bootstrap -- STARTING"
    rules.each do |rule|
      log("Processing rule: #{rule}")
      validate_rule(rule)
      log "Rule is valid"
      bootstrap_rule(rule)
      log "-- rule done --"
    end

    if backend?
      validate_relationship_types
    end

    log "Series System Relationships Bootstrap -- DONE"
  end

  def validate_relationship_types
    self.relationships.values.each do |relationship|
      enum_values = BackendEnumSource.values_for(relationship.relator)
      unless relationship.relator_values.values.sort.uniq == enum_values.sort.uniq
        raise "Dynamic enum '#{relationship.relator}' had unexpected values.  Had: %s; Wanted: %s" % [enum_values, relationship.relator_values.values.uniq]
      end
    end
  end

  def validate_rule(rule)
    validate_jsonmodel_category(rule.source_jsonmodel_category)
    validate_jsonmodel_category(rule.target_jsonmodel_category)

    raise "Rule needs relationships: #{rule.inspect}" if rule.relationship_types.nil? || rule.relationship_types.empty?

    rule.relationship_types.each do |relationship_type|
      log "Validating jsonmodel type: #{relationship_type}"
      raise "Relationship type does not exist: #{relationship_type}" unless relationships.include?(relationship_type)
    end

  end

  def validate_jsonmodel_category(jsonmodel_category_or_magic)
    log "Validating jsonmodel type: #{jsonmodel_category_or_magic}"
    jsonmodel_types = jsonmodel_expander(jsonmodel_category_or_magic)
    jsonmodel_types.each do |jsonmodel_type|
      raise "No JSONModel for #{jsonmodel_type}" unless JSONModel.models.include?(jsonmodel_type.to_s)
    end
  end

  def jsonmodel_expander(jsonmodel_category)
    JSONMODEL_CATEGORIES.fetch(jsonmodel_category, ASUtils.wrap(jsonmodel_category))
  end

  def global?(jsonmodel_category)
    jsonmodel_expander(jsonmodel_category).any? {|jsonmodel_type|
      !JSONModel.JSONModel(jsonmodel_type).schema.fetch('uri').start_with?("/repositories/")
    }
  end

  def supported?(rule)
    # global->repository scoped relationships as not supported
    return true if !global?(rule.source_jsonmodel_category)
    return true if global?(rule.source_jsonmodel_category) and global?(rule.target_jsonmodel_category)

    false
  end

  def supported_rules
    rules.select{|rule| supported?(rule)}
  end

  def bootstrap_rule(rule)
    # Use abstract_series_system_relationship as the basis for all relationship JSONModels
    abstract_relationship_schema = JSONModel.JSONModel(:abstract_series_system_relationship).schema

    return unless supported?(rule)

    jsonmodel_expander(rule.source_jsonmodel_category).each do |source_jsonmodel_type|
      relationship_jsonmodels = []
      relators = []

      rule.relationship_types.each do |relationship_type|
        rlshp_name = build_relationship_jsonmodel_name(rule, relationship_type)

        relators << relationships.fetch(relationship_type).relator
        relationship_jsonmodels << rlshp_name

        # skip if already created by reciprocal relationship
        next if @all_relationship_jsonmodels.include?(rlshp_name)

        rlshp_schema = Marshal.load(Marshal.dump(abstract_relationship_schema))
        rlshp_schema["properties"].merge!({
          "relator" => {
            "type" => "string",
            "dynamic_enum" => relationships.fetch(relationship_type).relator || raise("No relator"),
            "ifmissing" => "error"
          },
          "ref" => {
            "type" => (jsonmodel_expander(rule.source_jsonmodel_category) + jsonmodel_expander(rule.target_jsonmodel_category)).map { |target_jsonmodel_type|
                        {"type" => "JSONModel(:#{target_jsonmodel_type}) uri"}
                      },
            "ifmissing" => "error"
          },
        })

        JSONModel.validate_schema(rlshp_schema)
        JSONModel.create_model_for(rlshp_name, rlshp_schema)

        log "Created #{JSONModel.JSONModel(rlshp_name.intern)} with dynamic_enum #{relationships.fetch(relationship_type).relator}"

        @all_relationship_jsonmodels << rlshp_name
      end

      jsonmodel_property = build_jsonmodel_property(rule.target_jsonmodel_category)
      source_schema = JSONModel.JSONModel(source_jsonmodel_type).schema
      source_schema["properties"][jsonmodel_property] = {
        "type" => "array",
        "items" => {
          "type" => relationship_jsonmodels.map {|relationship_jsonmodel|
                      {"type" => "JSONModel(:#{relationship_jsonmodel}) object"}
                    }
        }
      }
      JSONModel.validate_schema(source_schema)
      log "Added #{jsonmodel_property} to #{source_jsonmodel_type} schema supporting: #{relationship_jsonmodels}"

      if backend?
        source_model = model_for_jsonmodel_type(source_jsonmodel_type)
        source_model.include(DirectionalRelationships) unless source_model.included_modules.include?(DirectionalRelationships)
        references = jsonmodel_expander(rule.target_jsonmodel_category).map {|type|
          model_for_jsonmodel_type(type)
        }
  
        source_model.define_directional_relationship(:name => jsonmodel_property,
                                                     :table => :series_system_rlshp,
                                                     :json_property => jsonmodel_property,
                                                     :contains_references_to_types => proc { references },
                                                     :supported_jsonmodel_types => relationship_jsonmodels,
                                                     :class_callback => proc {|clz|
                                                       clz.instance_eval do
                                                         include DynamicEnums

                                                         uses_enums({
                                                           :property => 'relator',
                                                           :uses_enum => relators,
                                                         })


                                                         def self.create(values)
                                                           values.delete('relationship_id')
                                                           super
                                                         end


                                                         alias_method :values_orig, :values
                                                         define_method(:values) do
                                                           result = values_orig

                                                           result['relationship_id'] = self.id.to_s
                                                           result
                                                         end
                                                       end
                                                     })

        log "Added #{jsonmodel_property} relationship to #{source_model.to_s} with relators: #{relators}"
      end
    end
  end

  def backend?
    @mode == :backend
  end

  def model_for_jsonmodel_type(jsonmodel_type)
    @model_map ||= {}

    return @model_map[jsonmodel_type] if @model_map.include?(jsonmodel_type)

    @model_map[jsonmodel_type] = ASModel.all_models.find {|model|
      jsonmodel = model.my_jsonmodel(true)
      jsonmodel && jsonmodel.record_type == jsonmodel_type.to_s
    } || raise("Model not found for #{jsonmodel_type}")

    @model_map[jsonmodel_type]
  end

  def build_relationship_jsonmodel_name(rule, relationship_type)
    "series_system_#{[rule.source_jsonmodel_category, rule.target_jsonmodel_category].sort.join('_')}_#{relationship_type}_relationship"
  end

  def build_jsonmodel_property(target_jsonmodel_category)
    "series_system_#{target_jsonmodel_category}_relationships"
  end

  def has_rules_for_jsonmodel_type?(jsonmodel_type)
    rules.any?{|rule| jsonmodel_expander(rule.source_jsonmodel_category).include?(jsonmodel_type.intern)}
  end

  def rules_for_jsonmodel_type(jsonmodel_type)
    rules.select{|rule| jsonmodel_expander(rule.source_jsonmodel_category).include?(jsonmodel_type.intern)}
  end

  # A list of all JSONModel properties on `source_jsonmodel_type` that can refer to `target_jsonmodel_type`
  def relationship_jsonmodel_properties(source_jsonmodel_type, target_jsonmodel_type)
    matched_rules = rules_for_jsonmodel_type(source_jsonmodel_type.intern).select {|rule|
      jsonmodel_expander(rule.target_jsonmodel_category).include?(target_jsonmodel_type.intern)
    }

    matched_rules.map {|rule| build_jsonmodel_property(rule.target_jsonmodel_category)}
  end

  def expand_reverse_relationship_rules!
    dict = {}
    reverse_rules = []

    rules.each do |rule|
      dict[rule.key] = rule

      if rule.target_jsonmodel_category == rule.source_jsonmodel_category
        rule.reverse_rule = rule
        next
      end

      reverse_rule = RelationshipRule.new(rule.target_jsonmodel_category, rule.source_jsonmodel_category, rule.relationship_types)
      raise "Already defined relationship between #{rule.target_jsonmodel_category}->#{rule.source_jsonmodel_category}" if dict.has_key?(reverse_rule.key)

      reverse_rule.is_reversed = true

      dict[reverse_rule.key] = reverse_rule

      rule.reverse_rule = reverse_rule
      reverse_rule.reverse_rule = rule

      reverse_rules << reverse_rule
    end

    @rules = @rules + reverse_rules
  end

  def find_relator_values(relationship_type_key)
    relationship_type = self.relationships.fetch(relationship_type_key) do
      raise "Relationship type not defined for '%s'" % [relationship_type_key]
    end

    relationship_type.relator_values
  end

  def find_relator_value(record_type, rule, relationship_type_key)
    if rule.is_reversed
      rule = rule.reverse_rule
    end

    if rule.source_jsonmodel_category == record_type
      attr = :source
    elsif rule.target_jsonmodel_category == record_type
      attr = :target
    else
      raise "Provided rule didn't match provided record_type"
    end

    find_relator_values(relationship_type_key).fetch(attr)
  end

  # For a given relator and value, return the other relator (e.g. given 'established' return 'established by')
  def flip_relator(relator_name, value)
    possible_values = JSONModel.enum_values(relator_name)

    other_value = possible_values - [value]

    if other_value.empty?
      # Single value...
      value
    else
      other_value[0]
    end
  end

  def log(*args)
    if backend?
      Log.debug(args)
    end
  end

  def should_show_multiple_relators?(rule, relationship_type)
    return false if rule.source_jsonmodel_category != rule.target_jsonmodel_category

    relator_values = find_relator_values(relationship_type)
    relator_values.fetch(:source) != relator_values.fetch(:target)
  end
end
 
