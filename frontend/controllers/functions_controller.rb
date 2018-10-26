class FunctionsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show],
                      "update_function_record" => [:new, :edit, :create, :update],
                      "delete_function_record" => [:delete]


  def index
    respond_to do |format|
      format.html {
        @search_data = Search.for_type(session[:repo_id], "function", {"sort" => "title_sort asc"}.merge(params_for_backend_search))
      }
      format.csv {
        search_params = params_for_backend_search.merge({ "sort" => "title_sort asc",  "facet[]" => []})
        uri = "/search/functions"
        csv_response( uri, search_params )
      }
    end
  end


  def show
    @function = JSONModel(:function).find(params[:id], find_opts)
  end


  def new
    @function = JSONModel(:function).new._always_valid!

    if user_prefs['default_values']
      defaults = DefaultValues.get 'function'

      @function.update(defaults.values) if defaults
    end

    render_aspace_partial :partial => "functions/new" if inline?
  end


  def edit
    @function = JSONModel(:function).find(params[:id], find_opts)
  end


  def create
    handle_crud(:instance => :function,
                :model => JSONModel(:function),
                :on_invalid => ->(){
                  return render_aspace_partial :partial => "functions/new" if inline?
                  return render :action => :new
                },
                :on_valid => ->(id){
                  if inline?
                    render :json => @function.to_hash if inline?
                  else
                    flash[:success] = I18n.t("function._frontend.messages.created")
                    return redirect_to :controller => :functions, :action => :new if params.has_key?(:plus_one)
                    redirect_to :controller => :functions, :action => :edit, :id => id
                  end
                })
  end

  def update
    handle_crud(:instance => :function,
                :model => JSONModel(:function),
                :obj => JSONModel(:function).find(params[:id]),
                :on_invalid => ->(){ return render :action => :edit },
                :on_valid => ->(id){
                  flash[:success] = I18n.t("function._frontend.messages.updated")
                  redirect_to :controller => :functions, :action => :edit, :id => id
                })
  end


  def delete
    function = JSONModel(:function).find(params[:id])
    function.delete

    flash[:success] = I18n.t("function._frontend.messages.deleted", JSONModelI18nWrapper.new(:function => function))
    redirect_to(:controller => :functions, :action => :index, :deleted_uri => function.uri)
  end

end
