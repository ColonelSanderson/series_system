class SeriesSystemRelationshipsController < ApplicationController

  set_access_control  "view_repository" => [:search]

  def search
    respond_to do |format|
      format.json {
        raise "Not supported"
      }
      format.js {
        if params[:listing_only]
          @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))
          @display_identifier = false

          render_aspace_partial :partial => "series_system_relationships/listing", locals: { filter_property: params[:filter_property], filter_value: params[:filter_value],  }
        else
          raise "Not supported"
        end
      }
      format.html {
        raise "Not supported"
      }
      format.csv {
        raise "Not supported"
      }
    end
  end
end