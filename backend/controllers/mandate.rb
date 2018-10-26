class ArchivesSpaceService < Sinatra::Base


  Endpoint.post('/mandates/:id')
    .description("Update a mandate")
    .params(["id", :id],
            ["mandate", JSONModel(:mandate), "The updated record", :body => true])
    .permissions([:update_mandate_record])
    .returns([200, :updated]) \
  do
    with_record_conflict_reporting(Mandate, params[:mandate]) do
      handle_update(Mandate, params[:id], params[:mandate])
    end
  end


  Endpoint.post('/mandates')
    .description("Create a mandate")
    .params(["mandate", JSONModel(:mandate), "The record to create", :body => true])
    .permissions([:update_mandate_record])
    .returns([200, :created]) \
  do
    with_record_conflict_reporting(Mandate, params[:mandate]) do
      handle_create(Mandate, params[:mandate])
    end
  end


  Endpoint.get('/mandates')
    .description("Get a list of mandates")
    .params()
    .paginated(true)
    .permissions([])
    .returns([200, "[(:mandate)]"]) \
  do
    handle_listing(Mandate, params)
  end


  Endpoint.get('/mandates/:id')
    .description("Get a mandate by ID")
    .params(["id", :id],
            ["resolve", :resolve])
    .permissions([])
    .returns([200, "(:mandate)"]) \
  do
    json_response(resolve_references(Mandate.to_jsonmodel(params[:id]), params[:resolve]))
  end


  Endpoint.delete('/mandates/:id')
    .description("Delete a mandate")
    .params(["id", :id])
    .permissions([:delete_mandate_record])
    .returns([200, :deleted]) \
  do
    handle_delete(Mandate, params[:id])
  end

end
