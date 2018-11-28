ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative 'helpers/series_system_helper'

Rails.application.config.after_initialize do

  Plugins.add_resolve_field('mandates')
  Plugins.add_resolve_field('functions')
  Plugins.add_resolve_field('controlled_by')
  Plugins.add_resolve_field('location')

  Plugins.register_edit_role_for_type('mandate', 'update_mandate_record')
  Plugins.register_edit_role_for_type('function', 'update_function_record')

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'series_system',
      'controlled_by',
      ['resource'],
      {
        sidebar_label: I18n.t('controlled_by.section'),
      }
    )
  )

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'series_system',
      'mandates',
      ['resource', 'archival_object', 'agent_corporate_entity'],
      {
        template_name: 'mandate',
        js_edit_template_name: 'template_mandate',
        sidebar_label: I18n.t('mandate._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    Plugins::PluginSubRecord.new(
      'series_system',
      'functions',
      ['resource', 'archival_object'],
      {
        template_name: 'function',
        js_edit_template_name: 'template_function',
        sidebar_label: I18n.t('function._plural'),
      }
    )
  )

  Plugins.register_plugin_section(
    Plugins::PluginReadonlySearch.new(
      'series_system',
      'controlled_series',
      ['agent_corporate_entity'],
      {
        filter_term_proc: Proc.new {|record| {"controlling_agency_uri_u_sstr" => record.uri}.to_json },
        heading_text: I18n.t("agent_corporate_entity.controls"),
        sidebar_label: I18n.t("agent_corporate_entity.controls"),
      }
    )
  )

  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:function)
  JSONModel(:mandate)

end