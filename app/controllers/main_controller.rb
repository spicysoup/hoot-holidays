class MainController < ApplicationController
  def index
  end

  def auto_complete
    @airports = Airport.ransack(iata_code_cont: params[:q]).result(distinct: true)

    respond_to do |format|
      format.html {}
      format.json {
        @airports = @airports.limit(5)
      }
    end
  end

  def search
    @dep_code, @dep_name = params[:dep].split(' - ')
    @arr_code, @arr_name = params[:arr].split(' - ')

    dep_airport = Airport.where(iata_code: @dep_code).limit 1
    arr_airport = Airport.where(iata_code: @arr_code).limit 1
    @flights = ScheduledFlight.where(from_airport_id: dep_airport.first.id, to_airport_id: arr_airport.first.id).limit 10

    respond_to do |format|
      format.js
    end
  end

  def choose_flight
    @passenger = populate_record :passenger, Passenger, params

    @countries = Country.all.map do |c|
      [c.name, c.name]
    end

    respond_to do |format|
      format.js
    end
  end

  def passenger
    #p params.inspect
    if params[:nav_back]
      @to_path = 'search-results'
    else
      #@card = Card.new
      @card = populate_record :card, Card, params
      @to_path = 'payment-details'
    end
    respond_to do |format|
      format.js
    end
  end

  def payment
    #binding.pry
    if params[:nav_back]
      @to_path = 'passenger-details'
    else
      @to_path = 'preview-trip'
      @flight = ScheduledFlight.find(params['selected-flight'])
      @trip = Trip.new
      @trip.dep_date = Date.strptime(params[:date],"%m/%d/%Y")
      @dep_airport = Airport.find(@flight.from_airport_id)
      @arr_airport = Airport.find(@flight.to_airport_id)
      @passenger = populate_record :passenger, Passenger, params

      puts '='*20
      p @trip
      p @flight
      p @passenger
      puts '='*20
    end
    respond_to do |format|
      format.js
    end
  end

  private
  def populate_record(model, model_class, params)
    p '='*20
    p model
    p model_class
    p params
    record = model_class.new
    if params[model]
      model_class.column_names.sort.each do |col|
        p col
        p model_class.columns_hash[col].type
        col_type = model_class.columns_hash[col].type
        if col_type != :date && col_type != :datetime
          record.send("#{col}=", params[model][col])
        else
          year = params[model]["#{col}(1i)"]
          month = params[model]["#{col}(2i)"]
          day = params[model]["#{col}(3i)"]
          record.send("#{col}=", "#{day}/#{month}/#{year}")
        end
      end
      p record.inspect
    end
    record
  end
end
