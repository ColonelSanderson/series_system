class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/similar_agencies')
    .description("Return a list of agencies with names similar to `name`")
    .params(["name", String])
    .permissions([])
    .returns([200, "[String]"]) \
  do
    query = SimilarAgencyQuery.new(params[:name])

    if query.empty?
      return json_response({})
    end

    result = Solr.search(query)

    if result['total_hits'] >= result['page_size']
      # We got a lot of hits, so the results were probably too generic to be useful.
      json_response({})
    else
      json_response(result['results'].map {|r|
                      {
                        'uri' => r['uri'],
                        'name' => r['agency_name_u_stext'][0],
                      }
                    })
    end
  end

end
