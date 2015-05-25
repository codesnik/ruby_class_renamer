#!/usr/bin/env ruby
require 'active_support/inflector'
require 'fileutils'

require 'logger'
LOGGER = Logger.new(STDOUT)
class ClassRenamer

  def get_class(path)
    klass = path.sub(%r[^app/[^/]+/], '').sub(/\.rb$/, '')
    klass = ActiveSupport::Inflector.camelize(klass)
  end

  def git_mv from, to
    to_dir = File.dirname(to)
    FileUtils.mkdir_p(to_dir)
    system 'git', 'mv', from, to
  end

  def update_file(filename)
    content = File.read(filename)
    new_content = yield content.dup
    if new_content != content
      LOGGER.info("update_file #{filename}")
      File.write(filename, new_content)
    end
  end


  def rename_constants(filename, mapping=[])
    update_file(filename) do
      |content|
      mapping.each do
        |from, to|
        content.gsub! from, to
      end
      content
    end
  end

end


class ClassFixer

  def initialize(content)
    @content = content.dup
  end

  attr_reader :content

  def indent
    content.gsub! /^(?!\s*$)/, '  '
  end

  def outdent
    content.gsub! /^  /, ''
  end

  def wrap_in_module(module_name)
    indent
    @content = "module #{module_name}\n" + @content + "end\n"
  end

  def unwrap_from_module
    # remove first class or module declaration
    content.sub! /^\s*(class|module).*?\n/, ''
    # remove last end
    content.sub! /\n+end\n*\z/m, "\n"
    outdent
  end

  def rename_classes(from, to)
    from_parts = from.split('::')
    to_parts = to.split('::')
    common_size = [from_parts.size, to_parts.size].min

    rename_parts = from_parts[-common_size..-1].zip(to_parts[-common_size..-1])
    remove_levels = from_parts.size - common_size
    add_parts = to_parts[0...-common_size]

    LOGGER.debug "remove_levels: #{remove_levels} add_parts: #{add_parts} rename_parts #{rename_parts}"
    remove_levels.times {unwrap_from_module}
    unless rename_parts == []
      content.gsub! /^(\s*(?:class|module)\s+)([\w:]+)(.*?)$/ do |m|
        pref, klass, subklass = $1, $2, $3
        if rename_parts != []
          from_part, to_part = rename_parts.pop
          fail "rename_classes: #{klass} != #{from_part}" if klass != from_part
        else
          to_part = klass
        end
        pref + to_part + subklass
      end
    end
    fail "rename_classes: not all parts (#{rename_parts}) renamed in #{from}" if rename_parts != []
    add_parts.reverse.each {|part| wrap_in_module(part)}
    self
  end
end

# git mv files
# rename/unwrap constants in each renamed file
# rename contsants in every other files

require 'yaml'
plan = YAML.load_file(ARGV[0])

cr = ClassRenamer.new

# git mv files
# rename/unwrap constants in each renamed file
# rename contsants in every other files
const_mapping = {}

plan.each do |p|
  from_path = p["from"]
  to_path = p["to"]
  from_class = cr.get_class(from_path)
  to_class = cr.get_class(to_path)
  cr.git_mv from_path, to_path
  cr.update_file to_path do |content|
    ClassFixer.new(content).rename_classes(from_class, to_class).content
  end
  const_mapping[from_class] = to_class
end

files = `git ls-files '*.rb'`.split(?\n)
files.each do |file|
  cr.rename_constants file, const_mapping
end
