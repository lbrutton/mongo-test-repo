class Racer
  include ActiveModel::Model

  attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

  # convenience method for access to client in console
  def self.mongo_client
   Mongoid::Clients.default
  end

  # convenience method for access to zips collection
  def self.collection
   self.mongo_client['racers']
  end

  def initialize(params={})
    @id=params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
  end

  # implement a find that returns a collection of document as hashes. 
  # Use initialize(hash) to express individual documents as a class 
  # instance. 
  #   * prototype - query example for value equality
  #   * sort - hash expressing multi-term sort order
  #   * skip - document to start results
  #   * limit - number of documents to include
  def self.all(prototype={}, sort={:number=>1}, skip=0, limit=nil)
    #map internal :population term to :pop document term

    result=collection.find(prototype)
          .projection({_id:true, number:true, group:true, first_name:true, last_name:true, secs:true, gender:true})
          .sort(sort)
          .skip(skip)
    result=result.limit(limit) if !limit.nil?

    return result
  end

  def self.paginate(params)
    Rails.logger.debug("paginate(#{params})")
    page=(params[:page] ||= 1).to_i
    limit=(params[:per_page] ||= 10).to_i
    skip=(page-1)*limit
    sort=params[:sort] ||= {:number=>1}

    #get the associated page of racers -- eagerly convert doc to Racer
    racers=[]
    all({}, sort, skip, limit).each do |doc|
      racers << Racer.new(doc)
    end

    #get a count of all documents in the collection
    total=all({}, sort, 0, 1).count
    
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end    
  end

  # locate a specific document. Use initialize(hash) on the result to 
  # get in class instance form
  def self.find id
    #id2 = id.to_s
    result= collection.find({_id:BSON::ObjectId(id.to_s)}).first
    return result.nil? ? nil : Racer.new(result)
  end 

  def save
    result=self.class.collection.insert_one(id:@id, number:@number, first_name:@first_name, last_name:@last_name, gender:@gender, group:@group, secs:@secs)
    @id=result.inserted_id
  end

  def update(params)
    @number=params[:number].to_i
    @first_name=params[:first_name]
    @last_name=params[:last_name]
    @gender=params[:gender]
    @group=params[:group]
    @secs=params[:secs].to_i
    params.slice!(:number,:first_name,:last_name,:gender,:group,:secs) if !params.nil?
    Rails.logger.debug {"Params:#{@number},#{@first_name},#{@last_name},#{@gender},#{@group},#{@secs}"}
    self.class.collection.find(_id:BSON::ObjectId(@id.to_s)).update_one(:$set=>{number:@number,first_name:@first_name,last_name:@last_name,gender:@gender,group:@group,secs:@secs})
  end

  def destroy
    self.class.collection.find(number:@number).delete_one()
  end

  def persisted?
    !@id.nil?
  end

  def created_at
    nil
  end

  def updated_at
    nil
  end

end
