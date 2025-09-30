class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "Subscribing to NotificationsChannel with params: #{params.inspect}"
    if params[:shopping_list_slug].present?
      stream_from "notifications_#{params[:shopping_list_slug]}"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
