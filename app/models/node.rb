class Node < ActiveRecord::Base
  using_access_control
  has_many :certs
  has_many :prefix_delegation
  has_many :tincs
  belongs_to :status
  has_many :node_registrations
  attr_accessible :wlan_mac, :bat0_mac, :current_ip, :updated_at, :status_id
  
  ## All nodes, where: VPN-Status is up, or tinc is trying to connect  
  def self.registerable(remote_addr)
    logger.info "Remote-addr is: #{remote_addr}"
    running_nodes = Node.where(:status_id => Status.up, :user_id => nil, :current_ip => remote_addr)
    connecting_nodes = (Node.unregistred.keep_if {|n| n.current_ip == remote_addr && n.node_registrations.size == 0}) || []
    running_nodes + connecting_nodes
  end
  
  def current_status
    self.status || Status.find_by_name("down")
  end
  
  def self.all_unregistered
    Node.all(:include => :node_registrations).keep_if {|n| n.node_registrations.size == 0}
  end
  
  def current_ip
    #permitted_to! :show_ip
    ip = read_attribute :current_ip
    logger.info "IP is #{ip}"
    return ip
  end

  def to_s
    "#{wlan_mac}"
  end

  
  private
  def self.unregistred(historic = false)
    nodes = {}
    t180_secs_ago = Time.now - 180
    logfile = Tinc.config['logfile']
    # May 26 22:40:03 felix tinc.intracity[285180]: Error while processing ID from b0487a96f582 (84.63.38.123 port 42756)
    IO.popen("#{logfile}") do |pipe|
      pipe.each_line do |line|
        md = line.match '(.+) .+ tinc..+\[\d+\]: Error while processing ID from (.+) \((.+) port \d+\)'
        if(md)
          logger.info "Got line-match: #{md}"
          time_stmp = md[1]
          node_mac = md[2]
          node_ip = md[3]
          md2 = time_stmp.match '(\w+) +(\d+) (\d\d):(\d\d):(\d\d)'
          if(md2)
          	yet = Time.local(t180_secs_ago.year, md2[1], md2[2],md2[3],md2[4],md2[5])
          	# Since tinc tries to connect every 180secs, we will use data younger than 180secs only
          	ago = yet - t180_secs_ago #If ago > 0 => Time > t180_secs_ago => Recent enough
          	logger.info "Got md2-match #{md2} - ago is #{ago}"
          	if(ago > 0 || historic) # If recent enough or historic nodes should be included ...
          	    nodes[node_mac] = Node.find_or_create_by_wlan_mac(node_mac)
            		nodes[node_mac].update_attributes({
            		  :wlan_mac => node_mac, 
            		  :bat0_mac => node_mac, 
            		  :current_ip => node_ip, 
            		  :updated_at => DateTime.parse(yet.to_s)
          		  }) if nodes[node_mac].permitted_to? :update
          	end
          end
        else
        	logger.info "No Line-Match #{line}"
        end
      end
    end
    return nodes.values
  end

end
