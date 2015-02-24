require 'yaml'
require 'pp'
require 'open-uri'
require 'rexml/document'
require 'java_buildpack/component/base_component'
require 'java_buildpack/container/tomcat/tomcat_utils'

class MvnDownloadArtifact
  attr_reader :downloadUrl, :sha1, :version, :jarname
  def initialize(downloadUrl, sha1, version, jarname)
    # Instance variables
    @downloadUrl = downloadUrl
    @sha1 = sha1
    @version = version
    @jarname = jarname
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
                            end
                          end  
    @location =  @config["repository"]["location"]
    @repoid =  @config["repository"]["repo-id"]
    @username =  @config["repository"]["authentication"]["username"]
    @password =  @config["repository"]["authentication"]["password"]
    #@url = "http://#{@username}:#{@password}@#{@location}?"
    @mvngavUrl = "http://#{@location}/service/local/artifact/maven/resolve?"
    @artifactUrl = "http://#{@username}:#{@password}@#{@location}/service/local/artifact/maven/content?"
    @repopath = "&r=#{@repoid}"

  end
def detect
  end
        
  
  def compile
    arry=read_config "libraries"
    puts arry[0].downloadUrl
    puts arry[0].version
    download_jar arry[0].version.to_s, arry[0].downloadUrl.to_s, arry[0].jarname.to_s, tomcat_lib
    #download_jar "1.0.0", "http://admin:admin123@nexus.covisintrnd.com:8081/nexus/service/local/artifact/maven/content?g=com.test&a=project&v=1.0&r=test_repo_1_release", "project1" 
    #download_jar arry[0].downloadUrl, arry[0].version,project-1
      
    
  end
  def release
       end
  def read_config(component)
    @compMaps||= Array.new
    @config[component].each do |val|

      begin
        #parse YAML and get the xml response
        contextPath = val.gsub(/\s/,"&").gsub(":","=")+"#{@repopath}"

        mvnXmlResponse=open(@mvngavUrl+contextPath, http_basic_authentication: ["#{@username}", "#{@password}"]).read
      rescue OpenURI::HTTPError => ex
        puts "wrong url endpoint: #{@mvngavUrl+contextPath}"
        abort
      end

      #from the mvn artifact xml response consrtuct final downloadable URL
      mvnDownloadUrl = "#{@artifactUrl}#{contextPath}"

      # create Object which is having downloadUrl, sha1 (for checksum) and version (for cache history)
      @compMaps << MvnDownloadArtifact.new(mvnDownloadUrl,
      REXML::Document.new(mvnXmlResponse).elements[SHA1].text,
      val.gsub(/\s/,"&").gsub(":","=").rpartition("=").last, 
      REXML::Document.new(mvnXmlResponse).elements[REPOSITORY_PATH].text.rpartition("/").last)

    end

    return @compMaps

  end

end
