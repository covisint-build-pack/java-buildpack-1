# Shared library support -we can upload any external project specific jars into tomcat sharedlib folder
# Current s3 location: https://s3-us-west-2.amazonaws.com/covisint.com-shared-libs
# This above s3 location we should upload one or more custom libs as a zip file
# user should make entry of uploaded zip file into index.yml file

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_utils'


module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat lifecycle support.
    class SharedLibSupport < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
          download_zip false, tomcat_lib
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
