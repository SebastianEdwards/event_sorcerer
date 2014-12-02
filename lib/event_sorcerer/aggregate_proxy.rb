module EventSorcerer
  class EventArgumentError < RuntimeError; end

  # Public: Transparent wrapped around Aggregate objects which tracks dirty
  #         events and handles persisting these.
  class AggregateProxy
    # Public: Value object which is returned from a successful save.
    class SaveReciept < Struct.new(:id, :klass, :events, :meta); end

    extend Forwardable

    instance_methods.each do |m|
      undef_method(m) unless m =~ /(^__|^nil\?$|^send$|^object_id$|^tap$)/
    end

    # Public: Shortcuts to access the global event_store and unit_of_work.
    def_delegators :EventSorcerer, :event_store, :unit_of_work

    # Public: Creates a new AggregateProxy instance.
    #
    # aggregate - aggregate to wrap.
    def initialize(aggregate)
      @_aggregate    = aggregate
      @_dirty_events = []
    end

    # Public: Forwards messages to the aggregate. Saves the details of event
    #         messages to the _dirty_events array.
    def method_missing(method_sym, *arguments, &block)
      if event_method?(method_sym)
        send_event_to_aggregate(method_sym, *arguments, &block)
      else
        @_aggregate.send method_sym, *arguments, &block
      end
    end

    # Public: Saves the current dirty events via the current unit_of_work.
    #
    # meta - Hash of extra data to publish on the message bus with the events
    #        after save.
    #
    # Returns self.
    def save(meta = {})
      dirty_events = @_dirty_events
      version      = persisted_version

      unit_of_work.handle_save(proc do
        event_store.append_events(id, self.class.name, dirty_events, version)
        SaveReciept.new(id, self.class, dirty_events, meta)
      end)

      @_dirty_events = []
      @_aggregate.instance_variable_set(:@persisted_version, local_version)

      self
    end

    private

    # Private: Handles the serialization of event arguments and pushes the
    #          Event object onto the _dirty_events array. Increments the local
    #          version number for the aggregate.
    def add_dirty_event!(time, method_sym, *arguments)
      increment_version!

      method = @_aggregate.method(method_sym)
      method.parameters.each.with_index.select { |(type, _), _| type == :req }

      details = ArgumentHashifier.hashify(method.parameters, arguments.dup)
      @_dirty_events << Event.new(method_sym, time, details)

      self
    end

    # Private: Decrements the wrapped aggregates local version by one.
    def decrement_version!
      @_aggregate.instance_variable_set(:@local_version, local_version - 1)

      self
    end

    # Private: Checks whether the aggregate has an event method defined with
    #          a given name.
    #
    # method_sym - A symbol of the method name.
    #
    # Returns true if event method exists.
    # Returns false if event method does not exist.
    def event_method?(method_sym)
      @_aggregate.class.event_methods.include? method_sym
    end

    # Private: Increments the wrapped aggregates local version by one.
    def increment_version!
      @_aggregate.instance_variable_set(:@local_version, local_version + 1)

      self
    end

    # Private: Forwards an event message to the aggregate while adding the
    #          Event to the _dirty_events and incrementing the local version.
    #          Rolls everything back if a StandardError is caught.
    def send_event_to_aggregate(method_sym, *arguments, &block)
      fail EventArgumentError if block

      time = Time.now
      add_dirty_event!(time, method_sym, *arguments)

      expected_args = arguments.slice(0, @_aggregate.method(method_sym).arity)

      EventSorcerer.with_time(time) do
        @_aggregate.send method_sym, *expected_args
      end
    rescue StandardError => e
      undo_dirty_event!
      raise e
    end

    # Private: Undoes the side-effects of the last event message.
    def undo_dirty_event!
      decrement_version!
      @_dirty_events.pop

      self
    end
  end
end
