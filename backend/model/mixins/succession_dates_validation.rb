module SuccessionDatesValidation

  def self.included(base)
    base.extend(ClassMethods)
  end

  def update_from_json(json, extra_values = {}, apply_nested_records = true)
    obj = super
    obj.validate_succession_date!
    obj
  end

  def validate_succession_date!
    my_relationships('series_system_agent_relationships').each_with_index do |relationship, idx|
      next unless relationship[:jsonmodel_type] == 'series_system_agent_agent_succession_relationship'

      relator = BackendEnumSource.value_for_id('series_system_succession_relator', relationship[:relator_id])

      date_to_check = nil

      if relator == 'supercedes' && relationship[:relationship_target_id] != self.id
        next if self.date.empty?
        next if self.date.first.begin.nil?

        date_to_check = self.date.first.begin
      else
        target_obj = relationship.other_referent_than(self)
        next if target_obj.nil?
        next if target_obj.date.empty?
        next if target_obj.date.first.begin.nil?

        date_to_check = target_obj.date.first.begin
      end

      unless valid_succession_date?(relationship[:start_date], date_to_check)
        self.errors.add(:"series_system_agent_relationships/#{idx}/start_date", "Succession Date must be after the successor existence date")
        raise Sequel::ValidationFailed.new(self)
      end
    end
  end

  def valid_succession_date?(succession_date, successor_date)
    # raise ["valid_succession_date?", succession_date, successor_date].inspect
    begin
      JSONModel::Validations.parse_sloppy_date(succession_date)
      JSONModel::Validations.parse_sloppy_date(successor_date)
    rescue ArgumentError => e
      # let the other validations catch this
      return true
    end

    shorty = [succession_date.length, successor_date.length].min

    succession_date[0,shorty] >= successor_date[0,shorty]
  end


  module ClassMethods

    def create_from_json(json, extra_values = {})
      obj = super
      obj.validate_succession_date!
      obj
    end

  end
end