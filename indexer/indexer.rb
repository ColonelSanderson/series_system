class IndexerCommon

  @@record_types << :mandate
  @@record_types << :function
  @@resolved_attributes << 'mandates'
  @@resolved_attributes << 'functions'

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['jsonmodel_type'] == 'mandate'
        doc['title'] = record['record']['title']
        doc['display_string'] = record['record']['display_string']
        doc['mandate_type_u_ssort'] = record['record']['mandate_type']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['jsonmodel_type'] == 'function'
        doc['title'] = record['record']['title']
        doc['display_string'] = record['record']['display_string']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if ['resource', 'archival_object', 'agent_corporate_entity'].include?(record['record']['jsonmodel_type'])
        doc['mandate_uris_u_sstr'] = ASUtils.wrap(record['record']['mandates']).collect{|m| m['ref']}
        doc['function_uris_u_sstr'] = ASUtils.wrap(record['record']['functions']).collect{|f| f['ref']}
      end
    end

  end
end