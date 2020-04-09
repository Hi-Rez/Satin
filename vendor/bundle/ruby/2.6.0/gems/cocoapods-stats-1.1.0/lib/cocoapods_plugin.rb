module CocoaPodsStats
  class SpecsRepoValidator
    def validates?(source)
      source && source.url && source.url.end_with?('CocoaPods/Specs.git')
    end
  end

  class OptOutValidator
    def validates?
      ENV['COCOAPODS_DISABLE_STATS'].nil?
    end
  end

  class Stats
    def send_stats(master_source, context)
      if fork_available?
        Process.fork do
          compute_and_send_stats(master_source, context)
        end
      else
        compute_and_send_stats(master_source, context)
      end
    end

    def fork_available?
      !Gem.win_platform?
    end

    private

    def compute_and_send_stats(master_source, context)
      master_pods = Set.new(master_source.pods)

      mapper = TargetMapper.new
      targets = mapper.pods_from_project(context, master_pods)

      # Logs out for now:
      targets.flat_map { |t| t[:pods] }.uniq.sort_by { |p| p[:name] }.each do |pod|
        Pod::UI.message "#{pod[:name]}, #{pod[:version]}", '- '
      end

      is_pod_try = defined?(Pod::Command::Try::TRY_TMP_DIR) &&
        Pod::Command::Try::TRY_TMP_DIR.exist? &&
        context.sandbox_root.start_with?(Pod::Command::Try::TRY_TMP_DIR.realpath.to_s)

      # Send the analytics stuff up
      Sender.new.send(targets, :pod_try => is_pod_try)
    end
  end

  Pod::HooksManager.register('cocoapods-stats', :post_install) do |context, _|
    require 'set'
    require 'cocoapods'
    require 'cocoapods_stats/target_mapper'
    require 'cocoapods_stats/sender'

    validator = OptOutValidator.new
    next unless validator.validates?

    sources_manager = if defined?(Pod::SourcesManager)
                        Pod::SourcesManager
                      else
                        Pod::Config.instance.sources_manager
                      end
    master_source = sources_manager.master.first
    validator = SpecsRepoValidator.new
    next unless validator.validates?(master_source)

    Pod::UI.titled_section 'Sending stats' do
      stats = Stats.new
      stats.send_stats(master_source, context)
    end
  end
end
