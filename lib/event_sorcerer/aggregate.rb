module EventSorcerer
  # Public: Mixin to turn a plain class into an event-store backed aggreagte.
  module Aggregate
    # Public: Returns the ID for the aggregate.
    attr_reader :id

    # Public: Returns the version number of the aggregate in memory.
    attr_reader :local_version

    # Public: Returns the version number of the aggregate in the database.
    attr_reader :persisted_version

    def self.included(base)
      base.class.send :alias_method, :build, :new
      base.extend(ClassMethods)
      base.class.extend(Forwardable)
      base.class.send :def_delegators, :EventSorcerer, :event_store,
                      :unit_of_work
    end

    # Public: Class methods to be extended onto the including class.
    module ClassMethods
      # Public: Load all Aggregates of this type.
      #
      # Returns an Array of AggregateProxy objects.
      def all
        with_all_loaders_for_type do |loaders|
          loaders.map(&:load).each do |aggregate|
            unit_of_work.store_aggregate(aggregate)
          end
        end
      end

      # Public: An array of symbols representing the names of the methods which
      #         are events.
      def event_methods
        @event_methods ||= []
      end

      # Public: Methods defined within this block will have their method symbol
      #         added to the event_methods array.
      #
      # block - block containing the event method definitions.
      #
      # Returns self.
      def events(&block)
        test_class ||= Class.new(BasicObject)
        starting_methods = test_class.instance_methods
        test_class.class_eval(&block)

        new_events = test_class.instance_methods.select do |method|
          !starting_methods.include? method
        end

        event_methods.concat new_events
        class_eval(&block)

        self
      end

      # Public: Load an aggregate out of the event store.
      #
      # id - the ID of the aggregate to load.
      #
      # Returns an AggregateProxy object.
      def find(id)
        if unit_of_work.fetch_aggregate(id)
          return unit_of_work.fetch_aggregate(id)
        end

        with_loader_for_id(id) do |loader|
          loader.load.tap do |aggregate|
            unit_of_work.store_aggregate(aggregate)
          end
        end
      end

      # Public: Load an aggregate out of the event store or create new.
      #
      # id - the ID of the aggregate to load.
      #
      # Returns an AggregateProxy object.
      def find_or_new(id)
        if unit_of_work.fetch_aggregate(id)
          return unit_of_work.fetch_aggregate(id)
        end

        with_loader_for_id(id, false) do |loader|
          loader.load.tap do |aggregate|
            unit_of_work.store_aggregate(aggregate)
          end
        end
      end

      # Public: Creates a new aggregate.
      #
      # id - the ID to set on the new aggregate.
      #
      # Returns an AggregateProxy object.
      def new(id = EventSorcerer.generate_id)
        AggregateCreator.new(self, id).create.tap do |aggregate|
          unit_of_work.store_aggregate(aggregate)
        end
      end

      private

      # Private: Grabs the event streams for the aggregate class and yields
      #          them to a given block.
      #
      # block - the block to yield the event stream to.
      #
      # Returns the return value of the given block.
      def with_all_event_streams_for_type(&block)
        yield event_store.read_event_streams_for_type(name)
      end

      # Private: Creates AggregateLoaders for an ID and yields it to a given
      #          block.
      #
      # prohibit_new - value of the prohibit_new flag to be passed to loaders.
      # block        - the block to yield the event stream to.
      #
      # Returns the return value of the given block.
      def with_all_loaders_for_type(prohibit_new = true, &block)
        with_all_event_streams_for_type do |streams|
          loaders = streams.map do |stream|
            AggregateLoader.new(self, stream.id, stream.events,
                                stream.current_version, prohibit_new)
          end

          yield loaders
        end
      end

      # Private: Grabs the event stream for an ID and yields it to a given
      #          block.
      #
      # id    - the ID of the aggregate to get the event stream for.
      # block - the block to yield the event stream to.
      #
      # Returns the return value of the given block.
      def with_event_stream_for_id(id, &block)
        yield event_store.read_event_stream(id)
      end

      # Private: Creates an AggregateLoader for an ID and yields it to a given
      #          block.
      #
      # id    - the ID of the aggregate to get the event stream for.
      # block - the block to yield the event stream to.
      #
      # Returns the return value of the given block.
      def with_loader_for_id(id, prohibit_new = true, &block)
        with_event_stream_for_id(id) do |stream|
          yield AggregateLoader.new(self, stream.id, stream.events,
                                    stream.current_version, prohibit_new)
        end
      end
    end
  end
end
