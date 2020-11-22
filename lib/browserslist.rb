require "parslet"

module Browserslist
  def self.call(*inputs)
    inputs.map do |input|
      selection = input.strip
      filter = Filters.detect(selection)

      if filter.nil?
        raise ArgumentError, "invalid selection `#{selection}'"
      end

      filter
    end
  end

  module Filters
    def self.detect(input)
      selection = input.strip

      And.(selection) ||
        Or.(selection) ||
        LastVersions.(selection) ||
        UsagePercentage.(selection) ||
        BrowserVersion.(selection) ||
        Dead.(selection)
    end

    module Unions
      def |(other)
        Or.new(self, other)
      end

      def &(other)
        And.new(self, other)
      end
    end

    class And
      include Unions

      REGEXP = /\s+and\s+/i

      def self.call(selection)
        if REGEXP.match?(selection)
          selection.split(REGEXP).map { |subselect| Filters.detect(subselect) }.reduce(:&)
        end
      end

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class Or
      include Unions

      REGEXP = /\s+or\s+|\s*,\s*/i

      def self.call(selection)
        if REGEXP.match?(selection)
          selection.split(REGEXP).map { |subselect| Filters.detect(subselect) }.reduce(:|)
        end
      end

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class LastVersions
      include Unions

      REGEXP = /
        (?<exclude>not\s+)?
        last
        \s+
        (?<version_count>\d+)
        \s+
        (?<browser>[\w\s]+)?
        (?<major>major\s+)?
        \s+
        versions?
      /xi

      def self.call(query)
        REGEXP.match(query) do |match_data|
          new version_count: match_data[:version_count],
            major: match_data[:major],
            browser: match_data[:browser],
            exclude: !!match_data[:exclude]
        end
      end

      def initialize(version_count:, browser: "", major: false, exclude: false)
        @version_count = Integer(version_count)
        @browser = browser.to_s.strip
        @major = major
        @exclude = exclude
      end
    end

    class UsagePercentage
      include Unions

      REGEXP = /
        (?<exclude>not\s+)?
        (?<operator>>=|<=|>|<)
        (?<percentage>[0-9]+(?:\.[0-9]{1,2})?)%
        (?:\s+in\s+(?<region>\w+))?
      /xi

      def self.call(query)
        REGEXP.match(query) do |match_data|
          new operator: match_data[:operator],
            percentage: match_data[:percentage],
            region: match_data[:region],
            exclude: !!match_data[:exclude]
        end
      end

      def initialize(operator:, percentage:, region: nil, exclude: false)
        @operator = operator
        @percentage = Float(percentage)
        @region = region
        @exclude = exclude
      end
    end

    class Dead
      include Unions

      REGEXP = /(?<exclude>not\s+)?dead/i

      def self.call(query)
        REGEXP.match(query) do |match_data|
          new exclude: !!match_data[:exclude]
        end
      end

      def initialize(exclude: false)
        @exclude = exclude
      end
    end

    class BrowserVersion
      include Unions

      REGEXP = /
        (?<exclude>not\s+)?
        (?<browser>[\w\s]+)
        \s*
        (?<operator>>=|<=|>|<)
        \s*
        (?<version>[0-9]+)
      /xi

      def self.call(query)
        REGEXP.match(query) do |match_data|
          new browser: match_data[:browser],
            operator: match_data[:operator],
            version: match_data[:version],
            exclude: !!match_data[:exclude]
        end
      end

      def initialize(browser:, operator:, version:, exclude: false)
        @browser = browser.strip
        @operator = operator
        @version = Integer(version)
        @exclude = exclude
      end
    end

    class Parser < Parslet::Parser
      root(:filter)

      rule(:filter) { last_versions | percentage_usage | version_comparison | dead }
      rule(:filters) { (filter >> (str(",") >> whitespace?)).repeat }

      rule(:last_versions) do
        not! >>
          stri("last") >> whitespace >>
          number.as(:count) >>
          word.as(:semantic) >>
          words.as(:browser) >>
          (stri("version") >> stri("s").maybe)
      end

      rule(:version_comparison) do
        not! >>
          words.as(:browser) >>
          operator.as(:operator) >>
          number.as(:version)
      end

      rule(:percentage_usage) do
        not! >>
          operator.as(:operator) >>
          percentage.as(:percentage) >>
          in_region.maybe
      end

      rule(:dead) { not! >> stri("dead").as(:dead) }

      rule(:in_region) { str("in") >> whitespace >> word.as(:region) }

      rule(:not!) { (stri("not") >> whitespace).maybe.as(:exclude) }
      rule(:operator) { match("[<>]") >> str("=").maybe >> whitespace? }

      rule(:percentage) do
        number >> (str(".") >> number).maybe >> str("%") >> whitespace?
      end

      rule(:number) { match["0-9"].repeat(1) >> whitespace? }

      rule(:word) { match["a-zA-Z"].repeat(1) >> whitespace? }
      rule(:words) { word.repeat }

      rule(:whitespace) { match("\s").repeat(1) }
      rule(:whitespace?) { whitespace.maybe }

      def stri(value)
        value.split(//).map! { |char| match["#{char.downcase}#{char.upcase}"] }.reduce(:>>)
      end
    end
  end
end
