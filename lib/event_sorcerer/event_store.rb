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

    # Public: Retrieve the events for a specified aggregate. Should be
    #         defined in a subclass.
    #
    # _aggregate_id - UUID of the aggregate as a String.
    #
    # Raises a NotImplementedError
    def read_events(_aggregate_id)
      fail NotImplementedError
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
