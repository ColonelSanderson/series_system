class ArchivesSpaceService < Sinatra::Base

  Endpoint.post('/repositories')
    .description("Create a Repository")
    .params(["repository", JSONModel(:repository), "The record to create", :body => true])
    .permissions([:create_repository])
    .returns([200, :created],
             [400, :error],
             [403, :access_denied]) \
  do

      # we need to check if the Agent for the repo has already been created 
      nce =  NameCorporateEntity.find(Sequel.like(:primary_name,params[:repository]['repo_code']))
    
      unless nce.nil?
        agent_id = nce.agent_corporate_entity_id
      else 
        # Create a dummy agent for this repository, since none was specified.
        name = {
          'primary_name' => params[:repository]['repo_code'],
          'sort_name' => params[:repository]['repo_code'],
          'source' => 'local'
        }

        contact = {
          'name' => params[:repository]['repo_code']
        }

        json = JSONModel(:agent_corporate_entity).from_hash('names' => [name],
                                                            'dates_of_existence' => [{
                                                                                     'label' => 'existence',
                                                                                     'date_type' => 'range',
                                                                                     'begin' => Time.now.strftime('%Y-%m-%d')}],
                                                            'agent_contacts' => [contact])
        agent = AgentCorporateEntity.create_from_json(json)
        agent_id = agent.id 
   
      end
      
    
    handle_create(Repository, params[:repository], :agent_representation_id => agent_id)
  end

end
