require "sdoc_site"
require "sdoc_site/version"

class SDocSite::Builds
  attr_accessor :root
  
  SIMPLE_BUILD_REGEXP = /^([^_-]+)-([^_-]+)$/
  MERGED_BUILD_REGEXP = /^([^_-]+-[^_-]+_)+[^_-]+-[^_-]+$/
  
  class Build
    include Comparable
    attr_accessor :name
    attr_accessor :versions
    
    def initialize(name, versions = [])
      @name = name
      @versions = versions
    end
    
    def self.from_str str
      (tmp, name, version) = *str.match(SIMPLE_BUILD_REGEXP)
      self.new name, [SDocSite::Version.new(version)]
    end
    
    def to_s
      "#{name}-#{versions.max.to_tag}"
    end
    
    def <=>(other)
      [@name, @versions.max] <=> [other.name, other.versions.max]
    end
    
    def ==(other)
      other.name == @name && @versions.sort == other.versions.sort
    end
  end
  
  class MergedBuild
    attr_accessor :builds
    
    def initialize
      @builds = []
    end
    
    def ==(other)
      builds.sort == other.builds.sort
    end
    
    def self.from_str str
      parts = str.split('_')
      merged = self.new
      parts.each do |part|
        merged.builds << Build.from_str(part)
      end
      merged
    end
  end
  
  def initialize(root)
    @root = root
  end
  
  def simple_builds
    raw_builds = select_dirs SIMPLE_BUILD_REGEXP
    builds = {}
    raw_builds.each do |raw|
      build = Build.from_str raw
      unless builds.has_key? build.name
        builds[build.name] = build
      else
        builds[build.name].versions << build.versions.first
      end
    end
    builds.values
  end
  
  def merged_builds
    raw_builds = select_dirs MERGED_BUILD_REGEXP
    result = []
    raw_builds.each do |raw|
      result << MergedBuild.from_str(raw)
    end
    result
  end
  
protected
  def select_dirs regexp
    Dir.new(@root).select do |name|
      File.directory?(File.join(@root, name)) && name.match(regexp)
    end
  end
end