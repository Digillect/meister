require 'active_support'
require 'active_support/core_ext'

module Meister
  class ComponentsSnapshot
    def initialize(content = nil)
      @components = []
      @new = content.nil?

      return unless content && content[:components]&.is_a?(Hash)

      content[:components].each_pair do |name, component_hash|
        @components << ComponentSnapshot.new(name, component_hash)
      end
    end

    def new?
      @new
    end

    def add_or_update_component(name, ref, sha)
      component = @components.find { |c| c.name == name }

      if component.nil?
        @components << ComponentSnapshot.new(name, ref, sha)
      else
        return false if component.ref == ref && component.sha == sha

        component.ref = ref
        component.sha = sha
      end

      true
    end

    def to_h
      components = {}

      @components.each do |component|
        components[component.name] = component.to_h
      end

      { components: components }
    end

    def save_to_gitlab(ref, commit_message)
      content = to_h.deep_stringify_keys.to_yaml.lines[1..-1].join

      begin
        if new?
          create_gitlab_file(commit_message, content, ref)
        else
          update_gitlab_file(commit_message, content, ref)
        end
      rescue StandardError => err
        @logger.error "Unable to update component versions: #{err.message}"
      end
    end

    def self.load_from_gitlab(ref)
      content = nil

      begin
        content = Gitlab.file_contents Settings.deployment_project_id, Configuration.current.components_file, ref
        content = YAML.safe_load content, symbolize_names: true
      rescue StandardError => err
        unless err.is_a? Gitlab::Error::NotFound
          SemanticLogger[ComponentsSnapshot].error "Unable to load components file: #{err.class.name}/#{err.message}"

          raise ReportedError
        end
      end

      new content
    end

    private

    def create_gitlab_file(commit_message, content, ref)
      Gitlab.create_file(
        Settings.deployment_project_id,
        Configuration.current.components_file,
        ref,
        content,
        commit_message
      )
    end

    def update_gitlab_file(commit_message, content, ref)
      Gitlab.edit_file(
        Settings.deployment_project_id,
        Configuration.current.components_file,
        ref,
        content,
        commit_message
      )
    end
  end
end
