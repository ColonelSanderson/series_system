class MandatesController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_mandate_record" => [:new, :edit, :create, :update],
                      "delete_mandate_record" => [:delete]


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "mandate", {"sort" => "title_sort asc"}.merge(params_for_backend_search))
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/mandates"
        csv_response( uri, search_params )
      }
    end
  end


  def show
    @mandate = JSONModel(:mandate).find(params[:id], find_opts)
  end


  def new
    @mandate = JSONModel(:mandate).new._always_valid!

    if user_prefs['default_values']
      defaults = DefaultValues.get 'mandate'

      @mandate.update(defaults.values) if defaults
    end

    render_aspace_partial :partial => "mandates/new" if inline?
  end


  def edit
    @mandate = JSONModel(:mandate).find(params[:id], find_opts)
  end


  def create
    handle_crud(:instance => :mandate,
                :model => JSONModel(:mandate),
                :on_invalid => ->(){
                  return render_aspace_partial :partial => "mandates/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  if inline?
                    render :json => @mandate.to_hash if inline?
                  else
                    flash[:success] = I18n.t("mandate._frontend.messages.created")
                    return redirect_to :controller => :mandates, :action => :new if params.has_key?(:plus_one)
                    redirect_to :controller => :mandates, :action => :edit, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :mandate,
                :model => JSONModel(:mandate),
                :obj => JSONModel(:mandate).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("mandate._frontend.messages.updated")
                  redirect_to :controller => :mandates, :action => :edit, :id => id
                })
  end


  def delete
    mandate = JSONModel(:mandate).find(params[:id])
    mandate.delete

    flash[:success] = I18n.t("mandate._frontend.messages.deleted", JSONModelI18nWrapper.new(:mandate => mandate))
    redirect_to(:controller => :mandates, :action => :index, :deleted_uri => mandate.uri)
  end


  def current_record
    @mandate
  end

end
