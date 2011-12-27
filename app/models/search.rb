module Search
  module_function

  # search all entities in the database
  #
  # search for buffy or vampire
  #  Search.new("buffy | vampire")
  #
  # search for buffy and vampire
  #  Search.new("buffy & vampire")
  #
  # search using a phrase instad of a query by wrapping the phrase in single quotes
  #  Search.new("'buffy vampire'")
  #
  # search using a limit of 20 (default 10) and an offset of 40 (default 0)
  #  Search.new("'slayer'", 20, 40)
  def new(query, limit = nil, page = nil)
    # as rails does not support eager loading on polymorphic associations, with headlines,
    # when conditions include text-search ranking, we have to do it ourselves.

    # 1. return `[]` if no query is given
    return [] if query.empty?

    # 2. return list of search results
    results = Database.select_all(["select * from search(cast(? as text), ?, ?)", query, limit, page])

    # 3. gather the model and id for each search result
    mapped_results = results.map do |result|
      [result["model"], result["id"]]
    end
    
    # 4. associate each id with its respective model
    reduced_results = mapped_results.reduce({}) do |memo, (model, id)|
      memo[model] ? memo[model] << id : memo[model] = [id]
      memo
    end

    # 5. replace the list of ids with a list of objects, using an `in` query
    reduced_results.keys.each do |model|
      reduced_results[model] = model.constantize.find(reduced_results[model])
    end

    # 6. replace each search result with its respective object, including headlines and search rank
    results.map do |result|
      searchable = reduced_results[result["model"]].detect{|model| model.id == result["id"].to_i}
      searchable.instance_variable_set(:@_search_rank, result["search_rank"].to_f)
      searchable.instance_variable_set(:@_search_result, true)
      searchable.instance_variable_set(:@_search_headlines, {})

      result.keys.select{|key| key.match(/^headlined_/)}.each do |headline|
        key, value = headline.sub(/^headlined_/, "").to_sym, result[headline]
        searchable.search_headlines[key] = value if value.present?
      end

      searchable
    end
  end

  # builds a text-search query that is good for autocomplete, all partial words must be found
  # e.g. "  Buff The VAMP Slayer  " -> "buff:* & the:* & vamp:* & slayer:*"
  #
  # search for 20 entities, with an offset of 40, for a given suggestion
  #  Search.suggest("  Buff The VAMP Slayer  ", 20, 40)
  def suggest(query, *args)
    q = query.
        to_s.                       # 1. typecase into a string
        strip.                      # 2. remove leading and tailing whitespace
        downcase.                   # 3. make all lowercase
        gsub(/[^[:alnum:]\s]/, ''). # 4. remove all non-alphanumberic and non-space characters
        gsub(/\s+/, ' ').           # 5. replace multiple spaces with just one space
        gsub(/[\s]/, ':* & ').      # 6. convert spaces into prefix matchers
        gsub(/$/, ':*')             # 7. make the last token a prefix matcher as well
    
    new(q, *args)
  end
end
