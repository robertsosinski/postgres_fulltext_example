class ActiveRecord::Base
  # helper methods to access search related information
  def search_rank
    @_search_rank
  end
  
  def search_result?
    @_search_result || false
  end

  def search_headlines
    @_search_headlines || {}
  end
end
