ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative 'helpers/series_system_helper'

Rails.application.config.after_initialize do

  ApplicationController.class_eval do

    alias_method :find_opts_pre_series_system, :find_opts

    def find_opts
      orig = find_opts_pre_series_system
      orig.merge('resolve[]' => orig['resolve[]'] + ['mandates', 'functions'])
    end

  end


  SearchHelper.class_eval do

    alias_method :can_edit_search_result_pre_series_system?, :can_edit_search_result?

    def can_edit_search_result?(record)
      return user_can?('update_mandate_record', record['id']) if record['primary_type'] === "mandate"
      return user_can?('update_function_record', record['id']) if record['primary_type'] === "function"
      can_edit_search_result_pre_series_system?(record)
    end

  end

  PluginHelper.class_eval do

    alias_method :form_plugins_for_pre_series_system, :form_plugins_for
    def form_plugins_for(jsonmodel_type, context)
      result = form_plugins_for_pre_series_system(jsonmodel_type, context)

      if SeriesSystemHelper::supports_mandate?(context.obj['jsonmodel_type'])
        result << render_aspace_partial(:partial => "shared/subrecord_form",
                                        :locals => {
                                          :form => context,
                                          :name => 'mandates',
                                          :cardinality => :zero_to_many,
                                          :template => 'subrecord_mandate',
                                          :template_erb => 'mandates/template',
                                          :js_template_name => 'template_subrecord_mandate',
                                        })
      end

      if SeriesSystemHelper::supports_function?(context.obj['jsonmodel_type']) 
        result << render_aspace_partial(:partial => "shared/subrecord_form",
                                        :locals => {
                                          :form => context,
                                          :name => 'functions',
                                          :cardinality => :zero_to_many,
                                          :template => 'subrecord_function',
                                          :template_erb => 'functions/template',
                                          :js_template_name => 'template_subrecord_function',
                                        }) 
      end

      result.html_safe
    end


    alias_method :show_plugins_for_pre_series_system, :show_plugins_for
    def show_plugins_for(record, context)
      result = show_plugins_for_pre_series_system(record, context)

      if SeriesSystemHelper::supports_mandate?(record['jsonmodel_type'])
        if Array(record.mandates).length > 0
          result << render_aspace_partial(:partial => "mandates/show_as_subrecords",
                                          :locals => { :mandates => record.mandates,
                                                       :context => context,
                                                       :section_id => "#{record['jsonmodel_type']}_mandates_" })
        end
      end

      if SeriesSystemHelper::supports_function?(record['jsonmodel_type'])
        if Array(record.functions).length > 0
          result << render_aspace_partial(:partial => "functions/show_as_subrecords",
                                          :locals => { :functions => record.functions,
                                                       :context => context,
                                                       :section_id => "#{record['jsonmodel_type']}_functions_" })
        end
      end

      result.html_safe
    end


    alias_method :sidebar_plugins_for_pre_series_system, :sidebar_plugins_for
    def sidebar_plugins_for(record)
      result = sidebar_plugins_for_pre_series_system(record)

      if SeriesSystemHelper::supports_mandate?(record['jsonmodel_type'])
        if not controller.action_name === "show" or Array(record.mandates).length > 0
          result += "<li><a href='##{record['jsonmodel_type']}_mandates_'>#{I18n.t("mandate._plural")}<span class='glyphicon glyphicon-chevron-right'></span></a></li>".html_safe
        end
      end

      if SeriesSystemHelper::supports_function?(record['jsonmodel_type'])
        if not controller.action_name === "show" or Array(record.functions).length > 0
          result += "<li><a href='##{record['jsonmodel_type']}_functions_'>#{I18n.t("function._plural")}<span class='glyphicon glyphicon-chevron-right'></span></a></li>".html_safe
        end
      end

      result.html_safe
    end

  end

  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:function)
  JSONModel(:mandate)

end