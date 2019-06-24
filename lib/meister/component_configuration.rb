module Meister
  class ComponentConfiguration
    attr_reader :name, :project_id, :job_name

    def initialize(name, project_id_or_hash)
      @name = name.to_s

      if project_id_or_hash.is_a? Hash
        @project_id = project_id_or_hash[:project]
        @job_name = project_id_or_hash[:job]
      else
        @project_id = project_id_or_hash
      end

      @job_name ||= 'deploy'
    end
  end
end
