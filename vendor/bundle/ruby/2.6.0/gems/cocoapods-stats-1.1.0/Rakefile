begin

  require 'bundler/setup'
  require 'bundler/gem_tasks'

  def specs(dir)
    FileList["spec/#{dir}/*_spec.rb"].shuffle.join(' ')
  end

  desc 'Runs all the specs'
  task :spec do
    sh "bundle exec bacon #{specs('**')}"
    Rake::Task['rubocop'].invoke
  end

  require 'rubocop/rake_task'
  RuboCop::RakeTask.new

  task default: :spec

  rescue LoadError, NameError
    $stderr.puts "\033[0;31m" \
      '[!] Some Rake tasks haven been disabled because the environment ' \
      'couldn’t be loaded. Be sure to run `rake bootstrap` first.' \
      "\e[0m"
end
