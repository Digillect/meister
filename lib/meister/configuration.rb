module Meister
  class Configuration
    attr_reader :components, :components_file

    def initialize(config = nil)
      @components = []

      if config
        @components_file = config[:components_file]

        if config[:components]&.is_a?(Hash)
          config[:components].each_pair do |name, component_config|
            @components << ComponentConfiguration.new(name, component_config)
          end
        end
      end

      @components_file ||= Settings.components_file_path
    end

    def find_component(project_id)
      @components.find { |c| c.project_id == project_id }
    end

    def project_ids
      @components.map(&:project_id)
    end

    class << self
      attr_reader :current

      def reload!
        @current = load_from_gitlab

        SemanticLogger[Configuration].info 'Configuration has been reloaded'
      end

      def reset!
        @current = new

        SemanticLogger[Configuration].info 'Configuration has been reset'
      end

      def load_from_gitlab
        content = nil

        begin
          content = Gitlab.file_contents Settings.deployment_project_id, "/#{Settings.configuration_file_path}"

          content = YAML.safe_load content, symbolize_names: true
        rescue StandardError => err
          SemanticLogger[Configuration].error "Unable to load configuration: #{err.message}" unless err.is_a? Gitlab::Error::NotFound
        end

        new content
      end
    end
  end
end
