class PrintsController < ApplicationController
  before_filter :cache_index, :only => :index
  
  def index
    @print = Print.new

    respond_to do |format|
      format.html
    end
  end
  
  def create
    documents = Array.wrap(params[:print].delete(:documents))
    params[:print][:copies] = 1 if params[:print][:copies].blank?
    
    @print = Print.new(params[:print])
    @print.user = $redis.srandmember("users")
    
    documents.each do |document|
      doc = @print.documents.build
      doc.filename = document.try(:original_filename)
      doc.tempfile = document.try(:tempfile).try(:path)
    end

    respond_to do |format|
      if success = @print.save
        Resque.enqueue(PrintWorker, @print.id)
        flash[:user] = @print.user
        flash[:printer] = @print.printer
        format.html { redirect_to root_path(success: success) }
      else
        format.html { render action: "index" }
      end
    end
  end
  
  private
  def cache_index
    unless params[:success]
      expires_in 30.minutes, :public => true
    end
  end
end
