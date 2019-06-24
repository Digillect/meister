module Meister
  module HookHandlers
    class PipelineHookHandler
      def initialize
        @logger = SemanticLogger[PipelineHookHandler]
      end

      def handle(body)
        project_id = body[:project][:id]
        attributes = body[:object_attributes]
        sha = attributes[:sha]
        ref = attributes[:ref]

        @logger.debug "Handling Pipeline event for project #{body[:project][:name]}, pipeline ##{attributes[:id]} from #{ref}, SHA #{sha}"

        return unless ref == 'master'
        return unless attributes[:status] == 'success'

        component_config = Configuration.current.find_component project_id

        return unless component_config

        return unless latest_pipeline? project_id, ref, sha

        build_status = build_status body, component_config.job_name

        return unless build_status == 'success'

        components = ComponentsSnapshot.load_from_gitlab ref

        return unless components.add_or_update_component component_config.name, ref, sha

        commit_message = "#{body[:project][:name]}: #{convert_commit_message(body[:commit][:message])}"

        components.save_to_gitlab ref, commit_message

        @logger.info "Components updated: #{commit_message}"
      end

      private

      def latest_pipeline?(project_id, ref, sha)
        begin
          pipelines = Gitlab.pipelines project_id, ref: ref, status: 'success'

          unless pipelines.empty?
            latest = pipelines.first

            return sha == latest.sha
          end

          @logger.error "No pipelines has been returned for project #{project_id}, ref #{ref}"
        rescue StandardError => err
          @logger.error "Unable to get pipelines for project #{project_id}, ref #{ref}: #{err.message}"
        end

        false
      end

      def build_status(body, job_name)
        build = body[:builds]&.find { |b| b[:name] == job_name }

        return nil unless build

        build[:status]
      end

      SKIP_DEPLOY_REGEXP = /\[(skip deploy|deploy skip)\]/i.freeze
      SKIP_CI_TEXT = '[skip ci]'.freeze

      def convert_commit_message(message)
        message.gsub(SKIP_DEPLOY_REGEXP, SKIP_CI_TEXT)
      end
    end
  end
end
