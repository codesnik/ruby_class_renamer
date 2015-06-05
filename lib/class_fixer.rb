class ClassFixer

  def initialize(content, reindent: true, flat_from: false, flat_to: false)
    @content = content.dup
    @indent_level = 0
    @reindent = reindent
    @flat_from = flat_from
    @flat_to = flat_to
  end

  attr_reader :content
  attr_reader :indent_level
  attr_reader :reindent
  attr_reader :flat_from
  attr_reader :flat_to

  def indent
    @indent_level += 1
    content.gsub! /^(?!\s*$)/, '  '
    self
  end

  def outdent
    @indent_level -= 1
    content.gsub! /^  /, ''
    self
  end

  def wrap_in_module(module_name)
    indent if reindent
    @content = "module #{module_name}\n" + @content + "end\n"
    self
  end

  def unwrap_from_module
    # remove first class or module declaration
    content.sub! /^\s*(class|module).*?\n/, ''
    # remove last end
    content.sub! /\n+end\n*\z/m, "\n"
    outdent if reindent
    self
  end

  def rename_classes(from, to)
    from_parts = flat_from ? [from] : from.split('::')
    to_parts = flat_to ? [to] : to.split('::')
    common_size = [from_parts.size, to_parts.size].min

    rename_parts = from_parts[-common_size..-1].zip(to_parts[-common_size..-1])
    remove_levels = from_parts.size - common_size
    add_parts = to_parts[0...-common_size]

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

