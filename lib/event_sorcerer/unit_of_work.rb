module EventSorcerer
  # Public: Provides transactional integrity across multiple aggregate saves.
  #         Also provides an indentity map.
  class UnitOfWork
    extend Uber::Delegates

    # Public: Shortcuts to access the global event_store and message_bus.
    delegates :EventSorcerer, :event_store, :message_bus

    # Public: Creates a new UnitOfWork instance.
    def initialize
      @identity_map  = {}
      @meta          = {}
      @pending_saves = []
    end

    # Public: Add additional meta data to be sent along with any save reciepts
    #         on the message bus for the duration of the unit of work.
    def add_meta_data(meta_hash)
      meta.merge! meta_hash
    end

    # Public: Executes all pending saves within a transaction, clears the
    #         pending saves, and publishes the reciepts via the message bus.
    #
    # Returns self.
    def execute_work!
      save_receipts = event_store.with_transaction do
        pending_saves.map(&:call)
      end

      @pending_saves = []

      save_receipts.each do |reciept|
        message_bus.publish_events(reciept.id, reciept.klass, reciept.events,
                                   reciept.meta.merge(meta))
      end

      self
    end

    # Public: Fetches an aggregate via it's ID from the identity map.
    #
    # id - the ID for the aggregate.
    #
    # Returns nil if not found.
    # Returns Aggregate if found.
    def fetch_aggregate(id)
      identity_map[id]
    end

    def handle_save(save)
      pending_saves << save

      self
    end

    # Public: Stores an aggregate via it's ID into the identity map.
    #
    # aggregate - the aggregate to store.
    #
    # Returns self.
    def store_aggregate(aggregate)
      return self if fetch_aggregate(aggregate.id)

      identity_map[aggregate.id] = aggregate

      self
    end

    private

    # Private: Returns the identity map Hash.
    attr_reader :identity_map

    # Private: Returns extra metadata hash.
    attr_reader :meta

    # Private: Returns the pending saves Array.
    attr_reader :pending_saves
  end
end
