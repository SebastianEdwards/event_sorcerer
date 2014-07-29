module EventSorcerer
  # Public: Service class for loading aggregates from the event store.
  class AggregateLoader
    extend Forwardable

    # Public: Shortcut to access the global event_store.
    def_delegators :EventSorcerer, :event_store

    # Public: Creates a new AggregateLoader instance.
    #
    # klass        - class for the aggregate to be loaded.
    # id           - id for the aggregate to be loaded.
    # prohibit_new - whether or not to raise an error if aggregate not existing.
    def initialize(klass, id, prohibit_new = true)
      @id           = id
      @klass        = klass
      @prohibit_new = prohibit_new
    end

    # Public: Wraps and returns aggregate in a proxy.
    #
    # Returns an AggregateProxy.
    # Raises AggregateNotFound if aggregate not found and prohibit_new is true.
    def load
      fail AggregateNotFound if prohibit_new && new_aggregate?

      AggregateProxy.new(aggregate)
    end

    private

    # Private: Returns the id for the aggregate to be loaded.
    attr_reader :id

    # Private: Returns the class for the aggregate to be loaded.3
    attr_reader :klass

    # Private: Returns whether new aggregates will be allowed.
    attr_reader :prohibit_new

    # Private: Memorizes and returns a new instance of an aggregate. Applies
    #          existing events from the event store.
    def aggregate
      @aggregate ||= klass.build.tap do |aggregate|
        aggregate.instance_variable_set(:@id, id)
        aggregate.instance_variable_set(:@local_version, version)
        aggregate.instance_variable_set(:@persisted_version, version)
        events.each { |event| EventApplicator.apply_event!(aggregate, event) }
      end
    end

    # Private: Memorizes and returns the existing events from the event store.
    def events
      @events ||= event_store.read_events(id)
    end

    def new_aggregate?
      !version || version == 0
    end

    # Private: Memorizes and returns the current version number from the event
    #          store.
    def version
      @version ||= event_store.get_current_version(id)
    end
  end
end
