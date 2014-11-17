module EventSorcerer
  # Public: Simple value object representing an event stream.
  class EventStream < Struct.new(:id, :events, :current_version)
  end
end
