require 'bundler/setup'

require 'sucker_punch'
require 'sinatra'

Bundler.require(:default)

require 'json'
require 'yaml'
require 'zeitwerk'

loader = Zeitwerk::Loader.new
loader.push_dir File.expand_path('lib', __dir__)
loader.setup

SemanticLogger.default_level = ENV.fetch('LOG_LEVEL', 'info')
SemanticLogger.add_appender(io: STDOUT, formatter: ENV.fetch('LOG_FORMATTER', nil)&.to_sym)

Thread.current.name = 'main'

logger = SemanticLogger['Main']

SuckerPunch.logger = logger

Meister::Settings.check_env

set server: :puma
set bind: '0.0.0.0'
set port: ENV.fetch('MEISTER_PORT', 5000).to_i
disable :logging

GITLAB_EVENT_HEADER = 'HTTP_X_GITLAB_EVENT'.freeze
GITLAB_TOKEN_HEADER = 'HTTP_X_GITLAB_TOKEN'.freeze

post Meister::Settings.hook_path do
  unless request.has_header? GITLAB_EVENT_HEADER
    logger.debug 'Request does not have GitLab Event Header'

    return 400
  end

  if Meister::Settings.protect_gitlab_hooks?
    unless request.has_header? GITLAB_TOKEN_HEADER
      logger.debug 'Request does not have GitLab Token Header'

      return 403
    end

    token = request.get_header GITLAB_TOKEN_HEADER

    unless token == Meister::Settings.gitlab_hook_secret
      logger.debug 'Invalid security token'

      return 403
    end
  end

  event = request.get_header GITLAB_EVENT_HEADER

  request.body.rewind
  body = JSON.parse request.body.read, symbolize_names: true

  if Meister::GitlabHookProcessor.event_supported? event
    Meister::GitlabHookProcessor.perform_async(event, body)

    200
  else
    [400, 'Unsupported event']
  end
end

Meister::Configuration.reload!
Meister::HookManager.ensure_hooks if Meister::Settings.manage_hooks?
