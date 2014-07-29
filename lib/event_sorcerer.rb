require 'event_sorcerer/version'

require 'event_sorcerer/aggregate'
require 'event_sorcerer/aggregate_creator'
require 'event_sorcerer/aggregate_loader'
require 'event_sorcerer/aggregate_proxy'
require 'event_sorcerer/argument_hashifier'
require 'event_sorcerer/event'
require 'event_sorcerer/event_applicator'
require 'event_sorcerer/event_store'
require 'event_sorcerer/message_bus'
require 'event_sorcerer/no_unit_of_work'
require 'event_sorcerer/unit_of_work'

# Public: Top-level namespace.
module EventSorcerer
  class AggregateNotFound < RuntimeError; end
  class UnsetEventStore < RuntimeError; end
  class UnsetMessageBus < RuntimeError; end

  class << self
    # Public: Writer method to set new event_store.
    attr_writer :event_store

    # Public: Writer method to set a new id_generation function.
    attr_writer :id_generator

    # Public: Writer method to set new message_bus.
    attr_writer :message_bus

    # Public: Returns the current event store. Raises UnsetEventStore if not
    #         set.
    def event_store
      @event_store || fail(UnsetEventStore)
    end

    # Public: Generates a new ID using the current id_generator.
    def generate_id
      id_generator.call
    end

    # Public: Returns the current id_generator. Defaults to a SecureRandom.uuid
    #         based generator.
    def id_generator
      @id_generator ||= proc { SecureRandom.uuid }
    end

    # Public: Returns the current message bus. Raises UnsetMessageBus if not
    #         set.
    def message_bus
      @message_bus || fail(UnsetMessageBus)
    end

    # Public: Mutex to synchronize usage of non-threadsafe time-traveling gems.
    def time_travel_lock
      @time_travel_lock ||= Mutex.new
    end

    # Public: Returns the unit_of_work for the current thread. Defaults to
    #         NoUnitOfWork.
    def unit_of_work
      Thread.current[:unit_of_work] || NoUnitOfWork
    end

    # Public: Creates a new UnitOfWork and sets it for the current thread
    #         within the block. Executes the work after block completion.
    #
    # Returns value of block.
    def with_unit_of_work(unit_of_work = UnitOfWork.new, autosave = true)
      old_unit_of_work = Thread.current[:unit_of_work]
      new_unit_of_work = Thread.current[:unit_of_work] = unit_of_work
      begin
        result = yield
        new_unit_of_work.execute_work! if autosave
      ensure
        Thread.current[:unit_of_work] = old_unit_of_work
      end

      result
    end
  end
end
