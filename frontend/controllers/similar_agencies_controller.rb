class SimilarAgenciesController < ApplicationController

  set_access_control "view_repository" => [:index]

  def index
    raise "Missing 'name' parameter" if params[:name].blank?

    similar_agencies = JSONModel::HTTP.get_json("/similar_agencies", :name => params[:name])

    return render(:json => {
                    'matched' => !similar_agencies.empty?,
                    'markup' => render_to_string(:partial => "similar_agencies/show",
                                                 :locals => { :similar_agencies => similar_agencies })
                  })
  end

end
