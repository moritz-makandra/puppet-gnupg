litmus_cleanup = false

desc "run acceptance tests"
task :acceptance do
  litmus_cleanup = true
  Rake::Task['spec_prep'].invoke
  Rake::Task['litmus:provision_list'].invoke 'default'
  Rake::Task['litmus:install_agent'].invoke
  Rake::Task['litmus:install_module'].invoke
  Rake::Task['litmus:acceptance:parallel'].invoke
end

task :acceptance_cleanup do
  # return unless $!.nil? # No cleanup on error
  next unless litmus_cleanup # No cleanup if flag is false
  Rake::Task['litmus:tear_down'].invoke
end

at_exit { Rake::Task['acceptance_cleanup'].invoke }
