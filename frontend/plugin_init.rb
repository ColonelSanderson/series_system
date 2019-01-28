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
        template_erb: "mandate/template",
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
        template_erb: "function/template",
        sidebar_label: I18n.t('function._plural'),
      }
    )
  )

  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:function)
  JSONModel(:mandate)

end