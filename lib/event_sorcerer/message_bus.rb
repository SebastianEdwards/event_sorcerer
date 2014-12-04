module EventSorcerer
  # Public: Abstract class for an message bus implementation.
  class MessageBus
    # Public: Publish events for a specified aggregate. Should be defined in a
    #         subclass.
    #
    # _id     - UUID of the aggregate as a String.
    # _type   - Text representation of aggregate class.
    # _events - Array of Event objects.
    # _meta   - Hash of extra data to publish on the bus.
    #
    # Raises a NotImplementedError
    def publish_events(_id, _type, _events, _meta)
      fail NotImplementedError
    end
  end
end
