class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/functions/:id')
    .description("Update a function")
    .params(["id", :id],
            ["function", JSONModel(:function), "The updated record", :body => true])
    .permissions([:update_function_record])
    .returns([200, :updated]) \
  do
    with_record_conflict_reporting(Function, params[:function]) do
      handle_update(Function, params[:id], params[:function])
    end
  end


  Endpoint.post('/functions')
    .description("Create a function")
    .params(["function", JSONModel(:function), "The record to create", :body => true])
    .permissions([:update_function_record])
    .returns([200, :created]) \
  do
    with_record_conflict_reporting(Function, params[:function]) do
      handle_create(Function, params[:function])
    end
  end


  Endpoint.get('/functions')
    .description("Get a list of functions")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:function)]"]) \
  do
    handle_listing(Function, params)
  end


  Endpoint.get('/functions/:id')
    .description("Get a function by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:function)"]) \
  do
    json_response(resolve_references(Function.to_jsonmodel(params[:id]), params[:resolve]))
  end


  Endpoint.delete('/functions/:id')
    .description("Delete a function")
    .params(["id", :id])
    .permissions([:delete_function_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Function, params[:id])
  end

end
