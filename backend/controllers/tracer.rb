require_relative '../../lib/relationship_rules'

class ArchivesSpaceService < Sinatra::Base

  RelationshipRules.instance.all_jsonmodels.each do |jsonmodel|

    uri = JSONModel.JSONModel(jsonmodel).schema.fetch('uri')

    model = ASModel.all_models.find{|m| m.has_jsonmodel? && m.my_jsonmodel.record_type.intern == jsonmodel}

    base_params = [ ['id', :id]]
    base_params << ['repo_id', :repo_id] if uri.match(/:repo_id/)

    Endpoint.get("#{uri}/:id/trace")
      .description("Trace relationships for all relators")
      .params(
              *base_params)
      .permissions([])
      .returns([200, "[String]"]) \
    do
      json_response(model.get_or_die(params[:id]).trace_all(:full => true))
    end


    Endpoint.get("#{uri}/:id/trace/:relator")
      .description("Trace relationships with relator")
      .params(['relator', String, 'The relator to trace'],
              *base_params)
      .permissions([])
      .returns([200, "[String]"]) \
    do
      json_response(model.get_or_die(params[:id]).trace(params[:relator], :full => true))
    end


  end
end
