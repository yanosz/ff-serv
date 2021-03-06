class NodesController < ApplicationController
  #filter_resource_access
  before_filter :authenticate_localhost, :only => :update_status
  # GET /nodes
  # GET /nodes.xml
  def index
    @nodes = Node.all
    @registerable_nodes = Node.registerable(request.remote_ip)
    @unregistered = Node.all_unregistered if permitted_to? :all_unregistered, :nodes
    @node_registrations = NodeRegistration.all
    
    if permitted_to? :register_all, :nodes
      @registerable_nodes = @unregistered
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @nodes }
    end
  end

  def update_status
    mac = params[:mac]
    status_str = params[:status]
    ip = params[:ip]
    status = Status.find_by_name(status_str)
    node = Node.find_by_wlan_mac(mac)
    node.update_attributes({
        :status_id => status.id,
        :current_ip => ip
    })
    render :text => "Node #{mac} is #{status} - ip is #{ip} \n"
  end

  # # GET /nodes/1
  # # GET /nodes/1.xml
  # def show
  #   @node = Node.find(params[:id])
  # 
  #   respond_to do |format|
  #     format.html # show.html.erb
  #     format.xml  { render :xml => @node }
  #   end
  # end
  # 
  # GET /nodes/new
   # GET /nodes/new.xml
   # def new
   #   @node = Node.new
   # 
   #   respond_to do |format|
   #     format.html # new.html.erb
   #     format.xml  { render :xml => @node }
   #   end
   # end
   
  # # GET /nodes/1/edit
  # def edit
  #   @node = Node.find(params[:id])
  # end
  # 
  # # POST /nodes
  # # POST /nodes.xml
  # def create
  #   @node = Node.new(params[:node])
  # 
  #   respond_to do |format|
  #     if @node.save
  #       format.html { redirect_to(@node, :notice => 'Node was successfully created.') }
  #       format.xml  { render :xml => @node, :status => :created, :location => @node }
  #     else
  #       format.html { render :action => "new" }
  #       format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # # PUT /nodes/1
  # # PUT /nodes/1.xml
  # def update
  #   @node = Node.find(params[:id])
  # 
  #   respond_to do |format|
  #     if @node.update_attributes(params[:node])
  #       format.html { redirect_to(@node, :notice => 'Node was successfully updated.') }
  #       format.xml  { head :ok }
  #     else
  #       format.html { render :action => "edit" }
  #       format.xml  { render :xml => @node.errors, :status => :unprocessable_entity }
  #     end
  #   end
  # end
  # 
  # # DELETE /nodes/1
  # # DELETE /nodes/1.xml
  # def destroy
  #   @node = Node.find(params[:id])
  #   @node.destroy
  # 
  #   respond_to do |format|
  #     format.html { redirect_to(nodes_url) }
  #     format.xml  { head :ok }
  #   end
  # end
end
