module EventSorcerer
  # Public: Abstract class for event store errors.
  class EventStoreError < StandardError; end

  # Public: Error raised when given uuid is in invalid format.
  class InvalidUUID < EventStoreError; end

  # Public: Error raised when expected version doesn't match current stored
  #         version.
  class UnexpectedVersionNumber < EventStoreError; end

  # Public: Abstract class for an event store implementation.
  class EventStore
    # Public: Append events to a specified aggregate. Should be defined in a
    #         subclass.
    #
    # _id               - UUID of the aggregate as a String.
    # _type             - Text representation of aggregate class.
    # _events           - Array of JSON-serialized events.
    # _expected_version - The current version of the aggregate.
    #
    # Raises a NotImplementedError
    def append_events(_id, _type, _events, _expected_version)
      fail NotImplementedError
    end

    # Public: Retrieve the current version for a specified aggregate. Should
    #         be defined in a subclass.
    #
    # _id - UUID of the aggregate as a String.
    #
    # Raises a NotImplementedError
    def get_current_version(_id, _type)
      fail NotImplementedError
    end

    # Public: Retrieve the IDs for a given aggregate class. Should be defined
    #         in a subclass.
    #
    # _type - Text representation of aggregate class.
    #
    # Raises a NotImplementedError
    def get_ids_for_type(_type)
      fail NotImplementedError
    end

    # Public: Retrieve the events for a specified aggregate. Should be defined
    #         in a subclass.
    #
    # _id - UUID of the aggregate as a String.
    # _type - Text representation of aggregate class.
    #
    # Raises a NotImplementedError
    def read_events(_id, _type)
      fail NotImplementedError
    end

    # Public: Retrieve the event stream for a specified aggregate. Should be
    #         defined in a subclass.
    #
    # id   - UUID of the aggregate as a String.
    # type - Text representation of aggregate class.
    #
    # Returns an EventStream
    def read_event_stream(id, type)
      EventStream.new id, read_events(id, type), get_current_version(id, type)
    end

    # Public: Retrieve the event stream for all aggregates of a given type.
    #         Optionally can be defined in subclass to optimize loading these
    #         aggregates with a minimum of external calls.
    #
    # type - Text representation of aggregate class.
    #
    # Returns an Array.
    def read_event_streams_for_type(type)
      read_multiple_event_streams get_ids_for_type(type), type
    end

    # Public: Retrieve the events for multiple aggregates. Optionally can be
    #         defined in subclass to optimize loading multiple aggregates with
    #         a minimum of external calls.
    #
    # ids  - Array of UUIDs of the aggregates as Strings.
    # type - Text representation of aggregate class.
    #
    # Returns an Array.
    def read_multiple_event_streams(ids, type)
      ids.map { |id| read_event_stream id, type }
    end

    # Public: Ensures events appended within the given block are done so
    #         atomically. Should be defined in a subclass.
    #
    # Raises a NotImplementedError
    def with_transaction
      fail NotImplementedError
    end
  end
end
