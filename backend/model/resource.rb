Resource.include(FunctionsArchivalRecords)
Resource.include(MandatesArchivalRecords)
Resource.include(AutoGenerator)

class Resource

  auto_generate :property => :id_0,
                :generator => proc { |json| Sequence.get('SERIES_SYSTEM_RESOURCE_ID_0').to_s },
                :only_if_nil => true

end
