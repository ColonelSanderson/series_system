ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative 'helpers/series_system_helper'

Rails.application.config.after_initialize do

  Plugins.add_resolve_field('mandates')
  Plugins.add_resolve_field('functions')
  Plugins.add_resolve_field('related_functions')

  Plugins.register_edit_role_for_type('mandate', 'update_mandate_record')
  Plugins.register_edit_role_for_type('function', 'update_function_record')

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'series_system',
      'mandates',
      ['resource', 'archival_object', 'agent_corporate_entity'],
      {
        template_name: 'mandate_rlshp',
        js_edit_template_name: 'template_mandate_rlshp',
        template_erb: "mandates/template",
        sidebar_label: I18n.t('mandate._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'series_system',
      'functions',
      ['resource', 'archival_object', 'agent_corporate_entity'],
      {
        template_name: 'function_rlshp',
        js_edit_template_name: 'template_function_rlshp',
        template_erb: "functions/template",
        sidebar_label: I18n.t('function._plural'),
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

end
