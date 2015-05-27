require 'fileutils'
require 'active_support/inflector'
class ClassRenamer

  def initialize(logger:nil)
    @logger = logger
  end

  def get_class(path)
    klass = path.sub(%r[^(app|test)/[^/]+/], '').sub(/\.rb$/, '')
    klass = ActiveSupport::Inflector.camelize(klass)
  end

  def git_mv from, to
    return if from == to
    to_dir = File.dirname(to)
    FileUtils.mkdir_p(to_dir)
    system 'git', 'mv', from, to
  end

  def update_file(filename)
    content = File.read(filename)
    new_content = yield content.dup
    if new_content != content
      @logger.info("update_file #{filename}") if @logger
      File.write(filename, new_content)
    end
  end


  def rename_constants(filename, mapping=[])
    update_file(filename) do |content|
      mapping.each do |from, to|
        # prevent false matching, like Foo and FooTest
        # still try not prevent matching on ::Foo
        from_regex = /(?<!\w::)\b#{from}\b/
        content.gsub! from_regex, to
      end
      content
    end
  end

end
