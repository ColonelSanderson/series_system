ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative 'helpers/series_system_helper'
require_relative 'helpers/related_record_viewmodel'
require_relative '../lib/relationship_rules'
require_relative '../lib/hidden_fields'

Rails.application.config.after_initialize do

  Plugins.add_resolve_field('mandates')
  Plugins.add_resolve_field('functions')
  Plugins.add_resolve_field('related_functions')

  Plugins.register_edit_role_for_type('mandate', 'update_mandate_record')
  Plugins.register_edit_role_for_type('function', 'update_function_record')

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'series_system',
      'external_ids',
      ['agent_corporate_entity'],
      {
        template_name: 'external_id',
        js_edit_template_name: 'template_external_id',
        template_erb: "external_ids/edit",
        erb_edit_template_path: "external_ids/template",
        erb_readonly_template_path: "external_ids/show",
        sidebar_label: I18n.t('external_id._plural'),
      }
    )
  )

  Plugins.add_search_facets(:mandate, "mandate_type_u_ssort")
  Plugins.add_facet_group_i18n("mandate_type_u_ssort",
                               proc {|facet| "enumerations.mandate_type.#{facet}" })

  Plugins.add_search_facets(:function, "function_source_u_sstr")
  Plugins.add_facet_group_i18n("function_source_u_sstr",
                               proc {|facet| "enumerations.function_source.#{facet}" })

  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:function)
  JSONModel(:mandate)

  # Show a new search facet for our category
  Plugins.add_search_facets(:agent_corporate_entity, "agency_category_u_sstr")

  Plugins.add_facet_group_i18n("agency_category_u_sstr",
                               proc {|facet| "enumerations.agency_category.#{facet}" })


  # Series system relationships *magic*
  RelationshipRules.instance.mode(:frontend).bootstrap!

  class SeriesSystemRelationshipSubRecord < Plugins::AbstractPluginSection

    def render_edit(view_context, record, form_context)
      view_context.render_aspace_partial(
        :partial => "series_system_relationships/form",
        :locals => {
          :form => form_context,
          :name => @name,
          :source_jsonmodel_type => @source_jsonmodel_type,
          :rule => @rule,
          :template_prefix => @template_prefix,
          :section_id => @section_id,
          :relationship_jsonmodel_types => @relationship_jsonmodel_types,
        })
    end

    def render_readonly(view_context, record, form_context)
      view_context.render_aspace_partial(
        :partial => "series_system_relationships/show_as_subrecord",
        :locals => { :relationships => record.send(@name.intern),
                     :context => form_context,
                     :section_id => @section_id,
                     :name => @name,
                     :rule => @rule })
    end

    def supports?(record, mode)
      result = super
      if result && mode == :readonly
        Array(record.send(@name.intern)).length > 0
      else
        result
      end
    end

    private

    def parse_opts(opts)
      super
      @name = opts.fetch(:name)
      @sidebar_label = opts.fetch(:sidebar_label)
      @template_prefix = opts.fetch(:template_prefix)
      @rule = opts.fetch(:rule)
      @relationship_jsonmodel_types = opts.fetch(:relationship_jsonmodel_types)
      @source_jsonmodel_type = opts.fetch(:source_jsonmodel_type)
      @section_id = "#{@source_jsonmodel_type}_#{@name}_"
    end
  end

  all_series_system_relationship_properties = []

  RelationshipRules.instance.rules.each do |rule|
    source_jsonmodel_types = RelationshipRules.instance.jsonmodel_expander(rule.source_jsonmodel_category)
    source_jsonmodel_property =  RelationshipRules.instance.build_jsonmodel_property(rule.target_jsonmodel_category)

    if RelationshipRules.instance.supported?(rule)
      all_series_system_relationship_properties << source_jsonmodel_property

      source_jsonmodel_types.each do |source_jsonmodel_type|

        relationship_jsonmodel_types = []
          rule.relationship_types.each do |relationship_type|
          relationship_jsonmodel_types << RelationshipRules.instance.build_relationship_jsonmodel_name(rule, relationship_type)
        end

        Plugins.register_plugin_section(
          SeriesSystemRelationshipSubRecord.new(
            'series_system',
            "series_system_relationships_#{source_jsonmodel_property}",
            [source_jsonmodel_type.to_s],
            {
              name: source_jsonmodel_property,
              rule: rule,
              source_jsonmodel_type: source_jsonmodel_type,
              target_jsonmodel_category: rule.target_jsonmodel_category,
              sidebar_label: I18n.t("series_system_relationships.relationship_names.#{source_jsonmodel_property}"),
              template_prefix: "series_system_#{source_jsonmodel_type}_to_#{rule.target_jsonmodel_category}",
              relationship_jsonmodel_types: relationship_jsonmodel_types,
            }
          )
        )

        # add handy tooltips!
        I18n.backend.store_translations(:en,
                                        {
                                          source_jsonmodel_type.intern =>
                                          {
                                            "series_system_#{rule.target_jsonmodel_category}_relationships_tooltip".intern =>
                                            "Used for linking #{rule.target_jsonmodel_category}s"
                                          }
                                        })
      end
    else
      reverse_jsonmodel_property =  RelationshipRules.instance.build_jsonmodel_property(rule.source_jsonmodel_category)
      Plugins.register_plugin_section(
        Plugins::PluginReadonlySearch.new(
          'series_system',
          "series_system_relationships_#{source_jsonmodel_property}",
          source_jsonmodel_types.collect(&:to_s),
          {
            filter_term_proc: proc { |record| { "#{rule.target_jsonmodel_category}_#{reverse_jsonmodel_property}_u_sstr" => record.uri }.to_json },
            heading_text: I18n.t("series_system_relationships.relationship_names.#{source_jsonmodel_property}"),
            sidebar_label: I18n.t("series_system_relationships.relationship_names.#{source_jsonmodel_property}"),
            erb_template: 'series_system_relationships/search',
          }
        )
      )
    end
  end

  Plugins.add_resolve_field(all_series_system_relationship_properties.uniq)

  require_relative '../lib/validations'
  include SeriesSystemValidations
end


