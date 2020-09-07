require "json"

module Caniuse
  def self.load_file(data)
    case data
    when String
      load File.read(data)
    when Pathname, File
      load data.read
    else
      raise ArgumentError, "`#{data} is not a valid file object or filepath"
    end
  end

  def self.load(data)
    DataSet.new JSON.parse(data)
  end

  class DataSet
    def initialize(source)
      @agents = AgentList.new source.delete("agents")
      @updated = @version = source.delete("updated")
    end
  end

  class AgentList
    def initialize(agents_properties)
      @agents = agents_properties.map { |name, properties| Agent.new(name, properties) }
    end
  end

  class Agent
    def initialize(name, properties)
      @name = name
      @browser = properties["browser"]
      @abbr = properties["abbr"]
      @prefix = properties["prefix"]
      @type = properties["type"]
      @usage_global = properties["usage_global"]
      @current_version = Float(properties["current_version"])

      @version_list = properties["version_list"].map do |version_info|
        Version.new(self, version_info)
      end
    end

    class Version
      def initialize(agent, properties)
        @agent = agent

        @version = @number = Float(properties["version"]) rescue byebug
        @global_usage = properties["global_usage"]
        @era = properties["era"]
        @prefix = properties["prefix"]

        if properties["release_date"]
          @release_date = Time.at(properties["release_date"]).utc
        end
      end
    end
  end
end
