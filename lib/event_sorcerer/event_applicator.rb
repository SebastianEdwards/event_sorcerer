require 'invokr'
require 'timecop'

module EventSorcerer
  # Public: Helper for applying events to an aggregate.
  module EventApplicator
    # Public: Sets the clock to the event time and calls the event method on
    #         the aggregate.
    #
    # aggregate - The Aggregate to apply the Event to.
    # event     - The Event to be applied.
    #
    # Returns self.
    def self.apply_event!(aggregate, event)
      EventSorcerer.time_travel_lock.synchronize do
        Timecop.freeze(event.created_at) do
          Invokr.invoke method: event.name, on: aggregate, with: event.details
        end
      end

      self
    end
  end
end
