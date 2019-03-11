require_relative './factories_ext'
require 'spec_helper'

describe 'series_system relationships' do

  def enum_source
    if defined? BackendEnumSource
      BackendEnumSource
    else
      JSONModel.init_args[:enum_source]
    end
  end

  def relator_options(relationship_name)
    enum_source.values_for(JSONModel(relationship_name.intern).schema['properties']['relator']['dynamic_enum'])
  end

  RelationshipRules.instance.supported_rules.each do |rule|

    describe "#{rule.source_jsonmodel_category} to #{rule.target_jsonmodel_category}" do
      RelationshipRules.instance.jsonmodel_expander(rule.source_jsonmodel_category).each do |source_jsonmodel|
        RelationshipRules.instance.jsonmodel_expander(rule.target_jsonmodel_category).each do |target_jsonmodel|
          rule.relationship_types.each do |relationship_type|

            it "#{source_jsonmodel} #{relationship_type} #{target_jsonmodel}" do
              source_model = RelationshipRules.instance.model_for_jsonmodel_type(source_jsonmodel)
              target_model = RelationshipRules.instance.model_for_jsonmodel_type(target_jsonmodel)

              source = nil
              target = target_model.create_from_json(build("json_#{target_jsonmodel}".intern),
                                                     :repo_id => $repo_id)

              relationship_name = RelationshipRules.instance.build_relationship_jsonmodel_name(rule, relationship_type)

              relationship = JSONModel(relationship_name.intern).new
              relationship.ref = target.uri
              relationship.relator = relator_options(relationship_name).sample || raise("No relator for #{relationship_name}")
              relationship.start_date = '1999-01-01'
              relationship.end_date = '2010-12-31'
              relationship.note = generate(:generic_description)

              jsonmodel_property = RelationshipRules.instance.build_jsonmodel_property(rule.target_jsonmodel_category)

              opts = {}
              opts[jsonmodel_property] = [relationship.to_hash]

              expect {
                source = source_model.create_from_json(build("json_#{source_jsonmodel}".intern, opts),
                                                       :repo_id => $repo_id)
              }.to_not raise_error

              source_refreshed = source_model.to_jsonmodel(source.id)
              source_refreshed.send(jsonmodel_property).length.should eq(1)
              source_refreshed.send(jsonmodel_property)[0]["jsonmodel_type"].should eq(relationship_name)
              source_refreshed.send(jsonmodel_property)[0]["ref"].should eq(relationship.ref)
              source_refreshed.send(jsonmodel_property)[0]["relator"].should eq(relationship.relator)
              source_refreshed.send(jsonmodel_property)[0]["start_date"].should eq(relationship.start_date)
              source_refreshed.send(jsonmodel_property)[0]["end_date"].should eq(relationship.end_date)
              source_refreshed.send(jsonmodel_property)[0]["note"].should eq(relationship.note)

              # check reverse relationship if supported
              if RelationshipRules.instance.supported?(rule.reverse_rule)
                reverse_jsonmodel_property = RelationshipRules.instance.build_jsonmodel_property(rule.reverse_rule.target_jsonmodel_category)
                other_relator = relator_options(relationship_name).length == 1 ? relator_options(relationship_name).first : relator_options(relationship_name).reject{|r| r == relationship.relator}.first
                target_refreshed = target_model.to_jsonmodel(target.id)
                target_refreshed.send(reverse_jsonmodel_property).length.should eq(1)
                target_refreshed.send(reverse_jsonmodel_property)[0]["jsonmodel_type"].should eq(relationship_name)
                target_refreshed.send(reverse_jsonmodel_property)[0]["ref"].should eq(source.uri)
                target_refreshed.send(reverse_jsonmodel_property)[0]["relator"].should eq(other_relator)
                target_refreshed.send(reverse_jsonmodel_property)[0]["start_date"].should eq(relationship.start_date)
                target_refreshed.send(reverse_jsonmodel_property)[0]["end_date"].should eq(relationship.end_date)
                target_refreshed.send(reverse_jsonmodel_property)[0]["note"].should eq(relationship.note)
              end
            end


            it "#{source_jsonmodel} #{relationship_type} #{target_jsonmodel} date validations" do
              target_model = RelationshipRules.instance.model_for_jsonmodel_type(target_jsonmodel)

              target = target_model.create_from_json(build("json_#{target_jsonmodel}".intern),
                                                     :repo_id => $repo_id)

              relationship_name = RelationshipRules.instance.build_relationship_jsonmodel_name(rule, relationship_type)

              relationship = JSONModel(relationship_name.intern).new
              relationship.ref = target.uri
              relationship.relator = relator_options(relationship_name).sample || raise("No relator for #{relationship_name}")
              relationship.end_date = '2010-12-31'
              relationship.note = generate(:generic_description)

              # check the start_date
              relationship.start_date = 'NOT-VALID'
              expect { relationship.to_hash(:validated) }.to raise_error(JSONModel::ValidationException)

              relationship.start_date = '123'
              expect { relationship.to_hash(:validated) }.to_not raise_error

              relationship.start_date = '1111'
              expect { relationship.to_hash(:validated) }.to_not raise_error

              relationship.start_date = '1234-02-31'
              expect { relationship.to_hash(:validated) }.to raise_error(JSONModel::ValidationException)

              relationship.start_date = '2009-11-12'
              expect { relationship.to_hash(:validated) }.to_not raise_error

              relationship.start_date = '2009-01-01'

              # check the end_date
              relationship.end_date = 'NOT VALID'
              expect { relationship.to_hash(:validated) }.to raise_error(JSONModel::ValidationException)

              relationship.end_date = '2111'
              expect { relationship.to_hash(:validated) }.to_not raise_error

              relationship.end_date = '2234-02-31'
              expect { relationship.to_hash(:validated) }.to raise_error(JSONModel::ValidationException)

              relationship.end_date = '2009-11-12'
              expect { relationship.to_hash(:validated) }.to_not raise_error

              # check the start_date isn't after the end_date
              relationship.start_date = '2009-11-12'
              relationship.end_date = '2009-11-11'
              expect { relationship.to_hash(:validated) }.to raise_error(JSONModel::ValidationException)
            end

            if rule.source_jsonmodel_category != rule.target_jsonmodel_category
              it "#{source_jsonmodel} #{relationship_type} #{target_jsonmodel} ref validation" do
                source_model = RelationshipRules.instance.model_for_jsonmodel_type(source_jsonmodel)

                target = source_model.create_from_json(build("json_#{source_jsonmodel}".intern),
                                                       :repo_id => $repo_id)

                relationship_name = RelationshipRules.instance.build_relationship_jsonmodel_name(rule, relationship_type)

                relationship = JSONModel(relationship_name.intern).new
                relationship.ref = target.uri
                relationship.relator = relator_options(relationship_name).sample || raise("No relator for #{relationship_name}")

                jsonmodel_property = RelationshipRules.instance.build_jsonmodel_property(rule.target_jsonmodel_category)

                opts = {}
                opts[jsonmodel_property] = [relationship.to_hash]

                expect {
                  source_model.create_from_json(build("json_#{source_jsonmodel}".intern, opts),
                                                         :repo_id => $repo_id)
                }.to raise_error(JSONModel::ValidationException)
              end
            end
          end
        end
      end
    end
  end
end
