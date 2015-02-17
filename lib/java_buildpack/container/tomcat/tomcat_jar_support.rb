# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_utils'


module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat lifecycle support.
    class TomcatJarSupport < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        jar_names.each do |jar_name|
          download_jar(jar_name, tomcat_lib)
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

      private

      def jar_names
       #"h3.zip"

pwd = Pathname.pwd + 'h3.zip'
zips = pwd.find_all {|p| p.fnmatch('h3.zip')}
jars = []
zips.each do |zip|
	IO.popen(['unzip', '-o', '-d', pwd.to_s, zip.to_s, '*.jar']) do |io|
		io.readlines.each do |line|
			line.gsub!(/\s*$/, '')
			next unless line.chomp =~ /\.jar$/
			jar = line.split()[-1]
			jars.push(jar)
		end
	end
end
 
        
    end
    
    

end
end
end