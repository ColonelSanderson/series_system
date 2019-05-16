# An optionally-opened-ended date range.
class DateRange
  attr_reader :start_date, :end_date

  def initialize(start_date, end_date)
    @start_date = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    @end_date = end_date.is_a?(String) ? Date.parse(end_date) : end_date

    raise unless @end_date.nil? || @start_date <= @end_date
  end

  def to_s
    [@start_date.strftime("%Y-%m-%d"), @end_date ? @end_date.strftime("%Y-%m-%d") : ""].join(" -- ")
  end

  def inspect
    "<#DateRange #{to_s}>"
  end

  # Split the current range by removing any dates included in `other_range`.
  #
  # If the two ranges are non-overlapping, it's a no-op.
  #
  # If the two ranges are identical, returns an empty array.
  #
  # Otherwise, returns an array of the remaining DateRange segments.
  #
  def remove_range(other_range)
    if ((other_range.end_date && other_range.end_date < @start_date) ||
        (@end_date && other_range.start_date > @end_date))
      # No overlap in these ranges
      return [self]
    end

    result = []

    if @start_date < other_range.start_date
      result << DateRange.new(@start_date, other_range.start_date - 1)
    end

    if (other_range.end_date && @end_date) && other_range.end_date < @end_date
      result << DateRange.new(other_range.end_date + 1, @end_date)
    end

    if @end_date.nil? && other_range.end_date
      result << DateRange.new(other_range.end_date + 1, nil)
    end

    result
  end
end

