require 'active_support/inflector'
require 'fileutils'


class ClassRenamer

  # in every file
  rename_constants


  def get_class(path)
    klass = path.sub(%r[^app/[^/]+/], '').sub(/\.rb$/, '')
    klass = ActiveSupport::Inflector.camelize(klass)
  end

  def get_levels(class_name)
    class_name.scan('::').count
  end

  def get_levels(class_name)
    class_name.split('::')
  end

  def indent(content)
    content.gsub /^(?!\s*$)/, '  '
  end

  def outdent(content)
    content.gsub /^  /, ''
  end

  def wrap_in_module(content, module_name)
    "module #{module_name}\n" + indent(content) + "end\n"
  end


  def unwrap_from_module(content)
    # remove first class or module declaration
    content.sub! /^\s*(class|module).*?\n/, ''
    # remove last end
    content.sub! /\n+end\n*\z/m, "\n"
    outdent(content)
  end

  def git_mv from, to
    to_dir = File.dirname(to)
    FileUtils.mkdir_p(to_dir)
    system 'git', 'mv', from, to
  end

  def update_file(filename)
    content = File.read(filename)
    new_content = yield content.dup
    File.write(filename, content) if new_content != content
  end

  def rename_class(from, to, content)
    from_parts = from.split('::')
    to_parts = to.split('::')
    common_size = [from_parts.size, to_parts.size].min

    rename_parts = from_parts[-common_size..-1].zip(to_parts[-common_size..-1])
    remove_levels = from_parts.size - common_size
    add_parts = to_parts[0...-common_size]

    # puts "remove_levels: #{remove_levels}"
    # puts "add_parts: #{add_parts}"
    # puts "rename_parts #{rename_parts}"
    remove_levels.times {content = unwrap_from_module(content)}
    unless rename_parts == []
      content.gsub! /^\s*(class|module).*?\n/ do |m|
        rename_parts.
      end
    end

    end
    add_parts.reverse.each {|part| content = wrap_in_module(content, part)
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
