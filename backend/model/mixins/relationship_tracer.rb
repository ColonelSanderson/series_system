module RelationshipTracer

  class StepLimitExceeded < StandardError; end
  class UnknownRelator < StandardError; end

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
      rlshp_def = self.class.find_relationship("series_system_#{rule.target_jsonmodel_category}_relationships")
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

        other_trace = other.trace(relator, opts)
        out << (other_trace.empty? ? other_uri : [other_uri, other_trace])
      end
    end

    out
  end


  def trace_set(relator, opts = {})
    trace(relator, opts).flatten
  end


  def trace_one(relator, opts = {})
    trace_set(relator, opts.merge(:steps => 1))
  end

end
