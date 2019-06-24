module Meister
  class HookManager
    def initialize
      @logger = SemanticLogger[HookManager]
    end

    def self.ensure_hooks
      new
        .ensure_deployment_hook
        .update_components
    end

    def self.update_components(previous_config)
      new
        .update_components previous_config
    end

    def ensure_deployment_hook
      hook = find_hook Settings.deployment_project_id

      if hook
        update_deployment_project_hook hook
      else
        add_deployment_project_hook
      end

      self
    end

    def update_components(previous_config = nil)
      old_projects = previous_config&.project_ids&.to_set || Set.new
      new_projects = Configuration.current.project_ids.to_set

      update_component_hooks old_projects, new_projects

      self
    end

    private

    def update_component_hooks(old_projects, new_projects)
      (old_projects - new_projects).each(&method(:remove_component_project_hook))
      (old_projects & new_projects).each(&method(:ensure_component_project_hook))
      (new_projects - old_projects).each(&method(:ensure_component_project_hook))
    end

    def ensure_component_project_hook(project_id)
      hook = find_hook project_id

      if hook
        update_component_project_hook hook
      else
        add_component_project_hook project_id
      end
    end

    def remove_component_project_hook(project_id)
      hook = find_hook project_id

      delete_component_project_hook hook
    rescue Gitlab::Error::NotFound
      @logger.warning "Gitlab project #{project_id} does not exists, web hook removal skipped"
    end

    def add_deployment_project_hook
      @logger.debug 'Adding web hook to Deployment Project'

      Gitlab.add_project_hook Settings.deployment_project_id,
                              Settings.hook_url,
                              hook_options(push_events: true)
    rescue Gitlab::Error => err
      @logger.error "Unable to add web hook to Deployment Project: #{err}"
    end

    def update_deployment_project_hook(hook)
      return if hook.push_events

      @logger.debug 'Updating web hook for Deployment Project'

      Gitlab.edit_project_hook hook.project_id,
                               hook.id,
                               Settings.hook_url,
                               hook_options(push_events: true)
    rescue Gitlab::Error => err
      @logger.error "Unable to update web hook for Deployment Project: #{err}"
    end

    def add_component_project_hook(project_id)
      @logger.debug "Adding web hook to Component Project #{project_id}"

      Gitlab.add_project_hook project_id,
                              Settings.hook_url,
                              hook_options(pipeline_events: true)
    rescue Gitlab::Error => err
      @logger.error "Unable to add web hook to Component Project #{project_id}: #{err}"
    end

    def update_component_project_hook(hook)
      return if hook.pipeline_events

      @logger.debug "Updating web hook for Component Project #{project_id}"

      Gitlab.edit_project_hook hook.project_id,
                               hook.id,
                               Settings.hook_url,
                               hook_options(pipeline_events: true)
    rescue Gitlab::Error => err
      @logger.error "Unable to update web hook for Component Project #{hook.project_id}: #{err}"
    end

    def delete_component_project_hook(hook)
      @logger.debug "Removing web hook from Component Project #{project_id}"

      Gitlab.delete_project_hook hook.project_id, hook.id
    rescue Gitlab::Error => err
      @logger.error "Unable to delete web hook for Component Project #{project_id}: #{err}"
    end

    def find_hook(project_id)
      hooks = Gitlab.project_hooks project_id

      hooks.find { |hook| hook.url == Settings.hook_url }
    end

    def hook_options(options = {})
      options[:token] = Settings.gitlab_hook_secret if Settings.protect_gitlab_hooks?

      options
    end
  end
end
