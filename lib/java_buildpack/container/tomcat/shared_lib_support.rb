# Shared library support -we can upload any external project specific jars into tomcat sharedlib folder
# Current s3 location: https://s3-us-west-2.amazonaws.com/covisint.com-shared-libs
# This above s3 location we should upload one or more custom libs as a zip file
# user should make entry of uploaded zip file into index.yml file

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_utils'
require 'yaml'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat lifecycle support.
    class SharedLibSupport < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
           @application.root.entries.find_all do |p|               
                       # load yaml file from app dir
                       if p.fnmatch?('*.yaml')
                         config=YAML::load_file(File.join(@application.root.to_s, p.to_s))
                         @sharedlibflag = config["applications"]["sharedlibflag"]
                         
                        end
                      end  
         if @sharedlibflag == true              
          download_zip version,uri,false, tomcat_lib
          
         else
           true
         end
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      end
end
end
