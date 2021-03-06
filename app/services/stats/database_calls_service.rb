class Stats::DatabaseCallsService < Stats::BaseService
  def call
    orders = {
      "Freq" => "COUNT(*) DESC",
      "Avg" => "(SUM(exclusive_duration) / COUNT(*)) DESC",
      "FreqAvg" => "(COUNT(DISTINCT trace_key) * SUM(exclusive_duration) / COUNT(*)) DESC"
    }

    application
      .database_calls
      .with(:trace_cte => traces)
      .joins(:span => :layer)
      .where("spans.trace_key IN (SELECT trace_key FROM trace_cte)")
      .where("statement IS NOT NULL")
      .group("layers.id, layers.name, database_calls.statement")
      .order(Arel.sql(orders[params[:_order]] || orders["FreqAvg"]))
      .limit(LIMITS[params[:_limit]] || LIMITS["10"])
      .pluck_to_hash(
        "layers.id AS layer_id",
        "layers.name AS layer_name",
        "database_calls.statement AS statement",
        "MAX(database_calls.id::varchar) AS id",
        "COUNT(*) AS freq",
        "SUM(database_calls.duration) / COUNT(*) AS avg"
      )
  end
end
