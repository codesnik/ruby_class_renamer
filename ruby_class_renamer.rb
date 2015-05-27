#!/usr/bin/env ruby

require_relative 'lib/class_renamer'
require_relative 'lib/class_fixer'

require 'logger'
require 'yaml'

plan = YAML.load_file(ARGV[0])

if plan.is_a? Hash
  plan = plan.map {|k, v| {"from" => k, "to" => v}}
end

cr = ClassRenamer.new(logger: Logger.new(STDOUT))

const_mapping = {}

plan.each do |p|
  from_path = p["from"]
  to_path = p["to"]
  next if to_path.nil? || from_path == to_path
  from_class = p["from_class"] || cr.get_class(from_path)
  to_class = p["to_class"] || cr.get_class(to_path)
  # git mv files
  cr.git_mv from_path, to_path
  next if from_class == to_class
  # rename/unwrap constants in each renamed file
  cr.update_file to_path do |content|
    ClassFixer.new(content).rename_classes(from_class, to_class).content
  end
  const_mapping[from_class] = to_class
end

# rename constants in every other files
files = `git ls-files '*.rb' '*.rake'`.split(?\n)
files.each do |file|
  cr.rename_constants file, const_mapping
end
