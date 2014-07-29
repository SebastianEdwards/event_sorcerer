module EventSorcerer
  # Public: Service class for building new aggregates.
  class AggregateCreator
    # Public: Creates a new AggregateCreator instance.
    #
    # klass - class for the aggregate to be created.
    # id    - desired id for the aggregate to be created.
    def initialize(klass, id)
      @id    = id
      @klass = klass
    end

    # Public: Wraps and returns aggregate in a new AggregateProxy.
    def create
      AggregateProxy.new(aggregate)
    end

    private

    # Private: Returns the desired id for the aggregate to be created.
    attr_reader :id

    # Private: Returns the class for the aggregate to be created.
    attr_reader :klass

    # Private: Memorizes and returns a new instance of an aggregate.
    def aggregate
      @aggregate ||= klass.build.tap do |aggregate|
        aggregate.instance_variable_set(:@id, id)
        aggregate.instance_variable_set(:@local_version, 0)
        aggregate.instance_variable_set(:@persisted_version, 0)
      end
    end
  end
end
