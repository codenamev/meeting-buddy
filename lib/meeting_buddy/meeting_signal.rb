# frozen_string_literal: true

module MeetingBuddy
  # Handles event signaling between components
  # @api private
  class MeetingSignal
    # Initialize a new MeetingSignal instance
    def initialize
      @listeners = []
      @queue = Queue.new
      start_listener_thread
    end

    # Subscribe to signal events
    # @yield [data] Block to be called when signal is triggered
    # @yieldparam data Data passed to trigger
    def subscribe(&block)
      @listeners << block
    end

    # Trigger the signal with optional data
    # @param data Data to pass to listeners
    def trigger(data = nil)
      @queue << data
    end

    private

    # Start the background thread for processing signals
    def start_listener_thread
      Thread.new do
        loop do
          data = @queue.pop
          @listeners.each { |listener| listener.call(data) }
        end
      end
    end
  end
end
