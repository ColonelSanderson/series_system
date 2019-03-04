require 'db/migrations/utils'
require 'json'
require 'digest/sha1'

Sequel.migration do
  up do
    json_terms = JSON.parse(File.read(File.expand_path('../plugins/series_system/migrations/data/005_subjects_thesaurus_terms.json')), symbolize_names: true)[:terms]
    transaction do
      enumeration_id = self[:enumeration][name: 'subject_term_type'][:id]
      subject_source_id = self[:enumeration][name: 'subject_source'][:id]
      source_ids = {}
      # Get unique source_id fields and create terms for them
      json_terms.uniq { |subject| subject[:source_id] }.each do |subject|
        source_ids[subject[:source_id].intern] = begin
                                                   self[:enumeration_value].insert(
                                                     enumeration_id: subject_source_id,
                                                     position: self[:enumeration_value].filter(enumeration_id: subject_source_id).max(:position) + 1,
                                                     value: subject[:source_id],
                                                     readonly: 1
                                                   )
                                                 rescue Sequel::UniqueConstraintViolation
                                                   self[:enumeration_value].filter(:value => subject[:source_id], :enumeration_id => subject_source_id).first[:id]
                                                 end
      end
      # Group subjects by their enum type
      # TODO: unique tags?
      json_terms.group_by { |json_term| json_term[:term_type] }.each do |key, term_groups|
        next_position = self[:enumeration_value].filter(enumeration_id: enumeration_id).max(:position) + 1
        enumeration_value_id =
          begin
            self[:enumeration_value].insert(
              enumeration_id: enumeration_id,
              position: next_position,
              value: key,
              readonly: 1
            )
          rescue Sequel::UniqueConstraintViolation
            self[:enumeration_value].filter(:enumeration_id => enumeration_id, :value => key).first[:id]
          end

        term_groups.each do |term|
          inserted_subject_id = self[:subject].insert(
            lock_version: 1,
            json_schema_version: 1,
            vocab_id: 1,
            title: term[:term_name],
            scope_note: term[:note],
            source_id: source_ids[term[:source_id].intern],
            created_by: 'admin',
            last_modified_by: 'admin',
            create_time: Time.now,
            system_mtime: Time.now,
            user_mtime: Time.now,
            terms_sha1: Digest::SHA1.hexdigest([[term[:term_name], term[:term_type]]].inspect)
          )
          inserted_term_id = self[:term].insert(
            lock_version: 1,
            json_schema_version: 1,
            vocab_id: 1,
            term: term[:term_name],
            term_type_id: enumeration_value_id,
            create_time: Time.now,
            system_mtime: Time.now,
            user_mtime: Time.now
          )
          # Add relationship between subject and term
          self[:subject_term].insert(
            subject_id: inserted_subject_id,
            term_id: inserted_term_id
          )
        end
      end
    end
  end
end
