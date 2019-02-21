class SimilarAgencyQuery < Solr::Query

  MAX_SUGGESTIONS = 5
  SOLR_CHARS = '+-&|!(){}[]^"~*?:\\/'

  def initialize(agency_name)
    super
    @agency_name = agency_name
  end

  def to_solr_url
    pagination(0, MAX_SUGGESTIONS)

    url = @solr_url
    url.path += "/select"
    url.query = URI.encode_www_form([[:q, 'agency_name_u_stext:(' + build_query(@agency_name) + ')'],
                                     [:fq, 'primary_type:agent_corporate_entity'],
                                     [:fl, 'agency_name_u_stext uri'],
                                     [:mm, '3<75%'],
                                     [:wt, 'json'],
                                     [:start, 0],
                                     [:rows, MAX_SUGGESTIONS]])

    url
  end

  def empty?
    build_query(@agency_name).empty?
  end


  private

  def solr_escape(s)
    pattern = Regexp.quote(SOLR_CHARS)
    s.gsub(/([#{pattern}])/, '\\\\\1')
  end

  def build_query(s)
    s.split(' ')
      .reject(&:empty?)
      .map {|term| solr_escape(term)}
      .join(' ')
  end

end
