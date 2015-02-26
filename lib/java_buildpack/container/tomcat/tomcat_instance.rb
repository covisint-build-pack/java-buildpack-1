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

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_utils'
require 'java_buildpack/util/tokenized_version'
require 'java_buildpack/container/tomcat/YamlParser'
require 'open-uri'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for the Tomcat instance.
    class TomcatInstance < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
       
        super(context) { |candidate_version| candidate_version.check_size(3) }
        @yamlobj=YamlParser.new(context)
        puts "#{@yamlobj}"
       end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
          if isYaml?
          wars = []
          puts "#{@yamlobj}"
          libs=@yamlobj.read_config "webapps", "war"
          puts "#{libs}"
          libs.each do |lib|
           
            open("http://nexus.covisintrnd.com:8081/nexus/service/local/artifact/maven/content?g=com.test&a=project&v=1.0&r=test_repo_1_release&p=war", http_basic_authentication: ["admin", "admin123"]) { 
            |file|  puts file.path
           link_to(file.path, tomcat_webapps)
          #open(lib.downloadUrl.to_s) { |file| 
           #   puts file.path
             }
          end
        else
          download(@version, @uri) { |file| expand file }
          link_webapps(@application.root.children, root)
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

      TOMCAT_8 = JavaBuildpack::Util::TokenizedVersion.new('8.0.0').freeze

      private_constant :TOMCAT_8

      def configure_jasper
        return unless @version < TOMCAT_8

        document = read_xml server_xml
        server   = REXML::XPath.match(document, '/Server').first

        listener = REXML::Element.new('Listener')
        listener.add_attribute 'className', 'org.apache.catalina.core.JasperListener'

        server.insert_before '//Service', listener

        write_xml server_xml, document
      end

      def configure_linking
        document = read_xml context_xml
        context  = REXML::XPath.match(document, '/Context').first

        if @version < TOMCAT_8
          context.add_attribute 'allowLinking', true
        else
          context.add_element 'Resources', 'allowLinking' => true
        end

        write_xml context_xml, document
      end

      def expand(file)
        with_timing "Expanding Tomcat to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox
          shell "tar xzf #{file.path} -C #{@droplet.sandbox} --strip 1 --exclude webapps 2>&1"

          @droplet.copy_resources
          configure_linking
          configure_jasper
        end
      end

      def root
        tomcat_webapps + 'ROOT'
      end

      def tomcat_datasource_jar
        tomcat_lib + 'tomcat-jdbc.jar'
      end

      def web_inf_lib
        @droplet.root + 'WEB-INF/lib'
      end

      def link_webapps(from, to)
        webapps = []
        webapps.push(from.find_all {|p| p.fnmatch('*.war')})

        # Explode zips
        # TODO: Need to figure out a way to add 'rubyzip' gem to the image
        #       and avoid shelling out to "unzip".
        zips = from.find_all {|p| p.fnmatch('*.zip')}
        zips.each do |zip|
          IO.popen(['unzip', '-o', '-d', @application.root.to_s, zip.to_s, '*.war']) do |io|
            io.readlines.each do |line|
              line.gsub!(/\s*$/, '')
              next unless line.chomp =~ /\.war$/
              war = line.split()[-1]
              webapps.push(Pathname.new(@application.root.to_s) + war)
            end
          end
        end
        webapps.flatten!

        if (not webapps.empty?)
          link_to(webapps, tomcat_webapps)
        else
          link_to(from, root)
          @droplet.additional_libraries << tomcat_datasource_jar if tomcat_datasource_jar.exist?
          @droplet.additional_libraries.link_to web_inf_lib
        end
      end
      def isYaml?
                #puts "****************#{@application.root.entries}"
               @application.root.entries.find_all do |p|
                   if p.fnmatch?('*.yaml')
                          return true
                   end  
                   
               end  
               return false
         end  
    end
  end
end
