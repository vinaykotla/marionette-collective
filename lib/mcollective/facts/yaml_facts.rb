module MCollective
  module Facts
    require 'yaml'

    # A factsource that reads a hash of facts from a YAML file
    #
    # Multiple files can be specified seperated with a : in the
    # config file, they will be merged with later files overriding
    # earlier ones in the list.
    class Yaml_facts<Base
      def initialize
        @yaml_file_mtimes = {}

        super
      end

      def load_facts_from_source
        config = Config.instance

        fact_files = config.pluginconf["yaml"].split(File::PATH_SEPARATOR)
        facts = {}

        fact_files.each do |file|
          begin
            if File.exist?(file)
	      if YAML.respond_to? :safe_load
                facts.merge!(YAML.safe_load(File.read(file), [Symbol], [], true))
	      else
                facts.merge!(YAML.load(File.read(file)))  # rubocop:disable Security/YAMLLoad
              end
            else
              raise("Can't find YAML file to load: #{file}")
            end
          rescue Exception => e
            Log.error("Failed to load yaml facts from #{file}: #{e.class}: #{e}")
          end
        end

        facts
      end

      # force fact reloads when the mtime on the yaml file change
      def force_reload?
        config = Config.instance

        fact_files = config.pluginconf["yaml"].split(File::PATH_SEPARATOR)

        fact_files.each do |file|
          @yaml_file_mtimes[file] ||= File.stat(file).mtime
          mtime = File.stat(file).mtime

          if mtime > @yaml_file_mtimes[file]
            @yaml_file_mtimes[file] = mtime

            Log.debug("Forcing fact reload due to age of #{file}")

            return true
          end
        end

        false
      end
    end
  end
end
