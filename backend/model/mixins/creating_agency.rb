# Keep track of which agency ultimately created each series/record in the system
# by propagating the agency relationship from parents to children in the tree.
#
# Each record winds up with a 'creating_agency' ref.
#
module CreatingAgency

  module ResourceCreation

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def sequel_to_jsonmodel(objs, opts = {})
        jsons = super

        # A resource record either has a creating agency or there isn't one
        # recorded.
        jsons.each do |json|
          created_relationship = (json['series_system_agent_relationships'] || []).find {|relationship|
            relationship.fetch('relator') == 'established_by'
          }

          if created_relationship
            json['creating_agency'] = {'ref' => created_relationship.fetch('ref')}
          end
        end

        jsons
      end

      def build_creating_agency_map_resource(objs)
        result = {}

        Resource.find_relationship('series_system_agent_relationships')
          .find_by_participants(objs)
          .each do |resource, rlshps|
          creation_relationship = rlshps.find {|r| r.jsonmodel_type == 'series_system_agent_record_creation_relationship'}
          if creation_relationship
            result[resource.id] = creation_relationship.uri_for_other_referent_than(resource)
          end
        end

        result
      end
    end
  end


  module ArchivalObjectCreation

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def build_creating_agency_map(objs)
        result = {}

        return result if objs.empty?

        pending = objs.map {|obj| [obj.id, obj]}.to_h

        creation_relationship_definition = self.find_relationship('series_system_agent_relationships')

        # Look for creation relationships directly attached to our set of objects
        creation_relationship_definition.find_by_participants(pending.values).each do |obj, rlshps|
          creation_relationship = rlshps.find {|r| r.jsonmodel_type == 'series_system_agent_record_creation_relationship'}
          if creation_relationship
            result[obj.id] = creation_relationship.uri_for_other_referent_than(obj)
            pending.delete(obj.id)
          end
        end

        # If there are remaining top-level AOs, we'll need to check their resource records
        top_level_aos = pending.values.select {|ao| ao.parent_id.nil?}
        resource_agency_map = Resource.build_creating_agency_map_resource(Resource.filter(:id => top_level_aos.map(&:root_record_id)).all)

        top_level_aos.each do |ao|
          if creating_agency_uri = resource_agency_map.fetch(ao.root_record_id, nil)
            result[ao.id] = creating_agency_uri
          end

          pending.delete(ao.id)
        end

        # For remaining AOs with parents, recurse up the tree
        parent_agency_map = self.build_creating_agency_map(self.filter(:id => pending.values.map(&:parent_id)).all)
        pending.values.each do |ao|
          if creating_agency_uri = parent_agency_map.fetch(ao.parent_id, nil)
            result[ao.id] = creating_agency_uri
          end

          pending.delete(ao.id)
        end

        result
      end

      def sequel_to_jsonmodel(objs, opts = {})
        jsons = super

        creating_agency_map = build_creating_agency_map(objs)

        jsons.zip(objs).each do |json, obj|
          if agency_ref = creating_agency_map.fetch(obj.id, nil)
            json['creating_agency'] = {'ref' => creating_agency_map.fetch(obj.id)}
          end
        end

        jsons
      end
    end
  end
end
