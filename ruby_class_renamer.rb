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
indents = {}

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
    cf = ClassFixer.new(content, reindent: !!ENV['REINDENT'], flat_to: !!ENV['FLAT_TO'], flat_from: !!ENV['FLAT_FROM'])
    cf.rename_classes(from_class, to_class)
    indents[to_path] = cf.indent_level
    cf.content
  end
  const_mapping[from_class] = to_class
end

# rename constants in every other files
files = `git ls-files '*.rb' '*.rake'`.split(?\n)
files.each do |file|
  cr.rename_constants file, const_mapping
end

`git add -u`
if ENV['TWO_COMMIT']
  # return indents as they were (almost), git add result, then return content back
  # then you can git commit "renaming", git commit -am "fix indent"
  indents.each do |path, indent_level|
    next if indent_level == 0
    prev_content = nil
    cr.update_file path do |content|
      prev_content = content
      cf = ClassFixer.new(content)
      if indent_level > 0
        indent_level.times { cf.outdent }
      else
        (-indent_level).times { cf.indent }
      end
      cf.content
    end
    `git add #{path}`
    File.write(path, prev_content)
  end
end
