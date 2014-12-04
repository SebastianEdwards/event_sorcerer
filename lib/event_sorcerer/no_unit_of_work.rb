module EventSorcerer
  # Public: Handles the API of a UnitOfWork but does nothing.
  module NoUnitOfWork
    class << self
      extend Uber::Delegates

      # Public: Shortcuts to access the global message_bus.
      delegates :EventSorcerer, :message_bus

      # Public: Returns nil.
      def fetch_aggregate(_id)
        nil
      end

      # Public: Immediately calls the save proc and publishes the reciepts via
      #         the message bus.
      #
      # save - the Proc object representing the save process.
      #
      # Returns self.
      def handle_save(save)
        reciept = save.call
        message_bus.publish_events(reciept.id, reciept.klass, reciept.events,
                                   reciept.meta)

        self
      end

      # Public: Returns self.
      def store_aggregate(_aggregate)
        self
      end
    end
  end
end
