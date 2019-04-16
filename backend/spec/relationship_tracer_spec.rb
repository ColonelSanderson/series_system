require 'spec_helper'

describe 'Series System' do

  describe 'Relationship Tracer' do

    it 'traces linear relationships' do

      really_old_agency =
        create(:json_agent_corporate_entity,
               :dates_of_existence => [{
                                         :label => 'existence',
                                         :date_type => 'range',
                                         :begin => '1900-01-01',
                                         :end => '1999-01-01'
                                       }])

      old_agency =
        create(:json_agent_corporate_entity,
               :dates_of_existence => [{
                                         :label => 'existence',
                                         :date_type => 'range',
                                         :begin => '1999-01-01',
                                         :end => '2001-01-01'
                                       }],
               :series_system_agent_relationships => [
                                                      {
                                                        :jsonmodel_type => 'series_system_agent_agent_succession_relationship',
                                                        :relator => 'supercedes',
                                                        :start_date => '1999-01-01',
                                                        :ref => really_old_agency.uri
                                                      }
                                                     ])

      current_agency =
        create(:json_agent_corporate_entity,
               :dates_of_existence => [{
                                         :label => 'existence',
                                         :date_type => 'range',
                                         :begin => '2019-01-01'
                                       }],
               :series_system_agent_relationships => [
                                                      {
                                                        :jsonmodel_type => 'series_system_agent_agent_succession_relationship',
                                                        :relator => 'supercedes',
                                                        :start_date => '2001-01-01',
                                                        :ref => old_agency.uri
                                                      }
                                                     ])

      ca_obj = AgentCorporateEntity[current_agency.id]
      oa_obj = AgentCorporateEntity[old_agency.id]
      roa_obj = AgentCorporateEntity[really_old_agency.id]

      ca_obj.trace('supercedes').flatten.should eq([old_agency.uri, really_old_agency.uri])
      oa_obj.trace('supercedes').flatten.should eq([really_old_agency.uri])
      roa_obj.trace('supercedes').flatten.should eq([])

      roa_obj.trace('precedes').flatten.should eq([old_agency.uri, current_agency.uri])

      ca_obj.trace('supercedes', :steps => 1).flatten.should eq([old_agency.uri])      
    end


    it 'does not mind which side the relationship is defined on' do
      agent = create(:json_agent_corporate_entity)

      function =
        create(:json_function,
               :series_system_agent_relationships => [
                                                         {
                                                           :jsonmodel_type => 'series_system_agent_function_administers_relationship',
                                                           :relator => 'is_administered_by',
                                                           :start_date => '2019-01-01',
                                                           :ref => agent.uri
                                                         }
                                                        ])

      AgentCorporateEntity[agent.id].trace('administered').flatten.should eq([function.uri])
      Function[function.id].trace('is_administered_by').flatten.should eq([agent.uri])

      function = create(:json_function)

      agent =
        create(:json_agent_corporate_entity,
               :series_system_function_relationships => [
                                                         {
                                                           :jsonmodel_type => 'series_system_agent_function_administers_relationship',
                                                           :relator => 'administered',
                                                           :start_date => '2019-01-01',
                                                           :ref => function.uri
                                                         }
                                                        ])

      AgentCorporateEntity[agent.id].trace('administered').flatten.should eq([function.uri])
      Function[function.id].trace('is_administered_by').flatten.should eq([agent.uri])
    end


    it 'traces branching relationships' do

      rel = {
        :jsonmodel_type => 'series_system_agent_agent_containment_relationship',
        :relator => 'is_contained_within',
        :start_date => '2019-01-01',
      }

      root = create(:json_agent_corporate_entity)

      child1 = create(:json_agent_corporate_entity,
                      :series_system_agent_relationships => [rel.merge(:ref => root.uri)])

      child2 = create(:json_agent_corporate_entity,
                      :series_system_agent_relationships => [rel.merge(:ref => root.uri)])

      child3 = create(:json_agent_corporate_entity,
                      :series_system_agent_relationships => [rel.merge(:ref => root.uri)])

      child4 = create(:json_agent_corporate_entity,
                      :series_system_agent_relationships => [rel.merge(:ref => root.uri)])

      child1_1 = create(:json_agent_corporate_entity,
                        :series_system_agent_relationships => [rel.merge(:ref => child1.uri)])

      child1_2 = create(:json_agent_corporate_entity,
                        :series_system_agent_relationships => [rel.merge(:ref => child1.uri)])

      child2_1 = create(:json_agent_corporate_entity,
                        :series_system_agent_relationships => [rel.merge(:ref => child2.uri)])

      child3_1 = create(:json_agent_corporate_entity,
                        :series_system_agent_relationships => [rel.merge(:ref => child3.uri)])

      child3_2 = create(:json_agent_corporate_entity,
                        :series_system_agent_relationships => [rel.merge(:ref => child3.uri)])

      child3_3 = create(:json_agent_corporate_entity,
                        :series_system_agent_relationships => [rel.merge(:ref => child3.uri)])

      root_obj = AgentCorporateEntity[root.id]

      root_obj.trace('is_contained_within').should eq([])

      root_obj.trace('contains').should eq(
                                           [ 
                                             [ child1.uri, [child1_1.uri, child1_2.uri] ],
                                             [ child2.uri, [child2_1.uri] ],
                                             [ child3.uri, [child3_1.uri, child3_2.uri, child3_3.uri] ],
                                             child4.uri
                                           ]
                                          )
    end


    it "respects step limits" do
      rel = {
        :jsonmodel_type => 'series_system_mandate_mandate_succession_relationship',
        :relator => 'supercedes',
        :start_date => '1950',
      }

      first = create(:json_mandate)
      second = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => first.uri)])
      third = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => second.uri)])
      fourth = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => third.uri)])
      fifth = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => fourth.uri)])

      first_obj = Mandate[first.id]

      first_obj.trace('precedes').flatten.should eq([second.uri, third.uri, fourth.uri, fifth.uri])
      first_obj.trace('precedes', :steps => 2).flatten.should eq([second.uri, third.uri])

      expect { first_obj.trace('precedes', :steps => 2, :raise_on_step_limit => true).flatten }.to raise_error(RelationshipTracer::StepLimitExceeded)
    end


    it "objects if you give it an unknown relator" do
      rel = {
        :jsonmodel_type => 'series_system_function_mandate_abolition_relationship',
        :relator => 'is_abolished_by',
        :start_date => '1864',
      }

      mandate = create(:json_mandate)
      function = create(:json_function, :series_system_mandate_relationships => [rel.merge(:ref => mandate.uri)])

      mandate_obj = Mandate[mandate.id]

      mandate_obj.trace('abolished').flatten.should eq([function.uri])

      expect { mandate_obj.trace('ablution') }.to raise_error(RelationshipTracer::UnknownRelator)
    end


    it "supports returning a flat array" do
      rel = {
        :jsonmodel_type => 'series_system_mandate_mandate_succession_relationship',
        :relator => 'supercedes',
        :start_date => '1950',
      }

      first = create(:json_mandate)
      second = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => first.uri)])
      third = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => second.uri)])

      Mandate[third.id].trace_set('supercedes').should eq([second.uri, first.uri])
    end


    it "provides a convenient way to only take one step" do
      rel = {
        :jsonmodel_type => 'series_system_mandate_mandate_succession_relationship',
        :relator => 'supercedes',
        :start_date => '1950',
      }

      first = create(:json_mandate)
      second = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => first.uri)])
      third = create(:json_mandate, :series_system_mandate_relationships => [rel.merge(:ref => second.uri)])

      Mandate[third.id].trace_one('supercedes').should eq([second.uri])
    end

  end
end
