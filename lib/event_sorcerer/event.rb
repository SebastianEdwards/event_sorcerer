module EventSorcerer
  # Public: Simple value object representing an event.
  class Event < Struct.new(:name, :created_at, :details)
  end
end
