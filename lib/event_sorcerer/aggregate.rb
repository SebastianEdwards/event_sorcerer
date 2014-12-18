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
      base.class.extend(Uber::Delegates)
      base.class.send :delegates, :EventSorcerer, :event_store, :unit_of_work
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

      # Public: Load an aggregate(s) out of the event store.
      #
      # id_or_ids - the ID of the aggregate to load or an array of the same.
      #
      # Returns an AggregateProxy object or an array of the same.
      def find(id_or_ids)
        return find_many(id_or_ids) if id_or_ids.respond_to?(:each)

        if unit_of_work.fetch_aggregate(to_s, id_or_ids)
          return unit_of_work.fetch_aggregate(to_s, id_or_ids)
        end

        loader_for_id(id_or_ids).load.tap do |aggregate|
          unit_of_work.store_aggregate(aggregate)
        end
      end

      # Public: Load an aggregate out of the event store or create new.
      #
      # id - the ID of the aggregate to load.
      #
      # Returns an AggregateProxy object.
      def find_or_new(id)
        if unit_of_work.fetch_aggregate(to_s, id)
          return unit_of_work.fetch_aggregate(to_s, id)
        end

        loader_for_id(id, false).load.tap do |aggregate|
          unit_of_work.store_aggregate(aggregate)
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

      # Private: Creates an AggregateLoader for each persisted aggregate.
      #
      # Returns the return value of the given block.
      def all_loaders_for_type
        event_store.read_event_streams_for_type(name).map do |stream|
          AggregateLoader.new(self, stream.id, stream.events,
                              stream.current_version, true)
        end
      end

      # Private: Maps an array of IDs replacing with cached aggregate if
      #          available.
      #
      # ids - the IDs of the aggregates to check the cache from.
      #
      # Returns a mixed Array of AggregateProxy objects and IDs.
      def perform_cache_pass(ids)
        ids.map do |id|
          cached = unit_of_work.fetch_aggregate(to_s, id)

          cached ? cached : id
        end
      end

      # Private: Loads an array of aggregates out of the event store.
      #
      # ids - the IDs of the aggregates to load.
      #
      # Returns an Array of AggregateProxy objects.
      def find_many(ids)
        aggregates = perform_cache_pass(ids)

        uncached_ids = aggregates.reject { |a| a.is_a? self }

        uncached = loaders_for_ids(uncached_ids).reduce({}) do |hash, loader|
          aggregate = loader.load
          unit_of_work.store_aggregate(aggregate)

          hash.merge aggregate.id => aggregate
        end

        aggregates.map do |id_or_agg|
          uncached[id_or_agg] ? uncached[id_or_agg] : id_or_agg
        end
      end

      def loader_for_id(id, prohibit_new = true)
        stream = event_store.read_event_stream(id, name)

        AggregateLoader.new(self, stream.id, stream.events,
                            stream.current_version, prohibit_new)
      end

      # Private: Creates an AggregateLoader for each given ID.
      #
      # id    - the ID of the aggregate to get the event stream for.
      #
      # Returns an Array of AggregateLoader instances.
      def loaders_for_ids(ids, prohibit_new = true)
        event_store.read_multiple_event_streams(ids, name).map do |stream|
          AggregateLoader.new(self, stream.id, stream.events,
                              stream.current_version, prohibit_new)
        end
      end
    end
  end
end
