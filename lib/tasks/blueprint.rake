def blueprintfile(opts = {})
  file = Rails.root.join("Blueprintfile")

  if File.exists?(file)
    file = YAML.load_file(file)

    if ENV['group']
      hash = file[ENV['group']] || {}
    else
      hash = file.any? ? file.first[1] : {}
    end
  else
    hash = {}
  end

  if opts[:write_blueprint] != false && hash['blueprint'].present? && File.exists?(hash['blueprint'])
    hash.delete('blueprint')
  end

  ['spec', 'blueprint', 'html'].each do |param|
    hash[param] = ENV[param] if ENV[param].present?
  end

  hash
end

def compile(source, target)
  compiler = ApiBlueprint::Compile::Compile.new(:source => source, :target => target, :logger => :stdout)
  compiler.compile

  compiler
end

def regenerate_dumps
  Rake::Task["blueprint:collect:clear"].execute
  puts
  Rake::Task["blueprint:collect:generate"].execute
  puts
end

namespace :blueprint do
  desc 'Clear, generate and merge dumps for specified request spec(s)'
  task :collect => :environment do
    regenerate_dumps

    Rake::Task["blueprint:collect:merge"].execute
  end

  namespace :collect do
    desc 'Remove all generated request dumps'
    task :clear => :environment do
      files = ApiBlueprint::Collect::Storage.request_dumps

      puts "Clearing #{files.count} request dumps..."

      File.unlink(*files)
    end

    desc 'Generate request dumps for specified request spec(s)'
    task :generate => :environment do
      args = blueprintfile['spec'] || "spec/requests/#{ENV['group'] || 'api'}"
      opts = { :order => 'defined', :format => 'documentation' }
      cmd  = "API_BLUEPRINT_DUMP=1 bundle exec rspec #{opts.map{|k,v| "--#{k} #{v}"}.join(' ')} #{args}"

      puts "Invoking '#{cmd}'..."

      system(cmd)
    end

    desc 'Merge all existing request dumps into single blueprint'
    task :merge => :environment do
      target = blueprintfile['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout, :naming => blueprintfile['naming']).merge
    end
  end

  namespace :examples do
    desc 'Clear existing examples in blueprint'
    task :clear => :environment do
      target = blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).clear_examples
    end

    desc 'Uuse dumps to update examples in blueprint'
    task :update => :environment do
      target = blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).update_examples
    end

    desc 'Use dumps to replace examples in blueprint'
    task :replace => :environment do
      target = blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')

      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).clear_examples
      ApiBlueprint::Collect::Merge.new(:target => target, :logger => :stdout).update_examples
    end
  end

  desc 'Compile the blueprint into complete HTML documentation'
  task :compile => :environment do
    source = blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')
    target = blueprintfile(:write_blueprint => false)['html'] || source.to_s.sub(/\.md$/, '.html')

    compile(source, target)
  end

  desc 'Watch for changes in the blueprint and compile it into HTML on every change'
  task :watch => :environment do
    source = blueprintfile(:write_blueprint => false)['blueprint'] || Rails.root.join('tmp', 'merge.md')
    target = blueprintfile(:write_blueprint => false)['html'] || source.to_s.sub(/\.md$/, '.html')

    files = compile(source, target).partials

    FileWatcher.new(files).watch do |filename|
      puts "\n--- #{Time.now} [#{filename.split('/').last}] ---\n\n"
      compile(source, target)
    end
  end

  desc 'Deploy the HTML documentation on remote target'
  task :deploy => :environment do
    Rake::Task["blueprint:compile"].execute

    source = blueprintfile(:write_blueprint => false)['html']
    target = blueprintfile(:write_blueprint => false)['deploy']

    if source.present? && target.present?
      cmd = "scp -q #{source} #{target}"

      puts "\nDeploying to '#{target}'..."

      system(cmd)
    end
  end
end


