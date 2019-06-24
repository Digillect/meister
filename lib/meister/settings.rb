require 'active_support'
require 'active_support/core_ext'

module Meister
  module Settings
    def self.check_env
      %w[DEPLOYMENT_PROJECT_ID GITLAB_API_ENDPOINT GITLAB_API_PRIVATE_TOKEN].each do |variable|
        next if ENV[variable]

        SemanticLogger['Meister'].error "Environment variable '#{variable}' is not set"

        exit 1
      end
    end

    def self.manage_hooks?
      !base_url.nil?
    end

    def self.base_url
      ENV['MEISTER_BASE_URL']
    end

    def self.hook_path
      '/gitlab/webhook'
    end

    def self.hook_url
      @hook_url ||= "#{base_url}#{hook_path}"
    end

    def self.protect_gitlab_hooks?
      gitlab_hook_secret.present?
    end

    def self.gitlab_hook_secret
      ENV['MEISTER_GITLAB_HOOK_SECRET']
    end

    def self.deployment_project_id
      @deployment_project_id ||= ENV['DEPLOYMENT_PROJECT_ID'].to_i
    end

    def self.configuration_file_path
      'meister.yaml'
    end

    def self.components_file_path
      'components.yaml'
    end
  end
end
