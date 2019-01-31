require 'singleton'

class RelationshipRules
  include Singleton

  attr_reader :rules, :relationships, :all_relationship_jsonmodels

  RelationshipRule = Struct.new(:source_jsonmodel_type, :target_jsonmodel_type, :relationship_types, :reverse_rule, :is_reversed) do
    def key
      "#{source_jsonmodel_type}__#{target_jsonmodel_type}"
    end
  end
  RelationshipType = Struct.new(:key, :relator, :relator_values)

  # Magic Mappers:
  # :agent === :agent_corporate_entity, :agent_family, :agent_person, :agent_software 
  # :record === :resource, :archival_object 
  # :transfer === :accession
  # :representation === :digital_object, :digital_object_component
  # :series === :resource
  # :item === :archival_object

  def self.relationship_type_keys
    ['association', 'authorisation', 'succession', 'ownership', 'containment',
     'responsibility', 'creation', 'represented', 'derivation', 'documentation',
     'restriction', 'synonym', 'preferred_term', 'nonpreferred_term']
  end

  def initialize
    @mode = :backend

    relator_values = {}
    relator_values['association'] = {:source => "is_associated_with", :target => "is_associated_with"}
    relator_values['authorisation'] = {:source => "authorises", :target => "is_authorised_by"}
    relator_values['containment'] = {:source => "contains", :target => "is_contained_within"}
    relator_values['creation'] = {:source => "established", :target => "established_by"}
    relator_values['derivation'] = {:source => "derives", :target => "is_derived_from"}
    relator_values['documentation'] = {:source => "documents", :target => "is_documented_by"}
    relator_values['ownership'] = {:source => "controls", :target => "is_controlled_by"}
    relator_values['represented'] = {:source => "represents", :target => "is_represented_by"}
    relator_values['responsibility'] = {:source => "is_responsible_for", :target => "under_responsibility_of"}
    relator_values['restriction'] = {:source => "restricts", :target => "is_restricted_by"}
    relator_values['succession'] = {:source => "supercedes", :target => "precedes"}
    relator_values['synonym'] = {:source => "is_synonym_of", :target => "is_synonym_of"}
    relator_values['preferred_term'] = {:source => "has_preferred_term_of", :target => "is_preferred_term_of"}
    relator_values['nonpreferred_term'] = {:source => "has_nonpreferred_term_of", :target => "is_nonpreferred_term_of"}

    @relationships = {}
    self.class.relationship_type_keys.each do |key|
      relator = "series_system_#{key}_relator"
      @relationships[key] = RelationshipType.new(key, relator, relator_values[key])
    end

    @rules = []
    @rules << RelationshipRule.new(:agent, :agent, ['succession', 'ownership', 'containment', 'association'])
    @rules << RelationshipRule.new(:agent, :record, ['ownership', 'creation','association'])
    @rules << RelationshipRule.new(:agent, :representation, ['creation', 'ownership'])
    @rules << RelationshipRule.new(:agent, :transfer, ['ownership'])
    @rules << RelationshipRule.new(:agent, :mandate, ['authorisation', 'ownership', 'creation'])
    @rules << RelationshipRule.new(:agent, :function, ['ownership', 'creation'])

    @rules << RelationshipRule.new(:series, :series, ['succession', 'ownership'])
    @rules << RelationshipRule.new(:series, :item, ['containment', 'ownership'])

    @rules << RelationshipRule.new(:item, :item, ['containment', 'succession'])
    @rules << RelationshipRule.new(:item, :representation, ['containment', 'represented'])

    @rules << RelationshipRule.new(:representation, :representation, ['association', 'containment', 'derivation'])

    @rules << RelationshipRule.new(:transfer, :record, ['containment'])

    @rules << RelationshipRule.new(:mandate, :series, ['association', 'ownership', 'documentation', 'restriction'])
    @rules << RelationshipRule.new(:mandate, :mandate, ['association', 'containment', 'succession'])
    @rules << RelationshipRule.new(:mandate, :function, ['creation', 'association'])

    @rules << RelationshipRule.new(:function, :series, ['documentation', 'association'])
    @rules << RelationshipRule.new(:function, :function, ['containment', 'association', 'succession', 'synonym', 'preferred_term', 'nonpreferred_term'])

    @all_relationship_jsonmodels = []

    expand_reverse_relationship_rules!
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
    validate_jsonmodel_type(rule.source_jsonmodel_type)
    validate_jsonmodel_type(rule.target_jsonmodel_type)

    raise "Rule needs relationships: #{rule.inspect}" if rule.relationship_types.nil? || rule.relationship_types.empty?

    rule.relationship_types.each do |relationship_type|
      log "Validating jsonmodel type: #{relationship_type}"
      raise "Relationship type does not exist: #{relationship_type}" unless relationships.include?(relationship_type)
    end

  end

  def validate_jsonmodel_type(jsonmodel_type_or_magic)
    log "Validating jsonmodel type: #{jsonmodel_type_or_magic}"
    jsonmodel_types = jsonmodel_expander(jsonmodel_type_or_magic)
    jsonmodel_types.each do |jsonmodel_type|
      raise "No JSONModel for #{jsonmodel_type}" unless JSONModel.models.include?(jsonmodel_type.to_s)
    end
  end

  def jsonmodel_expander(jsonmodel_type)
    if jsonmodel_type == :agent
      [:agent_corporate_entity, :agent_family, :agent_person, :agent_software]
    elsif jsonmodel_type == :record
      [:resource, :archival_object]
    elsif jsonmodel_type == :transfer
      [:accession]
    elsif jsonmodel_type == :representation
      [:digital_object, :digital_object_component]
    elsif jsonmodel_type == :series
      [:resource]
    elsif jsonmodel_type == :item
      [:archival_object]
    else
      ASUtils.wrap(jsonmodel_type)
    end
  end

  def global?(jsonmodel_type)
    # FIXME can we make this refer to the models and work in the frontend?
    [:agent, :agent_corporate_entity, :agent_family, :agent_person,
     :agent_software, :function, :mandate].include?(jsonmodel_type.intern)
  end

  def supported?(rule)
    # global->repository scoped relationships as not supported
    return true if !global?(rule.source_jsonmodel_type)
    return true if global?(rule.source_jsonmodel_type) and global?(rule.target_jsonmodel_type)

    false
  end

  def supported_rules
    rules.select{|rule| supported?(rule)}
  end

  def bootstrap_rule(rule)
    # Use abstract_series_system_relationship as the basis for all relationship JSONModels
    abstract_relationship_schema = JSONModel.JSONModel(:abstract_series_system_relationship).schema

    return unless supported?(rule)

    jsonmodel_expander(rule.source_jsonmodel_type).each do |source_jsonmodel_type|
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
            "type" => (jsonmodel_expander(rule.source_jsonmodel_type) + jsonmodel_expander(rule.target_jsonmodel_type)).map { |target_jsonmodel_type|
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

      jsonmodel_property = build_jsonmodel_property(rule.target_jsonmodel_type)
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
        references = jsonmodel_expander(rule.target_jsonmodel_type).map {|type|
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
    "series_system_#{[rule.source_jsonmodel_type, rule.target_jsonmodel_type].sort.join('_')}_#{relationship_type}_relationship"
  end

  def build_jsonmodel_property(target_jsonmodel_type)
    "series_system_#{target_jsonmodel_type}_relationships"
  end

  def has_rules_for_jsonmodel_type?(jsonmodel_type)
    rules.any?{|rule| jsonmodel_expander(rule.source_jsonmodel_type).include?(jsonmodel_type.intern)}
  end

  def rules_for_jsonmodel_type(jsonmodel_type)
    rules.select{|rule| jsonmodel_expander(rule.source_jsonmodel_type).include?(jsonmodel_type.intern)}
  end

  def expand_reverse_relationship_rules!
    dict = {}
    reverse_rules = []

    rules.each do |rule|
      dict[rule.key] = rule

      if rule.target_jsonmodel_type == rule.source_jsonmodel_type
        rule.reverse_rule = rule
        next
      end

      reverse_rule = RelationshipRule.new(rule.target_jsonmodel_type, rule.source_jsonmodel_type, rule.relationship_types)
      raise "Already defined relationship between #{rule.target_jsonmodel_type}->#{rule.source_jsonmodel_type}" if dict.has_key?(reverse_rule.key)

      reverse_rule.is_reversed = true

      dict[reverse_rule.key] = reverse_rule

      rule.reverse_rule = reverse_rule
      reverse_rule.reverse_rule = rule

      reverse_rules << reverse_rule
    end

    @rules = @rules + reverse_rules
  end

  def find_relator_value(record_type, rule, relationship_type_key)
    if rule.is_reversed
      rule = rule.reverse_rule
    end

    relationship_type = self.relationships.fetch(relationship_type_key) do
      raise "Relationship type not defined for '%s'" % [relationship_type_key]
    end

    if rule.source_jsonmodel_type == record_type
      attr = :source
    elsif rule.target_jsonmodel_type == record_type
      attr = :target
    else
      raise "Provided rule didn't match provided record_type"
    end

    relationship_type.relator_values.fetch(attr)
  end

  def log(*args)
    if backend?
      Log.debug(args)
    end
  end
end
 
