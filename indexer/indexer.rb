class IndexerCommon

  @@record_types << :mandate
  @@record_types << :function
  @@resolved_attributes << 'mandates'
  @@resolved_attributes << 'functions'

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['jsonmodel_type'] == 'mandate'
        doc['title'] = record['record']['title']
        doc['display_string'] = "#{record['record']['identifier']}: #{record['record']['title']}"
        doc['mandate_type_u_ssort'] = record['record']['mandate_type']
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['jsonmodel_type'] == 'function'
        doc['title'] = record['record']['title']
        doc['display_string'] = "#{record['record']['identifier']}: #{record['record']['title']}"
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if ['resource', 'archival_object'].include?(record['record']['jsonmodel_type'])
        doc['controlling_agency_uri_u_sstr'] = ASUtils.wrap(record['record']['controlled_by']).map { |agency| agency['ref'] }
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if ['function', 'mandate'].include?(doc['primary_type']) && record['record'] && record['record'].length > 0
        doc['location_uris'] = record['record']['location']
      end
    end

  end

end