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
    # _aggregate_id     - UUID of the aggregate as a String.
    # _klass            - Text representation of aggregate class.
    # _events           - Array of JSON-serialized events.
    # _expected_version - The current version of the aggregate.
    #
    # Raises a NotImplementedError
    def append_events(_aggregate_id, _klass, _events, _expected_version)
      fail NotImplementedError
    end

    # Public: Retrieve the current version for a specified aggregate. Should
    #         be defined in a subclass.
    #
    # _aggregate_id - UUID of the aggregate as a String.
    #
    # Raises a NotImplementedError
    def get_current_version(_aggregate_id)
      fail NotImplementedError
    end

    # Public: Retrieve the IDs for a given aggregate class. Should be defined
    #         in a subclass.
    #
    # _klass - Text representation of aggregate class.
    #
    # Raises a NotImplementedError
    def get_ids_for_type(_klass)
      fail NotImplementedError
    end

    # Public: Retrieve the events for a specified aggregate. Should be defined
    #         in a subclass.
    #
    # _aggregate_id - UUID of the aggregate as a String.
    #
    # Raises a NotImplementedError
    def read_events(_aggregate_id)
      fail NotImplementedError
    end

    # Public: Retrieve the event stream for a specified aggregate. Should be
    #         defined in a subclass.
    #
    # aggregate_id - UUID of the aggregate as a String.
    #
    # Returns an EventStream
    def read_event_stream(aggregate_id)
      EventStream.new(aggregate_id, read_events(aggregate_id),
                      get_current_version(aggregate_id))
    end

    # Public: Retrieve the event stream for all aggregates of a given type.
    #         Optionally can be defined in subclass to optimize loading these
    #         aggregates with a minimum of external calls.
    #
    # klass - Text representation of aggregate class.
    #
    # Returns an Array.
    def read_event_streams_for_type(klass)
      read_multiple_event_streams get_ids_for_type(klass)
    end

    # Public: Retrieve the events for multiple aggregates. Optionally can be
    #         defined in subclass to optimize loading multiple aggregates with
    #         a minimum of external calls.
    #
    # aggregate_ids - Array of UUIDs of the aggregates as Strings.
    #
    # Returns an Array.
    def read_multiple_event_streams(aggregate_ids)
      aggregate_ids.map { |id| read_event_stream id }
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
