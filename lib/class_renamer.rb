require 'fileutils'
require 'active_support/inflector'
class ClassRenamer

  def initialize(logger:nil)
    @logger = logger
  end

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
      @logger.info("update_file #{filename}") if @logger
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
