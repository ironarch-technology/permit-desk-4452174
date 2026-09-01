class ParcelsController < ApplicationController
  include Authentication

  def lookup
    matches = Parcel.search_by_address(params[:q])

    render json: matches.map { |parcel|
      {
        apn: parcel.apn,
        address: parcel.display_address,
        district: parcel.district,
        zone_code: parcel.zone_code
      }
    }
  end
end
