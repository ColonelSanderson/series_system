class IndexerCommon

  @@record_types << :mandate
  @@record_types << :function
  @@resolved_attributes << 'mandates'
  @@resolved_attributes << 'functions'

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'mandate'
        doc['title'] = record['record']['title']
        doc['display_string'] = record['record']['title']
      end
    }

    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'function'
        doc['title'] = record['record']['title']
        doc['display_string'] = record['record']['title']
      end
    }

  end

end