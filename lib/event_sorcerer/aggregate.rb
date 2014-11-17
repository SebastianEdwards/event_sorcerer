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
        event_store.get_ids_for_type(name).map { |id| find(id) }
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

        AggregateLoader.new(self, id).load.tap do |aggregate|
          unit_of_work.store_aggregate(aggregate)
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

        AggregateLoader.new(self, id, false).load.tap do |aggregate|
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
    end
  end
end
