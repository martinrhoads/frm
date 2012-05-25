module FRM
  
  
  class Deb  < Base
    
    def initialize()
    end
    
    def generate_package_file(in_packages=[])
      packages = in_packages.sort { |a,b| a['Package'] <=> b['Package'] }
      package_file = ''
      packages.each { |package| package_file << generate_package_stub(package) }
      return package_file
    end

    
    def generate_package_stub(in_package={})
      package = in_package.dup
      package_stub = ''
      description = package.delete('Description') || "no description given"
      path_to_deb = package.delete 'path_to_deb'
      section = package.delete 'section'
      package["Filename"] = "pool/#{section}/#{package['Package'][0]}/#{package['Package']}/#{package['Package']}_#{package['Version']}_#{package['Architecture']}.deb"
      package["Size"] = File.new(path_to_deb).size
      package["MD5sum"] = self.compute_md5 File.read path_to_deb
      package["SHA1"] = compute_sha1 File.read path_to_deb
      package["SHA256"] = compute_sha2 File.read path_to_deb
      package["Description"] = description
      package.each { |key,value| package_stub << generate_package_line(key,value) }
      package_stub << "\n"
      return package_stub
    end
    
    
    def generate_package_release
      return "Component: main
Origin: apt.cloudscaling.com
Label: apt repository natty
Architecture: amd64
Description: Cloudscaling APT repository
"
    end
    
    
    def generate_package_line(key='',value='')
      valid_options = %w{Package Version Architecture Maintainer Standards-Version Homepage Priority Depends Filename Size SHA256 SHA1 MD5sum Description}
      raise "Bogus option passed: #{key}" unless valid_options.include?(key)                
      
      case key
      when 'Depends'
        return "Depends: #{value.join(', ')}\n"
      when 'Maintainer'
        return "Maintainer: <#{value}>\n"
      else
        return "#{key}: #{value}\n"
      end
    end
    
  end
  
end
