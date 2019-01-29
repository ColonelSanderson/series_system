class IndexerCommon

  @@record_types << :mandate
  @@record_types << :function
  @@resolved_attributes << 'mandates'
  @@resolved_attributes << 'functions'

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['jsonmodel_type'] == 'mandate'
        doc['display_string'] = record['record']['display_string']

        doc.delete('title')
        doc['mandate_title__u_sstr'] = record['record']['title']
        doc['title_sort'] = record['record']['title']
        doc['mandate_type_u_ssort'] = record['record']['mandate_type']

        doc['commencement_date_u_sortdate'] = IndexerCommon.extract_commencement_date_for_search(record['record']['date'])
        doc['commencement_date_u_sstr'] = IndexerCommon.extract_commencement_date_for_display(record['record']['date'])
        doc['termination_date_u_sortdate'] = IndexerCommon.extract_termination_date_for_search(record['record']['date'])
        doc['termination_date_u_sstr'] = IndexerCommon.extract_termination_date_for_display(record['record']['date'])
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if record['record']['jsonmodel_type'] == 'function'
        doc['display_string'] = record['record']['display_string']

        doc.delete('title')
        doc['function_title__u_sstr'] = record['record']['title']
        doc['title_sort'] = record['record']['title']
        doc['function_source_u_sstr'] = record['record']['source']

        doc['commencement_date_u_sortdate'] = IndexerCommon.extract_commencement_date_for_search(record['record']['date'])
        doc['commencement_date_u_sstr'] = IndexerCommon.extract_commencement_date_for_display(record['record']['date'])
        doc['termination_date_u_sortdate'] = IndexerCommon.extract_termination_date_for_search(record['record']['date'])
        doc['termination_date_u_sstr'] = IndexerCommon.extract_termination_date_for_display(record['record']['date'])
      end
    end

    indexer.add_document_prepare_hook do |doc, record|
      if ['agent_corporate_entity'].include?(record['record']['jsonmodel_type'])
        doc['agency_category_u_sstr'] = record['record']['agency_category']
      end
    end


    indexer.add_document_prepare_hook do |doc, record|
      if ['resource', 'archival_object', 'agent_corporate_entity'].include?(record['record']['jsonmodel_type'])
        doc['mandate_uris_u_sstr'] = ASUtils.wrap(record['record']['mandates']).collect{|m| m['ref']}
        doc['function_uris_u_sstr'] = ASUtils.wrap(record['record']['functions']).collect{|f| f['ref']}
      end
    end

  end

  def self.extract_commencement_date_for_search(date)
    return nil unless date && date['begin']

    # Format YYYY-MM-DD as YYYY-MM-DDT00:00:00Z
    if date['begin'] =~ /\d{4}\-\d{2}\-\d{2}/
    date['begin'] + "T00:00:00Z"

    # Format YYYY-MM as YYYY-MM-01T00:00:00Z
    elsif date['begin'] =~ /\d{4}\-\d{2}/
      date['begin'] + "-01T00:00:00Z"

    # Format YYYY as YYYY-01-01T00:00:00Z
    elsif date['begin'] =~ /d{4}/
      date['begin'] + "-01-01T00:00:00Z"

    # Not a date we can deal with
    else
      nil
    end
  end

  def self.extract_commencement_date_for_display(date)
    return nil unless date

    date['begin']
  end

  def self.extract_termination_date_for_search(date)
    return nil unless date && date['end']

    # Format YYYY-MM-DD as YYYY-MM-DDT00:00:00Z
    if date['end'] =~ /\d{4}\-\d{2}\-\d{2}/
      date['end'] + "T00:00:00Z"

    # Format YYYY-MM as YYYY-MM-XXT00:00:00Z
    elsif date['end'] =~ /\d{4}\-\d{2}/
      first_day_of_month = Date::strptime(date['end'] + "-01", "%Y-%m-%d")
      last_day_of_month = first_day_of_month.next_month.prev_day
      last_day_of_month.strftime("%Y-%m-%d") + "T00:00:00Z"

    # Format YYYY as YYYY-12-31T00:00:00Z
    elsif date['end'] =~ /d{4}/
      date['end'] + "-12-31" + "T00:00:00Z"

    # Not a date we can deal with
    else
      nil
    end
  end

  def self.extract_termination_date_for_display(date)
    return nil unless date

    date['end']
  end
end
