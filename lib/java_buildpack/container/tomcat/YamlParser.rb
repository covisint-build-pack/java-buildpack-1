require 'yaml'
require 'pp'
require 'open-uri'
require 'rexml/document'
require 'java_buildpack/component/base_component'


class MvnDownloadArtifact
  attr_reader :downloadUrl, :openUriDownloadUrl,:sha1, :version, :artifactname
  def initialize(downloadUrl, openUriDownloadUrl, sha1, version, artifactname)
    # Instance variables
    @downloadUrl = downloadUrl
    @openUriDownloadUrl= openUriDownloadUrl
    @sha1 = sha1
    @version = version
    @artifactname = artifactname
  end
end

class YamlParser < JavaBuildpack::Component::BaseComponent
  
  SHA1 = 'artifact-resolution/data/sha1'
  REPOSITORY_PATH = 'artifact-resolution/data/repositoryPath'
  def initialize(context)
     super(context)
     @application.root.entries.find_all do |p|               
                           # load yaml file from app dir
                           if p.fnmatch?('*.yaml')
                             @config=YAML::load_file(File.join(@application.root.to_s, p.to_s))
                             
                             unless @config.nil? || @config == 0                      
                              @location =  @config["repository"]["location"]
                              @repoid =  @config["repository"]["repo-id"]
                              @username =  @config["repository"]["authentication"]["username"]
                              @password =  @config["repository"]["authentication"]["password"]
                              #@url = "http://#{@username}:#{@password}@#{@location}?"
                              @mvngavUrl = "http://#{@location}/service/local/artifact/maven/resolve?"
                              @artifactUrl = "http://#{@username}:#{@password}@#{@location}/service/local/artifact/maven/content?"
                              @contentUnauthUrl= "http://#{@location}/service/local/artifact/maven/content?"
                              #@repopath = "&r=#{@repoid}"
                              @repopath = "&r=#{@repoid}"
                              end
                            end
            end  
           
  end
  
def detect
  end
        
  
  def compile
    unless @config.nil? || @config == 0
      libs=read_config "libraries", "jar"
      libs.each do |lib| 
        download_jar lib.version.to_s, lib.downloadUrl.to_s, lib.artifactname.to_s, tomcat_lib
      end 
    end  
    
  end
  def release
       end
  
  def read_config(component, type)
    @compMaps||= Array.new
    @config[component].each do |val|

      begin
        #parse YAML and get the xml response
        contextPath = val.gsub(/\s/,"&").gsub(":","=")+"#{@repopath}&p=#{type}"

        mvnXmlResponse=open(@mvngavUrl+contextPath, http_basic_authentication: ["#{@username}", "#{@password}"]).read
      rescue OpenURI::HTTPError => ex
        puts "wrong url endpoint: #{@mvngavUrl+contextPath}"
        abort
      end

      #from the mvn artifact xml response consrtuct final downloadable URL
      mvnDownloadUrl = "#{@artifactUrl}#{contextPath}"
      openUriDownloadUrl="#{@contentUnauthUrl}#{contextPath}"

      # create Object which is having downloadUrl, sha1 (for checksum) and version (for cache history)
      @compMaps << MvnDownloadArtifact.new(mvnDownloadUrl,
      openUriDownloadUrl,
      REXML::Document.new(mvnXmlResponse).elements[SHA1].text,
      val.gsub(/\s/,"&").gsub(":","=").rpartition("=").last, 
      REXML::Document.new(mvnXmlResponse).elements[REPOSITORY_PATH].text.rpartition("/").last)

    end

    return @compMaps

  end

    # The Tomcat +lib+ directory
    #
    # @return [Pathname] the Tomcat +lib+ directory
    def tomcat_lib
      @droplet.sandbox + 'lib'
    end
end
