require 'yaml'
require 'pp'
require 'open-uri'
require 'rexml/document'

class MvnDownloadArtifact
  attr_reader :downloadUrl, :sha1, :version
  def initialize(downloadUrl, sha1, version)
    # Instance variables
    @downloadUrl = downloadUrl
    @sha1 = sha1
    @version = version
  end
end

class YamlParser < JavaBuildpack::Component::BaseComponent
  SHA1 = 'artifact-resolution/data/sha1'
  def initialize(context)
     @application.root.entries.find_all do |p|               
                           # load yaml file from app dir
                           if p.fnmatch?('*.yaml')
                             @config=YAML::load_file(File.join(@application.root.to_s, p.to_s))
                            end
                          end  
    @location =  @config["repository"]["location"]
    @repoid =  @config["repository"]["repo-id"]
    $username =  @config["repository"]["authentication"]["username"]
    $password =  @config["repository"]["authentication"]["password"]
    #@url = "http://#{@username}:#{@password}@#{@location}?"
    @mvngavUrl = "http://#{@location}/service/local/artifact/maven/resolve?"
    @artifactUrl = "http://#{@location}/service/local/artifact/maven/content?"
    @repopath = "&r=#{@repoid}"

  end

  def read_config(component)
    @compMaps||= Array.new
    @config[component].each do |val|

      begin
        #parse YAML and get the xml response
        contextPath = val.gsub(/\s/,"&").gsub(":","=")+"#{@repopath}"

        mvnXmlResponse=open(@mvngavUrl+contextPath, http_basic_authentication: ["#{$username}", "#{$password}"]).read
      rescue OpenURI::HTTPError => ex
        puts "wrong url endpoint: #{@mvngavUrl+contextPath}"
        abort
      end

      #from the mvn artifact xml response consrtuct final downloadable URL
      mvnDownloadUrl = "#{@artifactUrl}#{contextPath}"

      # create Object which is having downloadUrl, sha1 (for checksum) and version (for cache history)
      @compMaps << MvnDownloadArtifact.new(mvnDownloadUrl,
      REXML::Document.new(mvnXmlResponse).elements[SHA1].text,
      val.gsub(/\s/,"&").gsub(":","=").rpartition("=").last)

    end

    return @compMaps

  end

end

object=YamlParser.new("*.yaml")
arry = object.read_config "libraries"
puts arry[0].downloadUrl
p arry[0].sha1
p arry[0].version

#mvnXmlResponse=open('http://#{@location}/content/repositories/#{@repoid}#{REXML::Document.new(mvnXmlResponse).elements['artifact-resolution/data/repositoryPath'].text}', http_basic_authentication: ["#{$username}", "#{$password}"]).read
#http://nexus.covisintrnd.com:8081/nexus/service/local/artifact/maven/content?g=com.test&a=project&v=1.0&r=test_repo_1_release
#http://nexus.covisintrnd.com:8081/nexus/service/local/artifact/maven/resolve?g=com.test&a=project&v=1.0&r=test_repo_1_release
#iterate the map and call the download with URI , version
#puts map
map=object.read_config "webapps"
#puts map
#object.construct_uri
