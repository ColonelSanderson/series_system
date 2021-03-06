module RelationshipTracer

  class StepLimitExceeded < StandardError; end
  class UnknownRelator < StandardError; end


  def self.included(base)
    base.extend(ClassMethods)
  end


  # Recursively find all series system relationships for an object
  # Returns nested arrays of uris
  #
  # Examples:
  #   obj.trace('supercedes')
  #   obj.trace('contains')
  #
  def trace(relator, opts = {})
    out = []

    opts[:break_on] ||= []
    raise ArgumentError.new("opts[:break_on] must be an array. You provided a #{opts[:break_on].class}") unless opts[:break_on].is_a? Array

    return out if opts[:break_on].include?(self.uri)
    opts[:break_on].push(self.uri)

    if opts.has_key?(:steps)
      raise ArgumentError.new("opts[:steps] must be an integer. You provided a #{opts[:steps].class}") unless opts[:steps].is_a? Integer

      opts[:_steps_taken] ||= 0
      opts[:_steps_taken] += 1

      if opts[:_steps_taken] > opts[:steps]
        if opts[:raise_on_step_limit]
          raise StepLimitExceeded.new("Step limit (#{opts[:steps]}) reached while tracing relationships")
        else
          return out
        end
      end
    end

    # The current rule definitions have unique relators across types
    # It is possible that future definitions will overload relators
    # Since we just grab the first one, subsequent ones will be unreachable
    # This unlikely circumstance is catered for by allowing a relationship_type
    # option to explicitly use the type intended
    relationship_type = opts[:relationship_type] || RelationshipRules.instance.relationships.select{|k,v| v.relator_values.values.include?(relator)}.keys.first

    raise UnknownRelator.new("Can't find a relationship type for the provided relator: #{relator}") unless relationship_type

    # find out if the relationship type is non-directional
    non_directional = RelationshipRules.instance.relationships[relationship_type].relator_values.values.uniq.length == 1

    # get the id for the relator - we'll need it later
    relator_id = db[:enumeration_value].filter(:value => relator).get(:id)

    rules = RelationshipRules.instance.rules_for_jsonmodel_type(self.class.my_jsonmodel.record_type).select do |rule|
      rule.relationship_types.include?(relationship_type) && (!opts.has_key?(:target_category) || rule.target_jsonmodel_category == opts[:target_category])
    end

    rules.each do |rule|
      rlshp_def = self.class.find_relationship("series_system_#{rule.target_jsonmodel_category}_relationships", true)
      # we might have to wait for the reverse rule
      next unless rlshp_def

      rlshp_jsonmodel_type = RelationshipRules.instance.build_relationship_jsonmodel_name(rule, relationship_type)

      rels = rlshp_def.find_by_participant(self)
        .select{|rel| rel.jsonmodel_type == rlshp_jsonmodel_type}
        .select{|rel|
                  # don't care about direction if it's non-directional
                  non_directional ||
                  # otherwise make sure it's the right way around!
                  (the_target_is_me = rel.relationship_target_record_type.intern == self.class.table_name && rel.relationship_target_id == self.id
                   the_target_is_me ? rel.relator_id != relator_id : rel.relator_id == relator_id)
               }

      rels.each do |rel|
        other = rel.other_referent_than(self)
        other_uri = other.uri

        next if opts[:break_on].include?(other_uri)

        out << build_rel(rel, other.trace(relator, opts), opts)
      end
    end

    out
  end


  def build_rel(rel, other_trace, opts)
    other = rel.other_referent_than(self)
    json = other.class.to_jsonmodel(other.id)
    label = json['long_display_string'] || json['display_string'] || json['title'] || json['name']
    uri = other.uri
    if opts[:full]
      {
        :ref => uri,
        :label => label,
        :start_date => rel.start_date,
        :end_date => rel.end_date,
        :note => rel.note,
        :trace => other_trace,
      }.select{|k,v| !!v && !v.empty?}
    else
      (other_trace.empty? ? uri : [uri, other_trace])
    end
  end


  def trace_all(opts = {})
    relators = []
    categories = RelationshipRules.instance.categories_for_jsonmodel(self.class.my_jsonmodel.record_type)
    rules = RelationshipRules.instance.rules_for_jsonmodel_type(self.class.my_jsonmodel.record_type).select do |rule|
      if categories.include?(rule.source_jsonmodel_category)
        relators << rule.relationship_types.map{|rt| RelationshipRules.instance.relationships[rt].relator_values[:source]}
      end
      if categories.include?(rule.target_jsonmodel_category)
        relators << rule.relationship_types.map{|rt| RelationshipRules.instance.relationships[rt].relator_values[:target]}
      end
    end
    relators = relators.flatten.uniq

    Hash[relators.map{|relator| [relator, trace(relator, {:steps => 1}.merge(opts))]}]
  end


  def trace_set(relator, opts = {})
    trace(relator, opts).flatten
  end


  def trace_one(relator, opts = {})
    trace_set(relator, opts.merge(:steps => 1))
  end


  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super
      jsons.zip(objs).each do |json, obj|
        json['relationship_tracer'] = { 'ref' => "#{json['uri']}/trace" }
      end

      jsons
    end
  end

end
