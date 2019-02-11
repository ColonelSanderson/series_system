ArchivalObject.include(FunctionsArchivalRecords)
ArchivalObject.include(MandatesArchivalRecords)

class ArchivalObject

  auto_generate :property => :ref_id,
                :generator => proc { |json| Sequence.get('SERIES_SYSTEM_REF_ID').to_s },
                :only_on_create => true

end
