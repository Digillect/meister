module Meister
  module HookHandlers
    class PushHookHandler
      def handle(body)
        check_and_reload_configuration body if body[:project_id] == Settings.deployment_project_id
      end

      private

      def check_and_reload_configuration(body)
        status = configuration_file_status body

        return unless status

        previous_config = Configuration.current

        if status == :removed
          Configuration.reset!
        else
          Configuration.reload!
        end

        HookManager.update_components(previous_config) if Settings.manage_hooks?
      end

      def configuration_file_status(body)
        body[:commits].each do |commit|
          return :removed if commit[:removed].include? Settings.configuration_file_path
          return :added if commit[:added].include? Settings.configuration_file_path
          return :modified if commit[:modified].include? Settings.configuration_file_path
        end

        nil
      end
    end
  end
end
