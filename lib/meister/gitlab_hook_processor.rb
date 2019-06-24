module Meister
  class GitlabHookProcessor
    include SuckerPunch::Job

    attr_reader :logger

    def initialize
      @logger = SemanticLogger[GitlabHookProcessor]
    end

    HANDLERS = {
      'Pipeline Hook' => Meister::HookHandlers::PipelineHookHandler,
      'Push Hook' => Meister::HookHandlers::PushHookHandler
    }.freeze

    def self.event_supported?(event)
      HANDLERS.key? event
    end

    def perform(event, body)
      handler_class = HANDLERS[event]
      handler = handler_class.new

      handler.handle body
    rescue StandardError => err
      logger.error "Hook processing failed: #{err.message}" unless err.is_a? ReportedError
    end
  end
end
