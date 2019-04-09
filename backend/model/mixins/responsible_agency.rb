module ResponsibleAgency

  def self.prepended(base)
    class << base
      prepend(ClassMethods)
    end
  end

  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super
      jsons.zip(objs).each do |json, obj|
        json['responsible_agency'] = { 'ref' => obj.responsible_agency }
      end

      jsons
    end
  end
end
